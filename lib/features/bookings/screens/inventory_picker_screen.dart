import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_service_model.dart';
import '../repository/booking_repository.dart';
import '../models/booked_item_model.dart';
import 'dart:async';
import '../../../core/config/app_config.dart';
import 'booking_detail_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// =====================================================
/// WIDGET
/// =====================================================
class InventoryPickerScreen extends StatefulWidget {
  final String bookingId;
  final String? parentId;

  const InventoryPickerScreen({
    super.key,
    required this.bookingId,
    this.parentId,
  });

  @override
  State<InventoryPickerScreen> createState() => _InventoryPickerScreenState();
}

/// =====================================================
/// STATE
/// =====================================================
class _InventoryPickerScreenState extends State<InventoryPickerScreen> {
  String? businessId;
  final BookingRepository repo = BookingRepository();
  TextEditingController searchController = TextEditingController();
  String searchText = "";
  Timer? _debounce;

  DateTime? startDate;
  DateTime? endDate;
  String filterMode = "category";

  String selectedManualType = "";

  Widget _itemThumbnail(DocumentSnapshot node) {
    final data = node.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl']?.toString().trim() ?? '';

    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFE8EEF8),
      child: imageUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                imageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.inventory,
                  color: Color(0xFF1E4FA3),
                ),
              ),
            )
          : const Icon(
              Icons.inventory,
              color: Color(0xFF1E4FA3),
            ),
    );
  }

  /// =====================================================
  /// LOAD BOOKING DATES
  /// =====================================================
  @override
  void initState() {
    super.initState();
    initialize();
  }

  Stream<Set<String>> bookedItemsStream() {
    return FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
        .collection("bookings")
        .doc(widget.bookingId)
        .collection("bookedItems")
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc["inventoryItemId"] as String)
          .toSet();
    });
  }

  Stream<Set<String>> bookedServicesStream() {
    return FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
        .collection("bookings")
        .doc(widget.bookingId)
        .collection("bookingServices")
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc["serviceId"] as String).toSet();
    });
  }

  void openManualItemDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController qtyController = TextEditingController();
    TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.addManualItem),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.itemName),
            ),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.quantity),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.rentPrice),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
            child: Text(AppLocalizations.of(context)!.add),
            onPressed: () async {
              String name = nameController.text;
              int qty = int.tryParse(qtyController.text) ?? 0;
              double price = double.tryParse(priceController.text) ?? 0;

              BookedItemModel item = BookedItemModel(
                id: const Uuid().v4(),
                inventoryItemId: const Uuid().v4(),
                itemName: name,
                isManual: true,
                requestedQuantity: qty,
                availableQuantityAtBooking: 0,
                shortageQuantity: 0,
                rentPriceSnapshot: price,
                createdAt: Timestamp.now(),
                bookingStartDate: startDate!,
                bookingEndDate: endDate!,
                businessId: businessId,
                bookingId: widget.bookingId,
              );

              await repo.addBookedItem(
                bookingId: widget.bookingId,
                item: item,
              );

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void openManualServiceDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.addManualService),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.serviceName),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.price),
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
            child: Text(AppLocalizations.of(context)!.add),
            onPressed: () async {
              final service = BookingServiceModel(
                id: const Uuid().v4(),
                serviceId: const Uuid().v4(),
                serviceName: nameController.text,
                priceSnapshot: double.tryParse(priceController.text) ?? 0,
                createdAt: Timestamp.now(),
              );

              await repo.addBookingService(
                bookingId: widget.bookingId,
                service: service,
              );

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> initialize() async {
    businessId = await getBusinessId();
    await loadBookingDates();
    setState(() {});
  }

  Future<void> loadBookingDates() async {
    final bookingDoc = await FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId!)
        .collection("bookings")
        .doc(widget.bookingId)
        .get();

    startDate = (bookingDoc["startDate"] as Timestamp).toDate();

    endDate = (bookingDoc["endDate"] as Timestamp).toDate();

    setState(() {});
  }

  /// =====================================================
  /// ✅ FAST DATE-AWARE AVAILABILITY STREAM
  /// =====================================================
  Stream<Map<String, int>> dateAwareBookedItemsStream() {
  if (startDate == null || endDate == null || businessId == null) {
    return Stream.value({});
  }

  return FirebaseFirestore.instance
      .collection("businesses")
      .doc(businessId)
      .collection("bookedItems") // ✅ SAFE + FAST
      .snapshots()
      .map((snapshot) {

    Map<String, int> bookedMap = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      /// skip manual items
      if (data["isManual"] == true) continue;

      /// date check
      if (!data.containsKey("bookingStartDate")) continue;

      DateTime otherStart =
          (data["bookingStartDate"] as Timestamp).toDate();
      DateTime otherEnd =
          (data["bookingEndDate"] as Timestamp).toDate();

      bool overlap =
          !(otherEnd.isBefore(startDate!) || otherStart.isAfter(endDate!));

      if (!overlap) continue;

      String itemId = data["inventoryItemId"];

      int requested = (data["requestedQuantity"] as num?)?.toInt() ?? 0;
      int dispatched = (data["dispatchedQuantity"] as num?)?.toInt() ?? 0;

      int effectiveQty = dispatched > 0 ? dispatched : requested;

      bookedMap[itemId] =
          (bookedMap[itemId] ?? 0) + effectiveQty;
    }

    return bookedMap;
  });
}

  /// =====================================================
  /// UI
  /// =====================================================
  @override
  Widget build(BuildContext context) {
    if (businessId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (startDate == null || endDate == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Query query = FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId!)
        .collection("inventoryNodes");

    /// NORMAL BROWSING MODE (no search)
    if (searchText.isEmpty) {
      if (filterMode != "category") {
        query = query.where("type", isEqualTo: filterMode);
      }

      if (filterMode == "category") {
        if (widget.parentId == null) {
          query = query.where("parentId", isNull: true);
        } else {
          query = query.where("parentId", isEqualTo: widget.parentId);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.pickItems,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
  child: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
        ),
      ],
    ),
    child: Row(
              children: [
                // Items
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppLocalizations.of(context)!.items),
                    selected: filterMode == "item",
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: filterMode == "item" ? Colors.white : Colors.black,
                    ),
                    onSelected: (_) {
                      setState(() {
                        filterMode = "item";
                      });
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Categories
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppLocalizations.of(context)!.categories),
                    selected: filterMode == "category",
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: filterMode == "category"
                          ? Colors.white
                          : Colors.black,
                    ),
                    onSelected: (_) {
                      setState(() {
                        filterMode = "category";
                      });
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Services
                Expanded(
                  child: ChoiceChip(
                    label: Text(AppLocalizations.of(context)!.services),
                    selected: filterMode == "service",
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color:
                          filterMode == "service" ? Colors.white : Colors.black,
                    ),
                    onSelected: (_) {
                      setState(() {
                        filterMode = "service";
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          ),

          /// SEARCH BAR
          ///
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                // Manual Item
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedManualType = "item";
                      });
                      openManualItemDialog();
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: selectedManualType == "item"
                            ? const LinearGradient(
                                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                              )
                            : null,
                        color:
                            selectedManualType == "item" ? null : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: selectedManualType == "item"
                                ? Colors.white
                                : Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.manualItem,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selectedManualType == "item"
                                  ? Colors.white
                                  : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Manual Service
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedManualType = "service";
                      });
                      openManualServiceDialog();
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: selectedManualType == "service"
                            ? const LinearGradient(
                                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                              )
                            : null,
                        color: selectedManualType == "service"
                            ? null
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: selectedManualType == "service"
                                ? Colors.white
                                : Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.addManualService,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selectedManualType == "service"
                                  ? Colors.white
                                  : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
        )
      ],
    ),
    child: TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchInventory,
        prefixIcon: const Icon(Icons.search),

        // clear button (same logic)
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  searchController.clear();

                  setState(() {
                    searchText = "";
                  });

                  FocusScope.of(context).unfocus();
                },
              )
            : null,

        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1E4FA3),
            width: 1,
          ),
        ),
      ),

      // ORIGINAL debounce logic preserved
      onChanged: (value) {
        if (_debounce?.isActive ?? false) {
          _debounce!.cancel();
        }

        _debounce = Timer(const Duration(milliseconds: 300), () {
          setState(() {
            searchText = value.toLowerCase();
          });
        });
      },
    ),
  ),
),

          /// YOUR EXISTING STREAMBUILDER
          Expanded(
            child: StreamBuilder(
                stream: query.snapshots(),
                builder: (context, inventorySnap) {
                  if (!inventorySnap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  var nodes = inventorySnap.data!.docs;

                  /// SEARCH FILTER
                  if (searchText.isNotEmpty) {
                    nodes = nodes.where((doc) {
                      String name = (doc["name"] ?? "").toLowerCase();

                      /// apply filter buttons also
                      if (filterMode != "category" &&
                          doc["type"] != filterMode) {
                        return false;
                      }

                      return name.contains(searchText);
                    }).toList();
                  }

                  List categories = [];
                  List items = [];
                  List services = [];

                  for (var node in nodes) {
                    if (node["type"] == "category") {
                      categories.add(node);
                    } else if (node["type"] == "item") {
                      items.add(node);
                    } else if (node["type"] == "service") {
                      services.add(node);
                    }
                  }

                  return StreamBuilder<Map<String, int>>(
                      stream: dateAwareBookedItemsStream(),
                      builder: (context, bookedSnap) {
                        final bookedMap = bookedSnap.data ?? {};

                        return StreamBuilder<Set<String>>(
                          stream: bookedItemsStream(),
                          builder: (context, itemSnap) {
                            final bookedItemIds = itemSnap.data ?? {};

                            return StreamBuilder<Set<String>>(
                              stream: bookedServicesStream(),
                              builder: (context, serviceSnap) {
                                final bookedServiceIds = serviceSnap.data ?? {};

                                return ListView(
                                  children: [
                                    /// CATEGORIES
                                    if (categories.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Text(
                                          AppLocalizations.of(context)!.categories,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),

                                    ...categories.map((node) {
                                      return ListTile(
                                        leading: const Icon(Icons.folder),
                                        title: Text(node["name"]),
                                        trailing:
                                            const Icon(Icons.arrow_forward),
                                        onTap: () {
                                          /// if searching, clear search and open folder
                                          if (searchText.isNotEmpty) {
                                            searchController.clear();
                                            searchText = "";
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  InventoryPickerScreen(
                                                bookingId: widget.bookingId,
                                                parentId: node.id,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),

                                    /// ITEMS
                                    if (items.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Text(
                                          AppLocalizations.of(context)!.items,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),

                                    ...items.map((node) {
                                      int total =
                                          (node["quantity"] as num?)?.toInt() ??
                                              0;
                                      int booked = bookedMap[node.id] ?? 0;
                                      int available = total - booked;

                                      bool isBooked =
                                          bookedItemIds.contains(node.id);

                                      return ListTile(
                                        leading: _itemThumbnail(node),
                                        title: Text(node["name"]),
                                        subtitle: Text("${AppLocalizations.of(context)!.available} $available"),
                                        trailing: isBooked
                                            ? Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                              )
                                            : null,
                                        onTap: () =>
                                            openQtyDialog(context, node),
                                      );
                                    }),

                                    /// SERVICES
                                    if (services.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Text(
                                          AppLocalizations.of(context)!.services,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),

                                    ...services.map((node) {
                                      bool isBooked =
                                          bookedServiceIds.contains(node.id);

                                      return ListTile(
                                        leading: const Icon(
                                            Icons.miscellaneous_services),
                                        title: Text(node["name"]),
                                        subtitle: Text(
                                            "₹ ${(node["price"] as num?)?.toDouble() ?? 0}"),
                                        trailing: isBooked
                                            ? Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                              )
                                            : null,
                                        onTap: () async {
                                          final service = BookingServiceModel(
                                            id: const Uuid().v4(),
                                            serviceId: node.id,
                                            serviceName: node["name"],
                                            priceSnapshot:
                                                (node["price"] as num?)
                                                        ?.toDouble() ??
                                                    0,
                                            createdAt: Timestamp.now(),
                                          );

                                          await repo.addBookingService(
                                            bookingId: widget.bookingId,
                                            service: service,
                                          );

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(AppLocalizations.of(context)!.serviceAdded)),
                                          );
                                        },
                                      );
                                    }),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      });
                }),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E4FA3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.done,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingDetailScreen(
                    bookingId: widget.bookingId,
                    businessId: businessId!,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// =====================================================
  /// ADD ITEM
  /// =====================================================
  void openQtyDialog(BuildContext context, DocumentSnapshot item) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(item["name"]),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.quantity),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
            child: Text(AppLocalizations.of(context)!.add),
            onPressed: () async {
              int qty = int.parse(controller.text);

              /// ✅ IMPORTANT:
              /// booking dates saved inside bookedItems
              BookedItemModel booked = BookedItemModel(
                id: const Uuid().v4(),
                inventoryItemId: item.id,
                itemName: item["name"],
                requestedQuantity: qty,
                availableQuantityAtBooking: (item["quantity"] as num).toInt(),
                shortageQuantity: 0,
                rentPriceSnapshot: (item["rentPrice"] as num).toDouble(),
                createdAt: Timestamp.now(),
                bookingStartDate: startDate!,
                bookingEndDate: endDate!,
                businessId: businessId,
                bookingId: widget.bookingId,
              );

              await repo.addBookedItem(
                bookingId: widget.bookingId,
                item: booked,
              );

              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }
}

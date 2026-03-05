import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_service_model.dart';
import '../repository/booking_repository.dart';
import '../models/booked_item_model.dart';
import 'dart:async';

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
  final String businessId = "demo_business";
  final BookingRepository repo = BookingRepository();
  TextEditingController searchController = TextEditingController();
  String searchText = "";
  Timer? _debounce;

  DateTime? startDate;
  DateTime? endDate;
  String filterMode = "category";

  /// =====================================================
  /// LOAD BOOKING DATES
  /// =====================================================
  @override
  void initState() {
    super.initState();
    loadBookingDates();
  }

  Future<void> loadBookingDates() async {
    final bookingDoc = await FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
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
    if (startDate == null || endDate == null) {
      return Stream.value({});
    }

    return FirebaseFirestore.instance
        .collectionGroup("bookedItems")
        .snapshots()
        .map((snapshot) {
      Map<String, int> bookedMap = {};

      for (var doc in snapshot.docs) {
        if (!doc.data().containsKey("bookingStartDate")) {
          continue;
        }

        /// ✅ dates already stored in bookedItems
        DateTime otherStart = (doc["bookingStartDate"] as Timestamp).toDate();

        DateTime otherEnd = (doc["bookingEndDate"] as Timestamp).toDate();

        /// DATE OVERLAP CHECK
        bool overlap =
            !(otherEnd.isBefore(startDate!) || otherStart.isAfter(endDate!));

        if (!overlap) continue;

        String itemId = doc["inventoryItemId"];

        int qty = (doc["requestedQuantity"] as num).toInt();

        bookedMap[itemId] = (bookedMap[itemId] ?? 0) + qty;
      }

      return bookedMap;
    });
  }

  /// =====================================================
  /// UI
  /// =====================================================
  @override
  Widget build(BuildContext context) {
    if (startDate == null || endDate == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Query query = FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
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
        title: Container(
  height: 40,
  decoration: BoxDecoration(
    color: Colors.grey.shade200,
    borderRadius: BorderRadius.circular(10),
  ),
  child: TextField(
    controller: searchController,
    decoration: InputDecoration(
      hintText: "Search inventory...",
      prefixIcon: const Icon(Icons.search),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      suffixIcon: searchText.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                searchController.clear();
                setState(() {
                  searchText = "";
                });
              },
            )
          : null,
    ),
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("Items"),
                  selected: filterMode == "item",
                  onSelected: (_) {
                    setState(() {
                      filterMode = "item";
                    });
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text("Categories"),
                  selected: filterMode == "category",
                  onSelected: (_) {
                    setState(() {
                      filterMode = "category";
                    });
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text("Services"),
                  selected: filterMode == "service",
                  onSelected: (_) {
                    setState(() {
                      filterMode = "service";
                    });
                  },
                ),
              ],
            ),
          )
        ],
      ),
      body: Column(
  children: [

    /// SEARCH BAR
    Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search inventory...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          if (_debounce?.isActive ?? false) {
            _debounce!.cancel();
          }

          _debounce = Timer(const Duration(milliseconds: 300), () {
            setState(() {
              searchText = value.toLowerCase();
            });
          }
          );
        },
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
              if (filterMode != "category" && doc["type"] != filterMode) {
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

              return ListView(
                children: [
                  /// CATEGORIES
                  if (categories.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "Categories",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),

                  ...categories.map((node) {
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(node["name"]),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        /// if searching, clear search and open folder
                        if (searchText.isNotEmpty) {
                          searchController.clear();
                          searchText = "";
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InventoryPickerScreen(
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
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "Items",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),

                  ...items.map((node) {
                    int total = (node["quantity"] as num?)?.toInt() ?? 0;
                    int booked = bookedMap[node.id] ?? 0;
                    int available = total - booked;

                    return ListTile(
                      leading: const Icon(Icons.inventory),
                      title: Text(node["name"]),
                      subtitle: Text("Available: $available"),
                      onTap: () => openQtyDialog(context, node),
                    );
                  }),

                  /// SERVICES
                  if (services.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "Services",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),

                  ...services.map((node) {
                    return ListTile(
                      leading: const Icon(Icons.miscellaneous_services),
                      title: Text(node["name"]),
                      subtitle:
                          Text("₹ ${(node["price"] as num?)?.toDouble() ?? 0}"),
                      onTap: () async {
                        final service = BookingServiceModel(
                          id: const Uuid().v4(),
                          serviceId: node.id,
                          serviceName: node["name"],
                          priceSnapshot:
                              (node["price"] as num?)?.toDouble() ?? 0,
                          createdAt: Timestamp.now(),
                        );

                        await repo.addBookingService(
                          bookingId: widget.bookingId,
                          service: service,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Service Added")),
                        );
                      },
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
          ),

  ],
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
        title: Text(item["name"]),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Quantity"),
        ),
        actions: [
          TextButton(
            child: const Text("Add"),
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

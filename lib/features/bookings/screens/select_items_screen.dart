import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/config/app_config.dart';
import '../repository/booking_repository.dart';
import '../models/booked_item_model.dart';
import '../models/temp_selected_item.dart';

class SelectItemsScreen extends StatefulWidget {
  final String bookingId;

  const SelectItemsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<SelectItemsScreen> createState() => _SelectItemsScreenState();
}

class _SelectItemsScreenState extends State<SelectItemsScreen> {
  DateTime? startDate;
  DateTime? endDate;

  String? businessId;
  final BookingRepository repo = BookingRepository();

  @override
  void initState() {
    super.initState();
    initialize();
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
  }

  Future<void> loadBusiness() async {
    businessId = await getBusinessId();
    setState(() {});
  }

  /// ⭐ LOCAL CART
  Map<String, TempSelectedItem> selectedItems = {};

  /// ===============================
  /// ADD QUICKLY
  /// ===============================
  void quickAdd(DocumentSnapshot item) {
    if (selectedItems.containsKey(item.id)) {
      selectedItems[item.id]!.quantity++;
    } else {
      selectedItems[item.id] = TempSelectedItem(
        inventoryItemId: item.id,
        name: item["name"],
        rentPrice: item["rentPrice"].toDouble(),
        quantity: 1,
      );
    }

    setState(() {});
  }

  /// ===============================
  /// QUANTITY POPUP
  /// ===============================
  void openQtyDialog(DocumentSnapshot item) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(item["name"]),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Quantity"),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
            child: const Text("OK"),
            onPressed: () {
              int qty = int.parse(controller.text);

              selectedItems[item.id] = TempSelectedItem(
                inventoryItemId: item.id,
                name: item["name"],
                rentPrice: item["rentPrice"].toDouble(),
                quantity: qty,
              );

              Navigator.pop(context);
              setState(() {});
            },
          )
        ],
      ),
    );
  }

  /// ===============================
  /// SAVE ALL ITEMS
  /// ===============================
  Future<void> saveItems() async {
    for (var item in selectedItems.values) {
      await repo.addBookedItem(
        bookingId: widget.bookingId,
        item: BookedItemModel(
          id: const Uuid().v4(),
          inventoryItemId: item.inventoryItemId,
          itemName: item.name,
          requestedQuantity: item.quantity,
          availableQuantityAtBooking: 0,
          shortageQuantity: 0,
          rentPriceSnapshot: item.rentPrice,
          createdAt: Timestamp.now(),

          /// ✅ ADD THESE
          bookingStartDate: startDate!,
          bookingEndDate: endDate!,
        ),
      );
    }

    Navigator.pop(context);
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    if (businessId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (startDate == null || endDate == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Select Items")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saveItems,
        label: const Text("Done"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("businesses")
            .doc(businessId!)
            .collection("inventoryNodes")
            .where("type", isEqualTo: "item")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];

              int qty = selectedItems[item.id]?.quantity ?? 0;

              return ListTile(
                title: Text(item["name"]),
                subtitle: Text("Qty: $qty"),
                trailing: ElevatedButton(
                  onPressed: () => quickAdd(item),
                  child: const Text("+ Add"),
                ),
                onTap: () => openQtyDialog(item),
              );
            },
          );
        },
      ),
    );
  }
}

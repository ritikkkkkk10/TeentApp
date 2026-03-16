import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../repository/booking_repository.dart';
import '../models/booked_item_model.dart';
import '../../../core/config/app_config.dart';

class AddItemScreen extends StatefulWidget {
  final String bookingId;

  const AddItemScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  String? businessId;
  final BookingRepository repo = BookingRepository();

  DateTime? startDate;
  DateTime? endDate;

  /// ===============================
  /// LOAD BOOKING DATES
  /// ===============================
  @override
  void initState() {
    super.initState();
    loadBookingDates();
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

  /// ===============================
  /// DATE OVERLAP AVAILABILITY STREAM
  /// ===============================
  Stream<int> bookedQuantityStream(String inventoryItemId) {
    return FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId!)
        .collection("bookings")
        .snapshots()
        .asyncMap((bookingSnapshot) async {
      int totalBooked = 0;

      for (var booking in bookingSnapshot.docs) {
        DateTime otherStart = (booking["startDate"] as Timestamp).toDate();

        DateTime otherEnd = (booking["endDate"] as Timestamp).toDate();

        /// overlap check
        bool overlap =
            !(otherEnd.isBefore(startDate!) || otherStart.isAfter(endDate!));

        if (!overlap) continue;

        var items = await booking.reference
            .collection("bookedItems")
            .where(
              "inventoryItemId",
              isEqualTo: inventoryItemId,
            )
            .get();

        for (var item in items.docs) {
          totalBooked += (item["requestedQuantity"] as num).toInt();
        }
      }

      return totalBooked;
    });
  }

  /// ===============================
  /// ADD ITEM
  /// ===============================
  void addItem(BuildContext context, DocumentSnapshot item, int available) {
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
            child: const Text("Add"),
            onPressed: () async {
              int requested = int.parse(controller.text);

              int shortage = requested > available ? requested - available : 0;

              /// SHORTAGE WARNING
              if (shortage > 0) {
                bool? proceed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: const Text("Stock Shortage"),
                    content: Text("Only $available available.\n"
                        "Short by $shortage items.\n\n"
                        "Continue booking?"),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
    foregroundColor: const Color(0xFF1E4FA3),
  ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Proceed"),
                      ),
                    ],
                  ),
                );

                if (proceed != true) return;
              }

              BookedItemModel booked = BookedItemModel(
                id: const Uuid().v4(),
                inventoryItemId: item.id,
                itemName: item["name"],
                requestedQuantity: requested,
                availableQuantityAtBooking: available,
                shortageQuantity: shortage,
                rentPriceSnapshot: item["rentPrice"].toDouble(),
                createdAt: Timestamp.now(),

                /// ✅ ADD THESE
                bookingStartDate: startDate!,
                bookingEndDate: endDate!,
              );

              await repo.addBookedItem(
                bookingId: widget.bookingId,
                item: booked,
              );

              Navigator.pop(context);
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    if (startDate == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Select Item")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("businesses")
            .doc(businessId)
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

              return StreamBuilder<int>(
                stream: bookedQuantityStream(item.id),
                builder: (context, bookedSnap) {
                  if (!bookedSnap.hasData) {
                    return const ListTile(title: Text("Checking..."));
                  }

                  int booked = bookedSnap.data!;
                  int total = item["quantity"];

                  int available = total - booked;

                  return ListTile(
                    title: Text(item["name"]),
                    subtitle: Text("Available: $available / $total"),
                    onTap: () => addItem(
                      context,
                      item,
                      available,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../repository/booking_repository.dart';
import '../models/booked_item_model.dart';

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
  State<InventoryPickerScreen> createState()
      => _InventoryPickerScreenState();
}

/// =====================================================
/// STATE
/// =====================================================
class _InventoryPickerScreenState
    extends State<InventoryPickerScreen> {

  final String businessId = "demo_business";
  final BookingRepository repo =
      BookingRepository();

  DateTime? startDate;
  DateTime? endDate;

  /// =====================================================
  /// LOAD BOOKING DATES
  /// =====================================================
  @override
  void initState() {
    super.initState();
    loadBookingDates();
  }

  Future<void> loadBookingDates() async {

    final bookingDoc =
        await FirebaseFirestore.instance
            .collection("businesses")
            .doc(businessId)
            .collection("bookings")
            .doc(widget.bookingId)
            .get();

    startDate =
        (bookingDoc["startDate"]
                as Timestamp)
            .toDate();

    endDate =
        (bookingDoc["endDate"]
                as Timestamp)
            .toDate();

    setState(() {});
  }

  /// =====================================================
  /// DATE AWARE AVAILABILITY ENGINE ⭐
  /// =====================================================
  Stream<Map<String, int>>
dateAwareBookedItemsStream() {

  if (startDate == null ||
      endDate == null) {
    return const Stream.empty();
  }

  return FirebaseFirestore.instance
      .collectionGroup("bookedItems")
      .snapshots()
      .asyncMap((snapshot) async {

    Map<String, int> bookedMap = {};

    for (var doc in snapshot.docs) {

      /// parent booking reference
      DocumentReference bookingRef =
          doc.reference.parent.parent!;

      var booking =
          await bookingRef.get();

      DateTime otherStart =
          (booking["startDate"]
                  as Timestamp)
              .toDate();

      DateTime otherEnd =
          (booking["endDate"]
                  as Timestamp)
              .toDate();

      /// DATE OVERLAP
      bool overlap =
          !(otherEnd.isBefore(startDate!) ||
            otherStart.isAfter(endDate!));

      if (!overlap) continue;

      String itemId =
          doc["inventoryItemId"];

      int qty =
          (doc["requestedQuantity"]
                  as num)
              .toInt();

      bookedMap[itemId] =
          (bookedMap[itemId] ?? 0) + qty;
    }

    return bookedMap;
  });
}

  /// =====================================================
  /// UI
  /// =====================================================
  @override
  Widget build(BuildContext context) {

    Query query = FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
        .collection("inventoryNodes");

    if (widget.parentId == null) {
      query =
          query.where("parentId",
              isNull: true);
    } else {
      query =
          query.where("parentId",
              isEqualTo:
                  widget.parentId);
    }

    return Scaffold(
      appBar: AppBar(
          title:
              const Text("Select Item")),

      body: StreamBuilder(
        stream: query.snapshots(),
        builder:
            (context, inventorySnap) {

          if (!inventorySnap.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          var nodes =
              inventorySnap.data!.docs;

          return StreamBuilder<
              Map<String, int>>(
            stream:
                dateAwareBookedItemsStream(),

            builder:
                (context, bookedSnap) {

              if (!bookedSnap.hasData) {
                return const Center(
                    child:
                        CircularProgressIndicator());
              }

              final bookedMap =
                  bookedSnap.data!;

              return ListView.builder(
                itemCount:
                    nodes.length,
                itemBuilder:
                    (context, index) {

                  var node =
                      nodes[index];

                  /// CATEGORY
                  if (node["type"] ==
                      "category") {

                    return ListTile(
                      leading:
                          const Icon(
                              Icons.folder),
                      title:
                          Text(
                              node["name"]),
                      trailing:
                          const Icon(
                              Icons.arrow_forward),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InventoryPickerScreen(
                              bookingId:
                                  widget
                                      .bookingId,
                              parentId:
                                  node.id,
                            ),
                          ),
                        );
                      },
                    );
                  }

                  /// ITEM
                  int total =
                      (node["quantity"]
                              as num)
                          .toInt();

                  int booked =
                      bookedMap[
                              node.id] ??
                          0;

                  int available =
                      total - booked;

                  return ListTile(
                    leading:
                        const Icon(
                            Icons.inventory),
                    title:
                        Text(
                            node["name"]),
                    subtitle: Text(
                        "Available: $available"),

                    onTap: () =>
                        openQtyDialog(
                            context,
                            node),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// =====================================================
  /// ADD ITEM
  /// =====================================================
  void openQtyDialog(
      BuildContext context,
      DocumentSnapshot item) {

    TextEditingController controller =
        TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(item["name"]),
        content:
            TextField(
          controller:
              controller,
          keyboardType:
              TextInputType.number,
          decoration:
              const InputDecoration(
                  labelText:
                      "Quantity"),
        ),
        actions: [
          TextButton(
            child:
                const Text("Add"),
            onPressed: () async {

              int qty =
                  int.parse(
                      controller.text);

              BookedItemModel booked =
                  BookedItemModel(
                id:
                    const Uuid().v4(),
                inventoryItemId:
                    item.id,
                itemName:
                    item["name"],
                requestedQuantity:
                    qty,
                availableQuantityAtBooking:
                    (item["quantity"]
                            as num)
                        .toInt(),
                shortageQuantity:
                    0,
                rentPriceSnapshot:
                    (item["rentPrice"]
                            as num)
                        .toDouble(),
                createdAt:
                    Timestamp.now(),
              );

              await repo.addBookedItem(
                bookingId:
                    widget.bookingId,
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
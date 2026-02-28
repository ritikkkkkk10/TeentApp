import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../repository/booking_repository.dart';
import '../models/booked_item_model.dart';

class AddItemScreen extends StatelessWidget {

  final String bookingId;

  AddItemScreen(
      {super.key,
      required this.bookingId});

  final String businessId =
      "demo_business";

  final BookingRepository repo =
      BookingRepository();

  void addItem(
      BuildContext context,
      DocumentSnapshot item) async {

    TextEditingController qtyController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title:
              Text(item["name"]),
          content: TextField(
            controller: qtyController,
            keyboardType:
                TextInputType.number,
            decoration:
                const InputDecoration(
                    labelText:
                        "Quantity"),
          ),
          actions: [
            TextButton(
              onPressed: () async {

                int requested =
                    int.parse(
                        qtyController.text);

                int totalQty =
                    item["quantity"];

                int shortage =
                    requested >
                            totalQty
                        ? requested -
                            totalQty
                        : 0;

                BookedItemModel booked =
                    BookedItemModel(
                  id: const Uuid().v4(),
                  inventoryItemId:
                      item.id,
                  itemName:
                      item["name"],
                  requestedQuantity:
                      requested,
                  availableQuantityAtBooking:
                      totalQty,
                  shortageQuantity:
                      shortage,
                  rentPriceSnapshot:
                      item["rentPrice"]
                          .toDouble(),
                  createdAt:
                      Timestamp.now(),
                );

                await repo.addBookedItem(
                  bookingId:
                      bookingId,
                  item: booked,
                );

                Navigator.pop(context);
                Navigator.pop(context);
              },
              child:
                  const Text("Add"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar:
          AppBar(title:
              const Text("Select Item")),

      body: StreamBuilder(
        stream: FirebaseFirestore
            .instance
            .collection(
                "businesses")
            .doc(businessId)
            .collection(
                "inventoryNodes")
            .where("type",
                isEqualTo:
                    "item")
            .snapshots(),
        builder:
            (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child:
                    CircularProgressIndicator());
          }

          var items =
              snapshot.data!.docs;

          return ListView.builder(
            itemCount:
                items.length,
            itemBuilder:
                (context, index) {

              var item =
                  items[index];

              return ListTile(
                title:
                    Text(item["name"]),
                subtitle: Text(
                    "Qty: ${item["quantity"]}"),
                onTap: () =>
                    addItem(
                        context,
                        item),
              );
            },
          );
        },
      ),
    );
  }
}
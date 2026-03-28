import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void editQuantity({
  required BuildContext context,
  required DocumentSnapshot item,
  required bool isManual,
  required String businessId,
  required String bookingId,
}) {
    final data = item.data() as Map<String, dynamic>;

    int qty = data["requestedQuantity"] ?? 0;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text("${data["itemName"]} (Current: $qty)"),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (qty > 0) {
                        setState(() {
                          qty--;
                        });
                      }
                    },
                  ),
                  Text(
                    qty.toString(),
                    style: const TextStyle(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        qty++;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                /// DELETE ITEM
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E4FA3),
                  ),
                  child: Text(AppLocalizations.of(context)!.delete),
                  onPressed: () async {
                    /// 1. DELETE FROM BOOKING
                    await item.reference.delete();

                    /// 2. DELETE FROM GLOBAL bookedItems
                    final globalRef = FirebaseFirestore.instance
                        .collection("businesses")
                        .doc(businessId)
                        .collection("bookedItems");

                    final globalDocs = await globalRef
                        .where("bookingId", isEqualTo: bookingId)
                        .where("inventoryItemId",
                            isEqualTo: item["inventoryItemId"])
                        .get();

                    for (var doc in globalDocs.docs) {
                      await doc.reference.delete();
                    }

                    Navigator.pop(context);
                  },
                ),

                /// SAVE CHANGES
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E4FA3),
                  ),
                  child: Text(AppLocalizations.of(context)!.save),
                  onPressed: () async {
                    int newQty = qty;

                    if (!isManual) {
                      final inventoryDoc = await FirebaseFirestore.instance
                          .collection("businesses")
                          .doc(businessId)
                          .collection("inventoryNodes")
                          .doc(data["inventoryItemId"])
                          .get();

                      int totalInventory =
                          (inventoryDoc["quantity"] as num).toInt();

                      int currentQty = data["requestedQuantity"] ?? 0;

                      if (newQty >
                          totalInventory + (data["requestedQuantity"] ?? 0)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .notEnoughInventory),
                          ),
                        );

                        return;
                      }
                    }

                    await item.reference.update({
                      "requestedQuantity": newQty,
                    });

                    final globalRef = FirebaseFirestore.instance
                        .collection("businesses")
                        .doc(businessId)
                        .collection("bookedItems");

                    /// find matching global entries
                    final globalDocs = await globalRef
                        .where("bookingId", isEqualTo: bookingId)
                        .where("inventoryItemId",
                            isEqualTo: item["inventoryItemId"])
                        .get();

                    for (var doc in globalDocs.docs) {
                      await doc.reference.update({
                        "requestedQuantity": newQty,
                      });
                    }

                    Navigator.pop(context);
                  },
                )
              ],
            );
          },
        );
      },
    );
  }
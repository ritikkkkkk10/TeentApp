import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReceiveItemsScreen extends StatefulWidget {
  final String businessId;
  final String bookingId;

  const ReceiveItemsScreen({
    super.key,
    required this.businessId,
    required this.bookingId,
  });

  @override
  State<ReceiveItemsScreen> createState() => _ReceiveItemsScreenState();
}

class _ReceiveItemsScreenState extends State<ReceiveItemsScreen> {
  Map<String, TextEditingController> quantityControllers = {};

  void receiveAllItems(List<QueryDocumentSnapshot> docs) {
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      int dispatched = data["dispatchedQuantity"] ?? 0;
      int received = data["receivedQuantity"] ?? 0;

      int remaining = dispatched - received;

      quantityControllers[doc.id]?.text = remaining.toString();
    }

    setState(() {});
  }

  Future<void> saveProgress(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      int qty = int.tryParse(quantityControllers[doc.id]!.text) ?? 0;

      int dispatched = data["dispatchedQuantity"] ?? 0;
      int previousReceived = data["receivedQuantity"] ?? 0;

      int remaining = dispatched - previousReceived;

      if (qty > remaining) qty = remaining;

      if (qty <= 0) continue;

      final ref = FirebaseFirestore.instance
          .collection("businesses")
          .doc(widget.businessId)
          .collection("bookings")
          .doc(widget.bookingId)
          .collection("bookedItems")
          .doc(doc.id);

      batch.update(ref, {
        "receivedQuantity": previousReceived + qty,
      });
    }

    await batch.commit();

    Navigator.pop(context);
  }

  Future<void> confirmReceive(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();

    bool hasMissing = false;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      int dispatched = data["dispatchedQuantity"] ?? 0;
      int received = data["receivedQuantity"] ?? 0;

      int qty = int.parse(quantityControllers[doc.id]!.text);

      int remaining = dispatched - received;

      if (qty > remaining) qty = remaining;

      if (qty <= 0) continue;

      int finalReceived = received + qty;

      int missing = dispatched - finalReceived;

      bool isManual = data["isManual"] ?? false;

      if (!isManual) {
        String inventoryId = data["inventoryItemId"];

        final inventoryRef = FirebaseFirestore.instance
            .collection("businesses")
            .doc(widget.businessId)
            .collection("inventoryNodes")
            .doc(inventoryId);

        if (missing > 0) {
          batch.update(
            inventoryRef,
            {"quantity": FieldValue.increment(-missing)},
          );
        }
      }

      /// update booked item
      final ref = FirebaseFirestore.instance
          .collection("businesses")
          .doc(widget.businessId)
          .collection("bookings")
          .doc(widget.bookingId)
          .collection("bookedItems")
          .doc(doc.id);

      batch.update(ref, {
        "receivedQuantity": finalReceived,
        "missingQuantity": missing,
      });

      /// ✅ UPDATE GLOBAL bookedItems
      // final globalRef = FirebaseFirestore.instance
      //     .collection("businesses")
      //     .doc(widget.businessId)
      //     .collection("bookedItems");

      // final globalDocs = await globalRef
      //     .where("bookingId", isEqualTo: widget.bookingId)
      //     .where("inventoryItemId", isEqualTo: data["inventoryItemId"])
      //     .get();

      // for (var gDoc in globalDocs.docs) {
      //   batch.update(gDoc.reference, {
      //     "receivedQuantity": finalReceived,
      //     "missingQuantity": missing,
      //   });
      // }

      if (missing > 0) {
        hasMissing = true;
      }
    }

    final bookingRef = FirebaseFirestore.instance
        .collection("businesses")
        .doc(widget.businessId)
        .collection("bookings")
        .doc(widget.bookingId);

    batch.update(bookingRef, {
      "status": hasMissing
          ? AppLocalizations.of(context)!.receiving
          : AppLocalizations.of(context)!.completed
    });

    await batch.commit();

    Navigator.pop(context);
  }

  Future<void> confirmReceiveDialog(List<QueryDocumentSnapshot> docs) async {
    bool confirm = await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(AppLocalizations.of(context)!.confirmReceive),
            content: Text(AppLocalizations.of(context)!.confirmReceiveMessage),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1E4FA3),
                ),
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1E4FA3),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text(AppLocalizations.of(context)!.confirm),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await confirmReceive(docs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingRef = FirebaseFirestore.instance
        .collection("businesses")
        .doc(widget.businessId)
        .collection("bookings")
        .doc(widget.bookingId);

    final bookedItemsRef = bookingRef.collection("bookedItems");

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.receiveItems)),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookedItemsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => receiveAllItems(docs),
                    child: Text(
                      AppLocalizations.of(context)!.receiveAll,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final name = data["itemName"];

                    final dispatched = data["dispatchedQuantity"] ?? 0;
                    final received = data["receivedQuantity"] ?? 0;

                    final remaining = dispatched - received;

                    quantityControllers.putIfAbsent(
                        doc.id, () => TextEditingController(text: "0"));

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// LEFT SIDE (ITEM INFO)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(AppLocalizations.of(context)!
                                    .alreadyDispatched(dispatched)),
                                Text(AppLocalizations.of(context)!
                                    .received(received)),
                                Text(
                                  AppLocalizations.of(context)!
                                      .remaining(remaining),
                                  style: TextStyle(
                                    color: remaining == 0
                                        ? Colors.green
                                        : Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// RIGHT SIDE CONTROLS
                          Column(
                            children: [
                              /// GREEN TICK
                              if (remaining == 0)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 26,
                                ),

                              const SizedBox(height: 8),

                              /// QUANTITY CONTROLS
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      int value = int.parse(
                                          quantityControllers[doc.id]!.text);

                                      if (value > 0) {
                                        quantityControllers[doc.id]!.text =
                                            (value - 1).toString();
                                        setState(() {});
                                      }
                                    },
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: TextField(
                                      controller: quantityControllers[doc.id],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: UnderlineInputBorder(),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.blue),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.blue, width: 2),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        int current = int.tryParse(value) ?? 0;
                                        int remaining = dispatched - received;

                                        if (current > remaining) {
                                          quantityControllers[doc.id]!.text =
                                              remaining.toString();
                                          quantityControllers[doc.id]!
                                                  .selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                                offset: remaining
                                                    .toString()
                                                    .length),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      int value = int.parse(
                                          quantityControllers[doc.id]!.text);

                                      int remaining = dispatched - received;

                                      if (value < remaining) {
                                        quantityControllers[doc.id]!.text =
                                            (value + 1).toString();
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            elevation: 0,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => saveProgress(docs),
                          child:
                              Text(AppLocalizations.of(context)!.saveProgress),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => confirmReceiveDialog(docs),
                          child: Text(
                              AppLocalizations.of(context)!.confirmReceive),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DispatchItemsScreen extends StatefulWidget {
  final String businessId;
  final String bookingId;

  const DispatchItemsScreen({
    super.key,
    required this.businessId,
    required this.bookingId,
  });

  @override
  State<DispatchItemsScreen> createState() => _DispatchItemsScreenState();
}

class _DispatchItemsScreenState extends State<DispatchItemsScreen> {
  Map<String, TextEditingController> quantityControllers = {};

  /// Dispatch All → fills ordered quantity
  void dispatchAllItems(List<QueryDocumentSnapshot> docs) {
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final requested = data["requestedQuantity"];

      quantityControllers[doc.id]?.text = requested.toString();
    }

    setState(() {});
  }

  /// Save Progress (does NOT change booking status)
  Future<void> saveProgress(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      int qty = int.tryParse(quantityControllers[doc.id]!.text) ?? 0;

      int requested = data["requestedQuantity"];
      int previousDispatched = data["dispatchedQuantity"] ?? 0;

      int remaining = requested - previousDispatched;

      if (qty > remaining) {
        qty = remaining;
      }

      if (qty <= 0) continue;

      final ref = FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('bookings')
          .doc(widget.bookingId)
          .collection('bookedItems')
          .doc(doc.id);

      batch.update(ref, {
        'dispatchedQuantity': previousDispatched + qty,
      });
    }

    await batch.commit();

    await FirebaseFirestore.instance
        .collection("businesses")
        .doc(widget.businessId)
        .collection("bookings")
        .doc(widget.bookingId)
        .update({
      "status": "dispatching",
    });

    Navigator.pop(context);
  }

  /// Confirm Dispatch → updates booking status
  Future<void> confirmDispatch(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      int qty = int.parse(quantityControllers[doc.id]!.text);

      int requested = data["requestedQuantity"];
      int previousDispatched = data["dispatchedQuantity"] ?? 0;

      String inventoryItemId = data["inventoryItemId"];

      int remaining = requested - previousDispatched;

      if (qty > remaining) {
        qty = remaining;
      }

      if (qty <= 0) continue;

      final ref = FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('bookings')
          .doc(widget.bookingId)
          .collection('bookedItems')
          .doc(doc.id);

      batch.update(ref, {
        'dispatchedQuantity': previousDispatched + qty,
      });

      /// ✅ UPDATE GLOBAL bookedItems
      final globalRef = FirebaseFirestore.instance
          .collection("businesses")
          .doc(widget.businessId)
          .collection("bookedItems");

      final globalDocs = await globalRef
          .where("bookingId", isEqualTo: widget.bookingId)
          .where("inventoryItemId", isEqualTo: inventoryItemId)
          .get();

      for (var gDoc in globalDocs.docs) {
        batch.update(gDoc.reference, {
          'dispatchedQuantity': previousDispatched + qty,
        });
      }
    }

    /// Update booking status
    final bookingRef = FirebaseFirestore.instance
        .collection("businesses")
        .doc(widget.businessId)
        .collection("bookings")
        .doc(widget.bookingId);

    batch.update(bookingRef, {"status": "dispatched"});

    await batch.commit();

    Navigator.pop(context);
  }

  Future<void> confirmDispatchDialog(List<QueryDocumentSnapshot> docs) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(AppLocalizations.of(context)!.confirmDispatch),
              content:
                  Text(AppLocalizations.of(context)!.confirmDispatchMessage),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E4FA3),
                  ),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                  ),
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
            );
          },
        ) ??
        false;

    if (confirm) {
      await confirmDispatch(docs);
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dispatchItems),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: bookingRef.snapshots(),
        builder: (context, bookingSnapshot) {
          if (!bookingSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookingData =
              bookingSnapshot.data!.data() as Map<String, dynamic>;

          final status = bookingData["status"] ?? "booked";
          final isDispatched = status == "dispatched";

          return StreamBuilder<QuerySnapshot>(
            stream: bookedItemsRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              return Column(
                children: [
                  /// Dispatch All button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                        onPressed:
                            isDispatched ? null : () => dispatchAllItems(docs),
                        child: Text(
                          isDispatched
                              ? AppLocalizations.of(context)!.dispatched
                              : AppLocalizations.of(context)!.dispatchAll,
                          style: const TextStyle(fontWeight: FontWeight.w600),
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

                        final itemName = data['itemName'];
                        final requestedQty = data['requestedQuantity'];

                        final dispatchedQty = data['dispatchedQuantity'] ?? 0;

                        final remainingQty = requestedQty - dispatchedQty;

                        quantityControllers.putIfAbsent(
                          doc.id,
                          () => TextEditingController(text: "0"),
                        );

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
                                      itemName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(AppLocalizations.of(context)!
                                        .ordered(requestedQty)),
                                    Text(AppLocalizations.of(context)!
                                        .alreadyDispatched(dispatchedQty)),
                                    Text(AppLocalizations.of(context)!
                                        .remaining(remainingQty)),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              /// RIGHT SIDE (TICK + CONTROLS)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  /// GREEN TICK
                                  if (remainingQty == 0)
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
                                        onPressed: isDispatched
                                            ? null
                                            : () {
                                                int current = int.tryParse(
                                                        quantityControllers[
                                                                doc.id]!
                                                            .text) ??
                                                    0;

                                                if (current > 0) {
                                                  quantityControllers[doc.id]!
                                                          .text =
                                                      (current - 1).toString();
                                                  setState(() {});
                                                }
                                              },
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: TextField(
                                          controller:
                                              quantityControllers[doc.id],
                                          enabled: !isDispatched,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: isDispatched
                                            ? null
                                            : () {
                                                int current = int.tryParse(
                                                        quantityControllers[
                                                                doc.id]!
                                                            .text) ??
                                                    0;

                                                if (current < remainingQty) {
                                                  quantityControllers[doc.id]!
                                                          .text =
                                                      (current + 1).toString();
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
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
                              onPressed: isDispatched
                                  ? null
                                  : () => saveProgress(docs),
                              child: Text(
                                  AppLocalizations.of(context)!.saveProgress),
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
                              onPressed: isDispatched
                                  ? null
                                  : () => confirmDispatchDialog(docs),
                              child: Text(AppLocalizations.of(context)!
                                  .confirmDispatch),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20)
                ],
              );
            },
          );
        },
      ),
    );
  }
}

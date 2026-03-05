import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      int qty = int.parse(quantityControllers[doc.id]!.text);

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

      int actualDispatched = previousDispatched + qty;
      int difference = requested - actualDispatched;

      if (difference > 0) {
        final inventoryRef = FirebaseFirestore.instance
            .collection("businesses")
            .doc(widget.businessId)
            .collection("inventoryNodes")
            .doc(inventoryItemId);

        batch.update(
            inventoryRef, {"quantity": FieldValue.increment(difference)});
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
              title: const Text("Confirm Dispatch"),
              content: const Text(
                  "Once confirmed, dispatch cannot be edited.\n\nAre you sure you want to confirm dispatch?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text("Confirm"),
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
        title: const Text("Dispatch Items"),
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
                  ElevatedButton(
                    onPressed:
                        isDispatched ? null : () => dispatchAllItems(docs),
                    child: Text(
                      isDispatched ? "Dispatched" : "Dispatch All",
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

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.inventory),
                            title: Text(itemName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Ordered: $requestedQty"),
                                Text("Already Dispatched: $dispatchedQty"),
                                Text("Remaining: $remainingQty"),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 120,
                                  child: TextField(
                                    controller: quantityControllers[doc.id],
                                    enabled: !isDispatched,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Dispatch Qty",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed:
                            isDispatched ? null : () => saveProgress(docs),
                        child: const Text("Save Progress"),
                      ),
                      ElevatedButton(
                        onPressed: isDispatched
                            ? null
                            : () => confirmDispatchDialog(docs),
                        child: const Text("Confirm Dispatch"),
                      ),
                    ],
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

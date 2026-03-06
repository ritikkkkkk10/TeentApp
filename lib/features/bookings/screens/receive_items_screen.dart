import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  int qty = int.parse(quantityControllers[doc.id]!.text);

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

await FirebaseFirestore.instance
    .collection("businesses")
    .doc(widget.businessId)
    .collection("bookings")
    .doc(widget.bookingId)
    .update({
  "status": "receiving",
});

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

  String inventoryId = data["inventoryItemId"];

final inventoryRef = FirebaseFirestore.instance
    .collection("businesses")
    .doc(widget.businessId)
    .collection("inventoryNodes")
    .doc(inventoryId);

/// return received items back to inventory
batch.update(
  inventoryRef,
  {"quantity": FieldValue.increment(finalReceived)}
);

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
  "status": hasMissing ? "receiving" : "completed"
});

await batch.commit();

Navigator.pop(context);

}

Future<void> confirmReceiveDialog(List<QueryDocumentSnapshot> docs) async {

bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Receive"),
        content: const Text(
            "Once confirmed, receive quantities cannot be edited."),
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
  appBar: AppBar(title: const Text("Receive Items")),

  body: StreamBuilder<QuerySnapshot>(
    stream: bookedItemsRef.snapshots(),
    builder: (context, snapshot) {

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final docs = snapshot.data!.docs;

      return Column(
        children: [

          ElevatedButton(
            onPressed: () => receiveAllItems(docs),
            child: const Text("Receive All"),
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
                    doc.id,
                    () => TextEditingController(text: "0"));

                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text("Dispatched: $dispatched"),
                        Text("Received: $received"),
                        Text("Remaining: $remaining"),

                        const SizedBox(height: 6),

                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller:
                                quantityControllers[doc.id],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Receive Qty",
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
                onPressed: () => saveProgress(docs),
                child: const Text("Save Progress"),
              ),

              ElevatedButton(
                onPressed: () => confirmReceiveDialog(docs),
                child: const Text("Confirm Receive"),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      );
    },
  ),
);
}
}

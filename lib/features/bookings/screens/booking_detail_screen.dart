import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inventory_picker_screen.dart';
import 'dispatch_items_screen.dart';
import 'receive_items_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final String businessId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.businessId,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  void showAdvanceDialog(BuildContext context, DocumentReference bookingRef) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Enter Advance Amount"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Advance Amount",
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () async {
                double amount = double.tryParse(controller.text) ?? 0;

                await bookingRef.update({
                  "advancePaid": amount,
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void editQuantity(BuildContext context, DocumentSnapshot item) {
    final status = item["status"] ?? "";

    if (status == "completed") {
      return;
    }
    TextEditingController controller = TextEditingController(
      text: item["requestedQuantity"].toString(),
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(item["itemName"]),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Quantity"),
          ),
          actions: [
            /// REMOVE ITEM
            TextButton(
              child: const Text("Remove"),
              onPressed: () async {
                await item.reference.delete();

                Navigator.pop(context);
              },
            ),

            /// UPDATE ITEM
            TextButton(
              child: const Text("Update"),
              onPressed: () async {
                int newQty = int.parse(controller.text);

                await item.reference.update({
                  "requestedQuantity": newQty,
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingRef = FirebaseFirestore.instance
        .collection("businesses")
        .doc(widget.businessId)
        .collection("bookings")
        .doc(widget.bookingId);

    final bookedItemsRef = bookingRef.collection("bookedItems");

    final servicesRef = bookingRef.collection("bookingServices");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking"),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: bookingRef.snapshots(),
        builder: (context, bookingSnapshot) {
          if (!bookingSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookingData =
              bookingSnapshot.data!.data() as Map<String, dynamic>;

          final status = bookingData["status"] ?? "confirmed";
          final isCompleted = status == "completed";
          final isDispatched = status == "dispatched";

          return Column(
            children: [
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "RETURNED",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              /// DISPATCH / RECEIVE BUTTON

              if (status == "confirmed" || status == "dispatching")
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DispatchItemsScreen(
                          businessId: widget.businessId,
                          bookingId: widget.bookingId,
                        ),
                      ),
                    );
                  },
                  child: const Text("Dispatch Items"),
                ),

              if (status == "dispatched")
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiveItemsScreen(
                          businessId: widget.businessId,
                          bookingId: widget.bookingId,
                        ),
                      ),
                    );
                  },
                  child: const Text("Receive Items"),
                ),

              /// ITEMS
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: bookedItemsRef.snapshots(),
                  builder: (context, itemSnapshot) {
                    if (!itemSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    var items = itemSnapshot.data!.docs;

                    double estimatedTotal = 0;

                    /// ITEMS COST
                    for (var item in items) {
                      final data = item.data() as Map<String, dynamic>;

                      int requestedQty = data["requestedQuantity"] ?? 0;
                      int dispatchedQty = data["dispatchedQuantity"] ?? 0;

                      int qty =
                          dispatchedQty > 0 ? dispatchedQty : requestedQty;

                      double price =
                          (data["rentPriceSnapshot"] ?? 0).toDouble();

                      estimatedTotal += qty * price;
                    }

                    return ListView(
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: servicesRef.snapshots(),
                          builder: (context, serviceSnapshot) {
                            if (!serviceSnapshot.hasData) {
                              return const SizedBox();
                            }

                            var services = serviceSnapshot.data!.docs;

                            double serviceTotal = 0;

                            for (var service in services) {
                              serviceTotal +=
                                  (service["priceSnapshot"] ?? 0).toDouble();
                            }

                            double grandTotal = estimatedTotal + serviceTotal;

                            double advance =
                                (bookingData["advancePaid"] ?? 0).toDouble();

                            return Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Estimated Bill",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                      "Items Total: ₹${estimatedTotal.toStringAsFixed(2)}"),
                                  Text(
                                      "Services Total: ₹${serviceTotal.toStringAsFixed(2)}"),
                                  const Divider(),
                                  Text(
                                    "Total: ₹${grandTotal.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text("Advance Paid: ₹$advance"),
                                  Text("Remaining: ₹${grandTotal - advance}"),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      showAdvanceDialog(context, bookingRef);
                                    },
                                    child: const Text("Pay Advance"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        /// INVENTORY ITEMS
                        ...items.map((item) {
                          final data = item.data() as Map<String, dynamic>;

                          final requestedQty = data["requestedQuantity"] ?? 0;

                          final dispatchedQty = data["dispatchedQuantity"] ?? 0;

                          final displayQty =
                              dispatchedQty > 0 ? dispatchedQty : requestedQty;

                          return ListTile(
                            leading: const Icon(Icons.inventory),

                            title: Text(data["itemName"] ?? ""),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Qty: $displayQty"),
                                if ((data["missingQuantity"] ?? 0) > 0)
                                  Text(
                                    "Missing: ${data["missingQuantity"]}",
                                    style: const TextStyle(color: Colors.red),
                                  ),
                              ],
                            ),

                            /// DISABLE EDIT AFTER DISPATCH
                            onTap: (isDispatched || isCompleted)
                                ? null
                                : () => editQuantity(context, item),

                            trailing: (data["shortageQuantity"] ?? 0) > 0
                                ? Text(
                                    "Shortage: ${data["shortageQuantity"]}",
                                    style: const TextStyle(color: Colors.red),
                                  )
                                : null,
                          );
                        }),

                        /// SERVICES
                        StreamBuilder<QuerySnapshot>(
                          stream: servicesRef.snapshots(),
                          builder: (context, serviceSnapshot) {
                            if (!serviceSnapshot.hasData) {
                              return const SizedBox();
                            }

                            var services = serviceSnapshot.data!.docs;

                            double serviceTotal = 0;

                            for (var service in services) {
                              serviceTotal +=
                                  (service["priceSnapshot"] ?? 0).toDouble();
                            }

                            return Column(
                              children: services.map((service) {
                                return ListTile(
                                  leading:
                                      const Icon(Icons.miscellaneous_services),

                                  title: Text(service["serviceName"]),

                                  subtitle:
                                      Text("₹ ${service["priceSnapshot"]}"),

                                  /// DISABLE DELETE AFTER DISPATCH
                                  onLongPress: (isDispatched || isCompleted)
                                      ? null
                                      : () async {
                                          bool confirm = await showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      "Remove Service"),
                                                  content: const Text(
                                                      "Delete this service from booking?"),
                                                  actions: [
                                                    TextButton(
                                                      child:
                                                          const Text("Cancel"),
                                                      onPressed: () {
                                                        Navigator.pop(
                                                            context, false);
                                                      },
                                                    ),
                                                    TextButton(
                                                      child:
                                                          const Text("Delete"),
                                                      onPressed: () {
                                                        Navigator.pop(
                                                            context, true);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ) ??
                                              false;

                                          if (confirm) {
                                            await service.reference.delete();
                                          }
                                        },
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      /// ADD ITEM DISABLED AFTER DISPATCH
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: bookingRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final status = data["status"] ?? "confirmed";

          if (status != "confirmed") {
            return const SizedBox();
          }

          return FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InventoryPickerScreen(
                    bookingId: widget.bookingId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

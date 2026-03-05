import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tent_app/core/config/app_config.dart';
import 'add_item_screen.dart';
import 'select_items_screen.dart';
import 'inventory_picker_screen.dart';
import 'dispatch_items_screen.dart';

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
  void editQuantity(BuildContext context, DocumentSnapshot item) {
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
            /// DELETE OPTION
            TextButton(
              child: const Text("Remove"),
              onPressed: () async {
                await item.reference.delete();

                Navigator.pop(context);
              },
            ),

            /// UPDATE
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking"),
      ),
      floatingActionButton: FloatingActionButton(
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
      ),
      body: Column(
        children: [
          /// =========================
          /// BOOKED ITEMS
          /// =========================
          ///
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
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("businesses")
                  .doc("demo_business")
                  .collection("bookings")
                  .doc(widget.bookingId)
                  .collection("bookedItems")
                  .snapshots(),
              builder: (context, itemSnapshot) {
                if (!itemSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var items = itemSnapshot.data!.docs;

                return ListView(
                  children: [
                    /// ITEMS
                   ...items.map((item) {

  final data = item.data() as Map<String, dynamic>;

  final requestedQty = data["requestedQuantity"] ?? 0;
  final dispatchedQty = data["dispatchedQuantity"] ?? 0;

  final displayQty =
      dispatchedQty > 0 ? dispatchedQty : requestedQty;

  return ListTile(
    leading: const Icon(Icons.inventory),
    title: Text(data["itemName"] ?? ""),
    subtitle: Text("Qty: $displayQty"),
    onTap: () => editQuantity(context, item),
    trailing: (data["shortageQuantity"] ?? 0) > 0
        ? Text(
            "Shortage: ${data["shortageQuantity"]}",
            style: const TextStyle(color: Colors.red),
          )
        : null,
  );

}),

                    /// =========================
                    /// SERVICES
                    /// =========================
                    StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("businesses")
                          .doc("demo_business")
                          .collection("bookings")
                          .doc(widget.bookingId)
                          .collection("bookingServices")
                          .snapshots(),
                      builder: (context, serviceSnapshot) {
                        if (!serviceSnapshot.hasData) {
                          return const SizedBox();
                        }

                        var services = serviceSnapshot.data!.docs;

                        return Column(
                          children: services.map((service) {
                            return ListTile(
                              leading: const Icon(Icons.miscellaneous_services),
                              title: Text(service["serviceName"]),
                              subtitle: Text("₹ ${service["priceSnapshot"]}"),
                              onLongPress: () async {
                                bool confirm = await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Remove Service"),
                                        content: const Text(
                                            "Delete this service from booking?"),
                                        actions: [
                                          TextButton(
                                            child: const Text("Cancel"),
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                          ),
                                          TextButton(
                                            child: const Text("Delete"),
                                            onPressed: () {
                                              Navigator.pop(context, true);
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
      ),
    );
  }
}

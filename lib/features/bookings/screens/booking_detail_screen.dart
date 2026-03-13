import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inventory_picker_screen.dart';
import 'dispatch_items_screen.dart';
import 'receive_items_screen.dart';
import 'payment_history_screen.dart';
import '../../../core/utils/invoice_generator.dart';
import 'package:tent_app/features/inventory/services/business_profile_service.dart';

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
  bool isSavingPayment = false;

  void showPaymentDialog(
    BuildContext context,
    DocumentReference bookingRef,
    double currentPaid,
    double grandTotal,
  ) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Enter Payment Amount"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Payment Amount",
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
              child: isSavingPayment
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Save"),
              onPressed: isSavingPayment
                  ? null
                  : () async {
                      if (isSavingPayment) return;

                      setState(() {
                        isSavingPayment = true;
                      });
                      double amount = double.tryParse(controller.text) ?? 0;

                      double remaining = grandTotal - currentPaid;

                      if (amount > remaining) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text("Payment cannot exceed remaining amount"),
                          ),
                        );
                        return;
                      }

                      double newTotalPaid = currentPaid + amount;

                      if (amount > remaining) {
                        bool confirm = await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Advance exceeds remaining"),
                                content: const Text(
                                  "This payment exceeds remaining amount.\n\nContinue?",
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text("Cancel"),
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                  ),
                                  TextButton(
                                    child: const Text("Confirm"),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (!confirm) return;
                      }

                      await bookingRef.update({
                        "totalPaid": newTotalPaid,
                      });

                      await bookingRef.collection("payments").add({
                        "amount": amount,
                        "type": "payment",
                        "timestamp": Timestamp.now(),
                      });

                      Navigator.pop(context);

                      setState(() {
                        isSavingPayment = false;
                      });
                    },
            ),
          ],
        );
      },
    );
  }

  void editQuantity(
      BuildContext context, DocumentSnapshot item, bool isManual) {
    final data = item.data() as Map<String, dynamic>;

    int qty = data["requestedQuantity"] ?? 0;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                  child: const Text("Delete"),
                  onPressed: () async {
                    await item.reference.delete();

                    Navigator.pop(context);
                  },
                ),

                /// SAVE CHANGES
                TextButton(
                  child: const Text("Save"),
                  onPressed: () async {
                    int newQty = qty;

                    if (!isManual) {
                      final inventoryDoc = await FirebaseFirestore.instance
                          .collection("businesses")
                          .doc(widget.businessId)
                          .collection("inventoryNodes")
                          .doc(data["inventoryItemId"])
                          .get();

                      int totalInventory =
                          (inventoryDoc["quantity"] as num).toInt();

                      int currentQty = data["requestedQuantity"] ?? 0;

                      if (newQty >
                          totalInventory + (data["requestedQuantity"] ?? 0)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Not enough inventory"),
                          ),
                        );

                        return;
                      }
                    }

                    await item.reference.update({
                      "requestedQuantity": newQty,
                    });

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
              /// BOOKING INFO
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookingData["eventName"] ?? "",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text("Customer: ${bookingData["customerName"] ?? ""}"),
                    Text("Phone: ${bookingData["customerPhone"] ?? ""}"),
                    Text("Address: ${bookingData["customerAddress"] ?? ""}"),
                    const SizedBox(height: 6),
                    Text(
                      "Event Date: ${(bookingData["startDate"] as Timestamp).toDate().day}/"
                      "${(bookingData["startDate"] as Timestamp).toDate().month}/"
                      "${(bookingData["startDate"] as Timestamp).toDate().year}",
                    ),
                  ],
                ),
              ),

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

                    bool hasMissingItems = false;

                    for (var item in items) {
                      final data = item.data() as Map<String, dynamic>;
                      if ((data["missingQuantity"] ?? 0) > 0) {
                        hasMissingItems = true;
                        break;
                      }
                    }

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

                            double paid =
                                (bookingData["totalPaid"] ?? 0).toDouble();

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
                                  Text("Paid: ₹$paid"),
                                  Text(
                                      "Remaining: ₹${(grandTotal - paid).toStringAsFixed(2)}"),
                                  const SizedBox(height: 10),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                showPaymentDialog(
                                                  context,
                                                  bookingRef,
                                                  paid,
                                                  grandTotal,
                                                );
                                              },
                                              child: const Text("Make Payment"),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        PaymentHistoryScreen(
                                                      bookingId:
                                                          widget.bookingId,
                                                      businessId:
                                                          widget.businessId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text("History"),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                            child:
                                                const Text("Generate Invoice"),
                                            onPressed: () async {
                                              final profileService =
                                                  BusinessProfileService();
                                              final profile =
                                                  await profileService
                                                      .getProfile(
                                                          widget.businessId);

                                              if (profile == null) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "Please fill Business Profile first")),
                                                );
                                                return;
                                              }

                                              generateInvoice(
                                                context,
                                                businessName:
                                                    profile.businessName,
                                                ownerName: profile.ownerName,
                                                businessPhone: profile.phone,
                                                businessAddress:
                                                    profile.address,
                                                gst: profile.gst,
                                                customerName:
                                                    bookingData["customerName"],
                                                customerPhone: bookingData[
                                                    "customerPhone"],
                                                customerAddress: bookingData[
                                                    "customerAddress"],
                                                eventName:
                                                    bookingData["eventName"],
                                                startDate:
                                                    (bookingData["startDate"]
                                                            as Timestamp)
                                                        .toDate(),
                                                endDate: (bookingData["endDate"]
                                                        as Timestamp)
                                                    .toDate(),
                                                items: items.map((doc) {
                                                  final data = doc.data()
                                                      as Map<String, dynamic>;

                                                  return {
                                                    "name": data["itemName"],
                                                    "requested": data[
                                                        "requestedQuantity"],
                                                    "dispatched": data[
                                                        "dispatchedQuantity"],
                                                    "price": data[
                                                        "rentPriceSnapshot"],
                                                  };
                                                }).toList(),
                                                services: services.map((doc) {
                                                  final data = doc.data()
                                                      as Map<String, dynamic>;

                                                  return {
                                                    "name": data["serviceName"],
                                                    "price":
                                                        data["priceSnapshot"],
                                                  };
                                                }).toList(),
                                                total: grandTotal,
                                                paid: paid,
                                              );
                                            }),
                                      ),
                                      if (status == "receiving" &&
                                          hasMissingItems)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                              ),
                                              child:
                                                  const Text("Close Booking"),
                                              onPressed: () async {
                                                bool confirm = await showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            "Close Booking"),
                                                        content: const Text(
                                                            "Some items are missing.\n\nClose this booking?"),
                                                        actions: [
                                                          TextButton(
                                                            child: const Text(
                                                                "Cancel"),
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    false),
                                                          ),
                                                          TextButton(
                                                            child: const Text(
                                                                "Close"),
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    true),
                                                          ),
                                                        ],
                                                      ),
                                                    ) ??
                                                    false;

                                                if (!confirm) return;

                                                await bookingRef.update({
                                                  "status": "completed",
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),

                        /// INVENTORY ITEMS
                        ...items.map((item) {
                          final data = item.data() as Map<String, dynamic>;

                          bool isManual = data["isManual"] ?? false;

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
                            onTap: (isDispatched || isCompleted)
                                ? null
                                : () => editQuantity(context, item, isManual),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if ((data["shortageQuantity"] ?? 0) > 0)
                                  Text(
                                    "Shortage: ${data["shortageQuantity"]}",
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                if (!(isDispatched || isCompleted))
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        editQuantity(context, item, isManual),
                                  ),
                              ],
                            ),
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

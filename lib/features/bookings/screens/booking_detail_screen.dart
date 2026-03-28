import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inventory_picker_screen.dart';
import 'dispatch_items_screen.dart';
import 'receive_items_screen.dart';
import 'payment_history_screen.dart';
import '../../../core/utils/invoice_generator.dart';
import 'package:tent_app/features/inventory/services/business_profile_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/payment_dialog.dart';

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
                        .doc(widget.businessId)
                        .collection("bookedItems");

                    final globalDocs = await globalRef
                        .where("bookingId", isEqualTo: widget.bookingId)
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

                    String businessId = widget.businessId;

                    final globalRef = FirebaseFirestore.instance
                        .collection("businesses")
                        .doc(businessId)
                        .collection("bookedItems");

                    /// find matching global entries
                    final globalDocs = await globalRef
                        .where("bookingId", isEqualTo: widget.bookingId)
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
        title: Text(AppLocalizations.of(context)!.booking),
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
          bool isReceiving = status == "receiving";

          return Column(
            children: [
              /// BOOKING INFO

              if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.returned,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              /// DISPATCH / RECEIVE BUTTON

              if (status == "confirmed" || status == "dispatching")
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4FA3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon:
                          const Icon(Icons.local_shipping, color: Colors.white),
                      label: Text(
                        AppLocalizations.of(context)!.dispatchItems,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
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
                    ),
                  ),
                ),

              if (status == "dispatched")
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4FA3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.assignment_return,
                          color: Colors.white),
                      label: Text(
                        AppLocalizations.of(context)!.receiveItems,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
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
                    ),
                  ),
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
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          padding: const EdgeInsets.all(16),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// EVENT NAME
                              Row(
                                children: [
                                  const Icon(Icons.event,
                                      color: Color(0xFF1E4FA3)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      bookingData["eventName"] ?? "",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              /// CUSTOMER NAME
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    bookingData["customerName"] ?? "",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// PHONE
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    bookingData["customerPhone"] ?? "",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// ADDRESS
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      bookingData["customerAddress"] ?? "",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              /// EVENT DATE
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${(bookingData["startDate"] as Timestamp).toDate().day}/"
                                    "${(bookingData["startDate"] as Timestamp).toDate().month}/"
                                    "${(bookingData["startDate"] as Timestamp).toDate().year}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                padding: const EdgeInsets.all(16),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.receipt_long,
                                            color: Color(0xFF1E4FA3)),
                                        SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .estimatedBill,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 14),

                                    Text(
                                      AppLocalizations.of(context)!.itemsTotal(
                                          estimatedTotal.toStringAsFixed(2)),
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .servicesTotal(
                                              serviceTotal.toStringAsFixed(2)),
                                    ),

                                    const Divider(height: 24),

                                    Text(
                                      AppLocalizations.of(context)!.grandTotal(
                                          grandTotal.toStringAsFixed(2)),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(AppLocalizations.of(context)!
                                        .paid(paid)),

                                    Text(
                                      AppLocalizations.of(context)!
                                          .remainingAmount((grandTotal - paid)
                                              .toStringAsFixed(2)),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),

                                    const SizedBox(height: 16),

                                    /// PAYMENT BUTTONS
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF1E4FA3),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              icon: const Icon(Icons.payments,
                                                  color: Colors.white),
                                              label: Text(
                                                AppLocalizations.of(context)!
                                                    .makePayment,
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              onPressed: () {
                                                showPaymentDialog(
                                                  context,
                                                  bookingRef,
                                                  paid,
                                                  grandTotal,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: SizedBox(
                                            height: 48,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF1E4FA3),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              icon: const Icon(Icons.history,
                                                  color: Colors.white),
                                              label: Text(
                                                AppLocalizations.of(context)!
                                                    .history,
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
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
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    /// INVOICE BUTTON
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: Row(
                                        children: [
                                          /// 🔹 PREVIEW BUTTON
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF1E4FA3),
                                                shape:
                                                    const RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft: Radius.circular(8),
                                                    bottomLeft:
                                                        Radius.circular(8),
                                                  ),
                                                ),
                                              ),
                                              icon: const Icon(Icons.visibility,
                                                  color: Colors.white),
                                              label: Text(
                                                AppLocalizations.of(context)!
                                                    .preview,
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
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
                                                    SnackBar(
                                                      content: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .fillBusinessProfile),
                                                    ),
                                                  );
                                                  return;
                                                }

                                                generateInvoice(
                                                  context,
                                                  isPreview:
                                                      true, // 👈 IMPORTANT
                                                  businessName:
                                                      profile.businessName,
                                                  ownerName: profile.ownerName,
                                                  businessPhone: profile.phone,
                                                  businessAddress:
                                                      profile.address,
                                                  gst: profile.gst,
                                                  customerName: bookingData[
                                                      "customerName"],
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
                                                  endDate:
                                                      (bookingData["endDate"]
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
                                                      "name":
                                                          data["serviceName"],
                                                      "price":
                                                          data["priceSnapshot"],
                                                    };
                                                  }).toList(),
                                                  total: grandTotal,
                                                  paid: paid,
                                                );
                                              },
                                            ),
                                          ),

                                          /// 🔹 SEND WHATSAPP BUTTON
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape:
                                                    const RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(8),
                                                    bottomRight:
                                                        Radius.circular(8),
                                                  ),
                                                ),
                                              ),
                                              icon: const Icon(Icons.send,
                                                  color: Colors.white),
                                              label: Text(
                                                AppLocalizations.of(context)!
                                                    .send,
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
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
                                                    SnackBar(
                                                      content: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .fillBusinessProfile),
                                                    ),
                                                  );
                                                  return;
                                                }

                                                generateInvoice(
                                                  context,
                                                  isPreview:
                                                      false, // 👈 IMPORTANT
                                                  businessName:
                                                      profile.businessName,
                                                  ownerName: profile.ownerName,
                                                  businessPhone: profile.phone,
                                                  businessAddress:
                                                      profile.address,
                                                  gst: profile.gst,
                                                  customerName: bookingData[
                                                      "customerName"],
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
                                                  endDate:
                                                      (bookingData["endDate"]
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
                                                      "name":
                                                          data["serviceName"],
                                                      "price":
                                                          data["priceSnapshot"],
                                                    };
                                                  }).toList(),
                                                  total: grandTotal,
                                                  paid: paid,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ));
                          },
                        ),

                        /// INVENTORY ITEMS

                        /// SERVICES
                        StreamBuilder<QuerySnapshot>(
                          stream: servicesRef.snapshots(),
                          builder: (context, serviceSnapshot) {
                            if (!serviceSnapshot.hasData) {
                              return const SizedBox();
                            }

                            var services = serviceSnapshot.data!.docs;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// ITEMS
                                  ...items.map((item) {
                                    final data =
                                        item.data() as Map<String, dynamic>;

                                    bool isManual = data["isManual"] ?? false;

                                    final requestedQty =
                                        data["requestedQuantity"] ?? 0;
                                    final dispatchedQty =
                                        data["dispatchedQuantity"] ?? 0;

                                    final displayQty = dispatchedQty > 0
                                        ? dispatchedQty
                                        : requestedQty;

                                    return Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.inventory,
                                                size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                data["itemName"] ?? "",
                                                style: const TextStyle(
                                                    fontSize: 15),
                                              ),
                                            ),
                                            Text(
                                              "Qty: $displayQty",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            if (!(isDispatched ||
                                                isCompleted ||
                                                isReceiving))
                                              GestureDetector(
                                                onTap: () => editQuantity(
                                                    context, item, isManual),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade400),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .edit,
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if ((data["missingQuantity"] ?? 0) > 0)
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                "Missing: ${data["missingQuantity"]}",
                                                style: const TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ),
                                        const Divider(height: 22),
                                      ],
                                    );
                                  }),

                                  /// SERVICES TITLE
                                  if (services.isNotEmpty)
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 6),
                                      child: Text(
                                        AppLocalizations.of(context)!.services,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),

                                  /// SERVICES LIST
                                  ...services.map((service) {
                                    return GestureDetector(
                                      onLongPress: (isDispatched || isCompleted)
                                          ? null
                                          : () async {
                                              bool confirm = await showDialog(
                                                    context: context,
                                                    builder: (_) => AlertDialog(
                                                      backgroundColor:
                                                          Colors.white,
                                                      title: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .removeService),
                                                      content: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .deleteServiceConfirm),
                                                      actions: [
                                                        TextButton(
                                                          style: TextButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                const Color(
                                                                    0xFF1E4FA3),
                                                          ),
                                                          child: Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .cancel),
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                        ),
                                                        TextButton(
                                                          style: TextButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                const Color(
                                                                    0xFF1E4FA3),
                                                          ),
                                                          child: Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .delete),
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  true),
                                                        ),
                                                      ],
                                                    ),
                                                  ) ??
                                                  false;

                                              if (confirm) {
                                                await service.reference
                                                    .delete();
                                              }
                                            },
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.miscellaneous_services,
                                                  size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                    service["serviceName"]),
                                              ),
                                              Text(
                                                "₹ ${service["priceSnapshot"]}",
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 22),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        )
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
            backgroundColor: Colors.white,
            child: const Icon(
              Icons.add,
              color: Color(0xFF1E4FA3),
            ),
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

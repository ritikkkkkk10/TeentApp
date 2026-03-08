import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_detail_screen.dart';

class PendingPaymentsScreen extends StatelessWidget {
  final String businessId;

  const PendingPaymentsScreen({
    super.key,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    final bookingsRef = FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
        .collection("bookings");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Payments"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          return ListView(
            children: bookings.map((booking) {
              final data = booking.data() as Map<String, dynamic>;

              final bookingRef = FirebaseFirestore.instance
                  .collection("businesses")
                  .doc(businessId)
                  .collection("bookings")
                  .doc(booking.id);

              return StreamBuilder<QuerySnapshot>(
                stream: bookingRef.collection("bookedItems").snapshots(),
                builder: (context, itemSnap) {
                  if (!itemSnap.hasData) return const SizedBox();

                  var items = itemSnap.data!.docs;

                  double itemsTotal = 0;

                  for (var item in items) {
                    final itemData = item.data() as Map<String, dynamic>;

                    int requested = itemData["requestedQuantity"] ?? 0;
                    int dispatched = itemData["dispatchedQuantity"] ?? 0;

                    int qty = dispatched > 0 ? dispatched : requested;

                    double price =
                        (itemData["rentPriceSnapshot"] ?? 0).toDouble();

                    itemsTotal += qty * price;
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream:
                        bookingRef.collection("bookingServices").snapshots(),
                    builder: (context, serviceSnap) {
                      if (!serviceSnap.hasData) return const SizedBox();

                      var services = serviceSnap.data!.docs;

                      double servicesTotal = 0;

                      for (var service in services) {
                        servicesTotal +=
                            (service["priceSnapshot"] ?? 0).toDouble();
                      }

                      double grandTotal = itemsTotal + servicesTotal;

                      double paid = (data["totalPaid"] ?? 0).toDouble();

                      double remaining = grandTotal - paid;

                      DateTime startDate =
                          (data["startDate"] as Timestamp).toDate();

                      DateTime today = DateTime.now();

                      bool eventStarted = !startDate.isAfter(today);

                      String status = data["status"] ?? "confirmed";

                      if (remaining <= 0) return const SizedBox();

                      if (!(eventStarted ||
                          status == "dispatched" ||
                          status == "receiving")) {
                        return const SizedBox();
                      }

String dateText =
    "${startDate.day}/${startDate.month}/${startDate.year}";

                      return ListTile(
                        leading: const Icon(Icons.payments),
                        title: Text(data["eventName"] ?? ""),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data["customerName"] ?? ""),
                            Text("Date: $dateText"),
                            Text("Status: ${data["status"]}"),
                            Text("Remaining: ₹${remaining.toStringAsFixed(2)}"),
                          ],
                        ),
                        trailing: const Text("View"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailScreen(
                                bookingId: booking.id,
                                businessId: businessId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_detail_screen.dart';

class TodayPaymentsScreen extends StatelessWidget {
  final String businessId;

  const TodayPaymentsScreen({
    super.key,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    final bookingsRef = FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
        .collection("bookings");

    DateTime now = DateTime.now();

    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Payments"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsRef.snapshots(),
        builder: (context, bookingSnap) {
          if (!bookingSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = bookingSnap.data!.docs;

          List<Widget> paymentTiles = [];

          for (var booking in bookings) {
            final bookingRef = bookingsRef.doc(booking.id);

            paymentTiles.add(
              StreamBuilder<QuerySnapshot>(
                stream: bookingRef.collection("payments").snapshots(),
                builder: (context, paymentSnap) {
                  if (!paymentSnap.hasData) return const SizedBox();

                  List<Widget> tiles = [];

                  for (var payment in paymentSnap.data!.docs) {
                    final data = payment.data() as Map<String, dynamic>;

                    Timestamp ts = data["timestamp"];
                    DateTime time = ts.toDate();

                    if (time.isAfter(startOfDay) &&
                        time.isBefore(endOfDay)) {
                      final bookingData =
                          booking.data() as Map<String, dynamic>;

                      double amount =
                          (data["amount"] ?? 0).toDouble();

                      tiles.add(
                        ListTile(
                          leading: const Icon(Icons.payments),
                          title: Text(bookingData["eventName"] ?? ""),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                  bookingData["customerName"] ?? ""),
                              Text("Paid: ₹$amount"),
                              Text("${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}"),
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
                        ),
                      );
                    }
                  }

                  return Column(children: tiles);
                },
              ),
            );
          }

          if (paymentTiles.isEmpty) {
            return const Center(
              child: Text("No payments received today"),
            );
          }

          return ListView(children: paymentTiles);
        },
      ),
    );
  }
}
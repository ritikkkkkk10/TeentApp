import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_detail_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.todaysPayments),
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

                    if (time.isAfter(startOfDay) && time.isBefore(endOfDay)) {
                      final bookingData =
                          booking.data() as Map<String, dynamic>;

                      double amount = (data["amount"] ?? 0).toDouble();

                      tiles.add(
                        Card(
                          color: Colors.white,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
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
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  /// BLUE ICON
                                  Icon(
                                    Icons.payments,
                                    color: Theme.of(context)
                                            .appBarTheme
                                            .backgroundColor ??
                                        Theme.of(context).primaryColor,
                                    size: 26,
                                  ),

                                  const SizedBox(width: 12),

                                  /// LEFT SIDE DETAILS
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// CUSTOMER NAME
                                        Text(
                                          bookingData["customerName"] ?? "",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        /// EVENT
                                        Text(
                                          bookingData["eventName"] ?? "",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        /// TIME
                                        Text(
                                          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// RIGHT SIDE
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      /// PAID BADGE
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
  AppLocalizations.of(context)!.paidToday,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      /// AMOUNT
                                      Text(
                                        "₹${amount.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
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

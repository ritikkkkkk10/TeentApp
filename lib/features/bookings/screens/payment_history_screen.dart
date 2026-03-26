import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PaymentHistoryScreen extends StatelessWidget {
  final String bookingId;
  final String businessId;

  const PaymentHistoryScreen({
    super.key,
    required this.bookingId,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    final paymentsRef = FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
        .collection("bookings")
        .doc(bookingId)
        .collection("payments")
        .orderBy("timestamp", descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.history),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: paymentsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = snapshot.data!.docs;

          if (payments.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noBookings),
            );
          }

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final data = payments[index];

              double amount =
                  (data["amount"] ?? 0).toDouble();

              Timestamp ts = data["timestamp"];

              DateTime date = ts.toDate();

              return ListTile(
                leading: const Icon(Icons.payments),
                title: Text("₹$amount"),
                subtitle: Text(date.toString()),
              );
            },
          );
        },
      ),
    );
  }
}
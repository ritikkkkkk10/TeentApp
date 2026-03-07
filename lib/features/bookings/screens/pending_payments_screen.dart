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

          List<DocumentSnapshot> pendingBookings = [];

          for (var booking in bookings) {

            final data = booking.data() as Map<String, dynamic>;

            double totalPaid =
                (data["totalPaid"] ?? 0).toDouble();

            if (data["status"] == "completed") continue;

            pendingBookings.add(booking);
          }

          if (pendingBookings.isEmpty) {
            return const Center(
              child: Text("No pending payments"),
            );
          }

          return ListView.builder(
            itemCount: pendingBookings.length,
            itemBuilder: (context, index) {

              final booking = pendingBookings[index];
              final data = booking.data() as Map<String, dynamic>;

              return ListTile(
                leading: const Icon(Icons.payments),

                title: Text(data["eventName"] ?? ""),

                subtitle: Text(data["customerName"] ?? ""),

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
      ),
    );
  }
}
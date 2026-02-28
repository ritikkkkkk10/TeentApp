import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_detail_screen.dart';
import 'create_booking_screen.dart';

class BookingsListScreen extends StatelessWidget {
  const BookingsListScreen({super.key});

  final String businessId = "demo_business";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bookings")),
      

        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const CreateBookingScreen(),
              ),
            );
          },
        ),


        body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("businesses")
            .doc(businessId)
            .collection("bookings")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          var bookings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {

              var booking = bookings[index];

              return ListTile(
                title:
                    Text(booking["eventName"]),
                subtitle:
                    Text(booking["customerName"]),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingDetailScreen(
                              bookingId:
                                  booking.id),
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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tent_app/core/config/app_config.dart';
import 'add_item_screen.dart';

class BookingDetailScreen extends StatefulWidget {

  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState
    extends State<BookingDetailScreen> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking"),
      ),

      floatingActionButton:
          FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddItemScreen(
                bookingId: widget.bookingId,
              ),
            ),
          );
        },
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("businesses")
            .doc("demo_business") // ✅ TEMP SAFE
            .collection("bookings")
            .doc(widget.bookingId)
            .collection("bookedItems")
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(
              child: Text("No items added"),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {

              var item = items[index];

              return ListTile(
                title: Text(item["itemName"]),
                subtitle: Text(
                    "Qty: ${item["requestedQuantity"]}"),
                trailing:
                    item["shortageQuantity"] > 0
                        ? Text(
                            "Shortage: ${item["shortageQuantity"]}",
                            style: const TextStyle(
                                color: Colors.red),
                          )
                        : null,
              );
            },
          );
        },
      ),
    );
  }
}
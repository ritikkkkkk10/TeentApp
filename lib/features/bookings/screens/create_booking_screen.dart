import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/booking_model.dart';
import '../repository/booking_repository.dart';
import '../models/booked_item_model.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  State<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState
    extends State<CreateBookingScreen> {

  final TextEditingController eventController =
      TextEditingController();

  final TextEditingController customerController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  final BookingRepository repository =
      BookingRepository();

  Future<void> pickDate(bool isStart) async {

    DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startDate = picked;
      } else {
        endDate = picked;
      }
    });
  }

  Future<void> saveBooking() async {

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select dates")),
      );
      return;
    }

    String bookingId = const Uuid().v4();

    BookingModel booking = BookingModel(
      id: bookingId,
      eventName: eventController.text,
      customerName: customerController.text,
      customerPhone: phoneController.text,
      startDate: startDate!,
      endDate: endDate!,
      status: "confirmed",
      createdAt: Timestamp.now(),
    );

    await repository.createBooking(booking);

    String bookedItemId = const Uuid().v4();

    BookedItemModel testItem = BookedItemModel(
      id: bookedItemId,
      inventoryItemId: "chair_001",
      itemName: "Plastic Chair",
      requestedQuantity: 50,
      availableQuantityAtBooking: 30,
      shortageQuantity: 20,
      rentPriceSnapshot: 10,
      createdAt: Timestamp.now(),
    );

    await repository.addBookedItem(
      bookingId: bookingId,
      item: testItem,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Booking"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: eventController,
              decoration:
                  const InputDecoration(
                      labelText: "Event Name"),
            ),

            TextField(
              controller: customerController,
              decoration:
                  const InputDecoration(
                      labelText: "Customer Name"),
            ),

            TextField(
              controller: phoneController,
              decoration:
                  const InputDecoration(
                      labelText: "Phone"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => pickDate(true),
              child: Text(
                  startDate == null
                      ? "Select Start Date"
                      : startDate.toString()),
            ),

            ElevatedButton(
              onPressed: () => pickDate(false),
              child: Text(
                  endDate == null
                      ? "Select End Date"
                      : endDate.toString()),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: saveBooking,
              child:
                  const Text("Save Booking"),
            ),
          ],
        ),
      ),
    );
  }
}
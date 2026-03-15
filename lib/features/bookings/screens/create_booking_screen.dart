import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/booking_model.dart';
import '../repository/booking_repository.dart';
import 'inventory_picker_screen.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final TextEditingController eventController = TextEditingController();

  final TextEditingController customerController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  final BookingRepository repository = BookingRepository();

  Widget buildInputCard({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 58,
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
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1E4FA3)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDateCard({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          height: 58,
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
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1E4FA3)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: saveBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E4FA3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          "Save & Add Items",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// ===============================
  /// DATE PICKER
  /// ===============================
  Future<void> pickDate(bool isStart) async {
  DateTime? picked = await showDatePicker(
    context: context,
    firstDate: DateTime.now(),
    lastDate: DateTime(2030),
    initialDate: DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E4FA3), // toolbar blue
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
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

  /// ===============================
  /// SAVE BOOKING + OPEN ITEMS
  /// ===============================
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
      customerAddress: addressController.text,
      startDate: startDate!,
      endDate: endDate!,
      status: "confirmed",
      createdAt: Timestamp.now(),
    );

    /// CREATE BOOKING
    await repository.createBooking(booking);

    /// OPEN ITEM PICKER
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryPickerScreen(
          bookingId: bookingId,
        ),
      ),
    );
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Booking"),
      ),
      body: Container(
        color: const Color(0xFFF2F3F7),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            buildInputCard(
              icon: Icons.event,
              hint: "Event Name",
              controller: eventController,
            ),
            buildInputCard(
              icon: Icons.person,
              hint: "Customer Name",
              controller: customerController,
            ),
            buildInputCard(
              icon: Icons.phone,
              hint: "Phone",
              controller: phoneController,
            ),
            buildInputCard(
              icon: Icons.location_on,
              hint: "Customer Address",
              controller: addressController,
            ),
            const SizedBox(height: 8),
            buildDateCard(
              icon: Icons.calendar_today,
              text: startDate == null
                  ? "Select Start Date"
                  : startDate!.toLocal().toString().split(" ")[0],
              onTap: () => pickDate(true),
            ),
            buildDateCard(
              icon: Icons.calendar_today,
              text: endDate == null
                  ? "Select End Date"
                  : endDate!.toLocal().toString().split(" ")[0],
              onTap: () => pickDate(false),
            ),
            const SizedBox(height: 30),
            buildSaveButton(),
          ],
        ),
      ),
    );
  }
}

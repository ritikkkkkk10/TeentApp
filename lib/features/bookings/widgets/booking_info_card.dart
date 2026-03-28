import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BookingInfoCard extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const BookingInfoCard({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    return Container(
      // paste your full container here
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              const Icon(Icons.event, color: Color(0xFF1E4FA3)),
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
              const Icon(Icons.location_on_outlined, size: 20),
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
              const Icon(Icons.calendar_today_outlined, size: 18),
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
    );
  }
}

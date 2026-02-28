import 'package:flutter/material.dart';
import 'package:tent_app/features/bookings/screens/create_booking_screen.dart';

import '../features/inventory/screens/inventory_screen.dart';
import 'package:tent_app/features/bookings/screens/create_booking_screen.dart';
import 'package:tent_app/features/bookings/screens/bookings_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BookingsListScreen(),
            ),
          );
        },
        child: const Text("Bookings"),
  ),
),
    );
  }
}
import 'package:flutter/material.dart';

import 'package:tent_app/features/bookings/screens/bookings_list_screen.dart';
import 'package:tent_app/features/inventory/screens/inventory_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tent Manager"),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            /// BOOKINGS BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const BookingsListScreen(),
                  ),
                );
              },
              child:
                  const Text("Bookings"),
            ),

            const SizedBox(height: 20),

            /// INVENTORY BUTTON ✅
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const InventoryScreen(),
                  ),
                );
              },
              child: const Text(
                  "Update Inventory"),
            ),
          ],
        ),
      ),
    );
  }
}
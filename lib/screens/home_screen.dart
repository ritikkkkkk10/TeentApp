import 'package:flutter/material.dart';

import '../features/inventory/screens/inventory_screen.dart';

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
              builder: (_) => const InventoryScreen(),
            ),
          );
        },
        child: const Text("Open Inventory"),
  ),
),
    );
  }
}
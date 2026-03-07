import 'package:flutter/material.dart';
import 'package:tent_app/features/bookings/screens/bookings_list_screen.dart';
import 'package:tent_app/features/inventory/screens/inventory_screen.dart';
import 'package:tent_app/core/config/app_config.dart';
import 'package:tent_app/features/bookings/screens/pending_payments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? businessId;

  @override
  void initState() {
    super.initState();
    loadBusiness();
  }

  Future<void> loadBusiness() async {
    businessId = await getBusinessId();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (businessId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tent Manager"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// BOOKINGS BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingsListScreen(
                      businessId: businessId!,
                    ),
                  ),
                );
              },
              child: const Text("Bookings"),
            ),

            const SizedBox(height: 20),

            /// INVENTORY BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InventoryScreen(),
                  ),
                );
              },
              child: const Text("Update Inventory"),
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.payments),
              label: const Text("Pending Payments"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PendingPaymentsScreen(
                      businessId: businessId!,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

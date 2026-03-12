import 'package:flutter/material.dart';
import 'package:tent_app/features/bookings/screens/bookings_list_screen.dart';
import 'package:tent_app/features/inventory/screens/inventory_screen.dart';
import 'package:tent_app/core/config/app_config.dart';
import 'package:tent_app/features/bookings/screens/pending_payments_screen.dart';
import 'package:tent_app/features/bookings/screens/business_profile_screen.dart';
import 'package:tent_app/features/bookings/screens/bookings_calendar_screen.dart';
import 'package:tent_app/features/bookings/screens/today_payments_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          /// TODAY PAYMENTS DASHBOARD
          Padding(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup("payments")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                double todayTotal = 0;

                DateTime now = DateTime.now();
                DateTime startOfDay = DateTime(now.year, now.month, now.day);

                DateTime endOfDay =
                    DateTime(now.year, now.month, now.day, 23, 59, 59);

                for (var doc in snapshot.data!.docs) {
                  /// ensure payment belongs to this business
                  String bookingBusinessId =
                      doc.reference.parent.parent!.parent!.parent!.id;

                  if (bookingBusinessId != businessId) continue;

                  final data = doc.data() as Map<String, dynamic>;

                  Timestamp ts = data["timestamp"];
                  DateTime time = ts.toDate();

                  if (time.isAfter(startOfDay) && time.isBefore(endOfDay)) {
                    todayTotal += (data["amount"] ?? 0).toDouble();
                  }
                }

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TodayPaymentsScreen(
                          businessId: businessId!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Today's Payments",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "₹${todayTotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// ORIGINAL BUTTONS
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingsCalendarScreen(
                            businessId: businessId!,
                          ),
                        ),
                      );
                    },
                    child: const Text("Bookings Calendar"),
                  ),
                  const SizedBox(height: 20),
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
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.business),
                    label: const Text("Business Profile"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BusinessProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

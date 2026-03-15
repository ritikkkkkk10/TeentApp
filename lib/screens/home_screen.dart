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
import '../../core/widgets/app_menu.dart';
import 'package:tent_app/core/widgets/bookings_calendar_widget.dart';
import 'package:tent_app/features/bookings/screens/create_booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? businessId;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadBusiness();
  }

  Future<void> loadBusiness() async {
    businessId = await getBusinessId();
    setState(() {});
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getScreen() {
    switch (_selectedIndex) {
      /// HOME TAB
      case 0:
        return _homeContent();

      /// BOOKINGS TAB
      case 1:
        return BookingsListScreen(
          businessId: businessId!,
        );

      /// INVENTORY TAB
      case 2:
        return const InventoryScreen();

      /// PAYMENTS TAB
      case 3:
        return PendingPaymentsScreen(
          businessId: businessId!,
        );

      default:
        return _homeContent();
    }
  }

  Widget _homeContent() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4FA3),
        centerTitle: true,
        title: const Text(
          "Home",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [
          AppMenu(),
        ],
      ),
      body: Column(
        children: [
          /// WELCOME MESSAGE
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Welcome back!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Good to see you again",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        /// ICON
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E4FA3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.payments,
                            color: Color(0xFF1E4FA3),
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 14),

                        /// TEXT SECTION
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Today's Payments",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
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

                        /// ARROW
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// MINI CALENDAR
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingsCalendarScreen(
                              businessId: businessId!,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: BookingsCalendarWidget(
                            businessId: businessId!,
                            isMini: true,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// NEW BOOKING BUTTON
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text(
                          "New Booking",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E4FA3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateBookingScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (businessId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        /// if not on home tab → go to home
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }

        /// if already on home → allow app close
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: _getScreen(),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              )
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1E4FA3),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: "Bookings",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory),
                label: "Inventory",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments),
                label: "Payments",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

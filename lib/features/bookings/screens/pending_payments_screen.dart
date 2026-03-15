import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_detail_screen.dart';

class PendingPaymentsScreen extends StatefulWidget {
  final String businessId;

  const PendingPaymentsScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<PendingPaymentsScreen> createState() => _PendingPaymentsScreenState();
}

class _PendingPaymentsScreenState extends State<PendingPaymentsScreen>
    with SingleTickerProviderStateMixin {
  Future<double> calculateTotalPending(
      List<QueryDocumentSnapshot> bookings, String? statusFilter) async {
    final firestore = FirebaseFirestore.instance;

    double total = 0;

    for (var booking in bookings) {
      final data = booking.data() as Map<String, dynamic>;
      String status = data["status"] ?? "confirmed";

      if (statusFilter != null && status != statusFilter) continue;

      final bookingRef = firestore
          .collection("businesses")
          .doc(widget.businessId)
          .collection("bookings")
          .doc(booking.id);

      final itemsSnap = await bookingRef.collection("bookedItems").get();

      double itemsTotal = 0;

      for (var item in itemsSnap.docs) {
        final itemData = item.data();

        int requested = itemData["requestedQuantity"] ?? 0;
        int dispatched = itemData["dispatchedQuantity"] ?? 0;

        int qty = dispatched > 0 ? dispatched : requested;

        double price = (itemData["rentPriceSnapshot"] ?? 0).toDouble();

        itemsTotal += qty * price;
      }

      final servicesSnap = await bookingRef.collection("bookingServices").get();

      double servicesTotal = 0;

      for (var service in servicesSnap.docs) {
        servicesTotal += (service["priceSnapshot"] ?? 0).toDouble();
      }

      double grandTotal = itemsTotal + servicesTotal;

      double paid = (data["totalPaid"] ?? 0).toDouble();

      double remaining = grandTotal - paid;

      DateTime startDate = (data["startDate"] as Timestamp).toDate();

      DateTime today = DateTime.now();

      bool eventStarted = !startDate.isAfter(today);

      if (!(eventStarted ||
          status == "dispatched" ||
          status == "receiving" ||
          status == "completed")) {
        continue;
      }

      if (remaining > 0) {
        total += remaining;
      }
    }

    return total;
  }

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Payments"),
      ),
      body: Column(
        children: [
          /// TAB BUTTONS
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).appBarTheme.backgroundColor ??
                      Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black87,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "All"),
                  Tab(text: "Dispatched"),
                  Tab(text: "Receiving"),
                  Tab(text: "Completed"),
                ],
              ),
            ),
          ),

          /// TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildBookingsList(null),
                buildBookingsList("dispatched"),
                buildBookingsList("receiving"),
                buildBookingsList("completed"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBookingsList(String? statusFilter) {
    final bookingsRef = FirebaseFirestore.instance
        .collection("businesses")
        .doc(widget.businessId)
        .collection("bookings");

    return StreamBuilder<QuerySnapshot>(
      stream: bookingsRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;

        List<Widget> tiles = [];
        double totalPending = 0;

        for (var booking in bookings) {
          final data = booking.data() as Map<String, dynamic>;

          String status = data["status"] ?? "confirmed";

          /// FILTER BASED ON TAB
          if (statusFilter != null && status != statusFilter) {
            continue;
          }

          final bookingRef = FirebaseFirestore.instance
              .collection("businesses")
              .doc(widget.businessId)
              .collection("bookings")
              .doc(booking.id);

          tiles.add(
            StreamBuilder<QuerySnapshot>(
              stream: bookingRef.collection("bookedItems").snapshots(),
              builder: (context, itemSnap) {
                if (!itemSnap.hasData) return const SizedBox();

                var items = itemSnap.data!.docs;

                double itemsTotal = 0;

                for (var item in items) {
                  final itemData = item.data() as Map<String, dynamic>;

                  int requested = itemData["requestedQuantity"] ?? 0;

                  int dispatched = itemData["dispatchedQuantity"] ?? 0;

                  int qty = dispatched > 0 ? dispatched : requested;

                  double price =
                      (itemData["rentPriceSnapshot"] ?? 0).toDouble();

                  itemsTotal += qty * price;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: bookingRef.collection("bookingServices").snapshots(),
                  builder: (context, serviceSnap) {
                    if (!serviceSnap.hasData) {
                      return const SizedBox();
                    }

                    var services = serviceSnap.data!.docs;

                    double servicesTotal = 0;

                    for (var service in services) {
                      servicesTotal +=
                          (service["priceSnapshot"] ?? 0).toDouble();
                    }

                    double grandTotal = itemsTotal + servicesTotal;

                    double paid = (data["totalPaid"] ?? 0).toDouble();

                    double remaining = grandTotal - paid;

                    DateTime startDate =
                        (data["startDate"] as Timestamp).toDate();

                    DateTime today = DateTime.now();

                    bool eventStarted = !startDate.isAfter(today);

                    if (remaining <= 0) {
                      return const SizedBox();
                    }

                    if (!(eventStarted ||
                        status == "dispatched" ||
                        status == "receiving" ||
                        status == "completed")) {
                      return const SizedBox();
                    }

                    totalPending += remaining;

                    String dateText =
                        "${startDate.day}/${startDate.month}/${startDate.year}";

                    return ListTile(
                      leading: const Icon(Icons.payments),
                      title: Text(data["eventName"] ?? ""),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data["customerName"] ?? ""),
                          Text("Date: $dateText"),
                          Text("Status: $status"),
                          Text(
                            "Remaining: ₹${remaining.toStringAsFixed(2)}",
                          ),
                        ],
                      ),
                      trailing: const Text("View"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingDetailScreen(
                              bookingId: booking.id,
                              businessId: widget.businessId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        }

        return Column(
          children: [
            FutureBuilder<double>(
              future: calculateTotalPending(bookings, statusFilter),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox();
                }

                return Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFDCEBFF),
                        Color(0xFFF1F7FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Pending",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "₹${snap.data!.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: tiles,
              ),
            ),
          ],
        );
      },
    );
  }
}

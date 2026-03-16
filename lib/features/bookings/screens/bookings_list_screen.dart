import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_detail_screen.dart';
import 'create_booking_screen.dart';

class BookingsListScreen extends StatefulWidget {
  final String businessId;

  const BookingsListScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Color _statusColor(String status) {
    switch (status) {
      case "confirmed":
        return Colors.orange;

      case "dispatching":
        return Colors.blue;

      case "dispatched":
        return Colors.green;

      case "receiving":
        return Colors.purple;

      case "completed":
        return Colors.grey;

      default:
        return Colors.black;
    }
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);

    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            filter = "all";
            break;
          case 1:
            filter = "pending";
            break;
          case 2:
            filter = "dispatched";
            break;
          case 3:
            filter = "receiving";
            break;
          case 4:
            filter = "history";
            break;
        }
      });
    });
  }

  String filter =
      "all"; // all, pending, dispatched, receiving, history, missing

  TextEditingController searchController = TextEditingController();
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4FA3),
        centerTitle: true,
        title: const Text(
          "Bookings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  )
                ],
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFF1E4FA3),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF1E4FA3),
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: "All"),
                  Tab(text: "Pending"),
                  Tab(text: "Dispatched"),
                  Tab(text: "Receiving"),
                  Tab(text: "History"),
                ],
              ),
            ),
          ),

          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by customer, event or phone",
                prefixIcon: const Icon(Icons.search),

                filled: true,
                fillColor: Colors.white, // white search area

                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ), // reduces height

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E4FA3),
                    width: 1,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          const SizedBox(height: 8),

          /// BOOKINGS LIST
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(
                5,
                (index) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("businesses")
                        .doc(widget.businessId)
                        .collection("bookings")
                        .orderBy("startDate", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      var bookings = snapshot.data!.docs;

                      /// SEARCH FILTER
                      if (searchText.isNotEmpty) {
                        bookings = bookings.where((b) {
                          String eventName =
                              (b["eventName"] ?? "").toString().toLowerCase();

                          String customerName = (b["customerName"] ?? "")
                              .toString()
                              .toLowerCase();

                          String phone = (b["customerPhone"] ?? "")
                              .toString()
                              .toLowerCase();

                          return eventName.contains(searchText) ||
                              customerName.contains(searchText) ||
                              phone.contains(searchText);
                        }).toList();
                      }

                      if (filter == "pending") {
                        bookings = bookings
                            .where((b) =>
                                b["status"] == "confirmed" ||
                                b["status"] == "dispatching")
                            .toList();
                      }

                      if (filter == "dispatched") {
                        bookings = bookings
                            .where((b) => b["status"] == "dispatched")
                            .toList();
                      }

                      if (filter == "receiving") {
                        bookings = bookings
                            .where((b) => b["status"] == "receiving")
                            .toList();
                      }

                      if (filter == "history") {
                        bookings = bookings
                            .where((b) => b["status"] == "completed")
                            .toList();
                      }

                      if (filter == "all") {
                        bookings = bookings
                            .where((b) =>
                                b["status"] != "completed" &&
                                b["status"] != "receiving")
                            .toList();
                      }
                      if (bookings.isEmpty) {
                        return const Center(
                          child: Text("No bookings found"),
                        );
                      }

                      return ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          var booking = bookings[index];
                          String status = booking["status"] ?? "confirmed";

                          DateTime start =
                              (booking["startDate"] as Timestamp).toDate();

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: Column(
                              children: [
                                ListTile(
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        booking["customerName"],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _statusColor(status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        "Event: ${booking["eventName"]}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Date: ${start.day} ${_monthName(start.month)} ${start.year}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BookingDetailScreen(
                                          businessId: widget.businessId,
                                          bookingId: booking.id,
                                        ),
                                      ),
                                    );
                                  },
                                  onLongPress: () async {
                                    String status =
                                        booking["status"] ?? "confirmed";

                                    if (status == "dispatched" ||
                                        status == "receiving" ||
                                        status == "completed") {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "Dispatched bookings cannot be deleted"),
                                        ),
                                      );

                                      return;
                                    }
                                    bool confirm = await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor: Colors.white,
                                            title: const Text("Delete Booking"),
                                            content: const Text(
                                                "Delete this booking? Inventory will be freed."),
                                            actions: [
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(0xFF1E4FA3),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context, false);
                                                },
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(0xFF1E4FA3),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context, true);
                                                },
                                                child: const Text("Delete"),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                        false;

                                    if (confirm) {
                                      final bookingRef = FirebaseFirestore
                                          .instance
                                          .collection("businesses")
                                          .doc(widget.businessId)
                                          .collection("bookings")
                                          .doc(booking.id);

                                      final items = await bookingRef
                                          .collection("bookedItems")
                                          .get();

                                      for (var doc in items.docs) {
                                        await doc.reference.delete();
                                      }

                                      final services = await bookingRef
                                          .collection("bookingServices")
                                          .get();

                                      for (var doc in services.docs) {
                                        await doc.reference.delete();
                                      }

                                      await bookingRef.delete();
                                    }
                                  },
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Divider(
                                    height: 1,
                                    thickness: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

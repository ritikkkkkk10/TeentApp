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

class _BookingsListScreenState extends State<BookingsListScreen> {
  String filter =
      "all"; // all, pending, dispatched, receiving, history, missing

  TextEditingController searchController = TextEditingController();
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookings"),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateBookingScreen(),
            ),
          );
        },
      ),
      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by customer, event or phone",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
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

          /// FILTER BUTTONS
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filter = "all";
                        });
                      },
                      child: const Text("All"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filter = "pending";
                        });
                      },
                      child: const Text("Pending"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filter = "dispatched";
                        });
                      },
                      child: const Text("Dispatched"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filter = "receiving";
                        });
                      },
                      child: const Text("Receiving"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          filter = "history";
                        });
                      },
                      child: const Text("History"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// BOOKINGS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                    String customerName =
                        (b["customerName"] ?? "").toString().toLowerCase();

                    String phone =
                        (b["customerPhone"] ?? "").toString().toLowerCase();

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

                    DateTime start =
                        (booking["startDate"] as Timestamp).toDate();

                    return ListTile(
                      title: Text(booking["eventName"]),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking["customerName"]),
                          Text(booking["customerPhone"]),
                          Text(
                            "Start: ${start.day}/${start.month}/${start.year}",
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
                        String status = booking["status"] ?? "confirmed";

                        if (status == "dispatched" ||
                            status == "receiving" ||
                            status == "completed") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text("Dispatched bookings cannot be deleted"),
                            ),
                          );

                          return;
                        }
                        bool confirm = await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Delete Booking"),
                                content: const Text(
                                    "Delete this booking? Inventory will be freed."),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
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
                          final bookingRef = FirebaseFirestore.instance
                              .collection("businesses")
                              .doc(widget.businessId)
                              .collection("bookings")
                              .doc(booking.id);

                          final items =
                              await bookingRef.collection("bookedItems").get();

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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

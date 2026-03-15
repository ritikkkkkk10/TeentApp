import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/widgets/bookings_calendar_widget.dart';
import 'booking_detail_screen.dart';

class BookingsCalendarScreen extends StatefulWidget {
  final String businessId;

  const BookingsCalendarScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<BookingsCalendarScreen> createState() => _BookingsCalendarScreenState();
}

class _BookingsCalendarScreenState extends State<BookingsCalendarScreen> {
  Map<DateTime, List<QueryDocumentSnapshot>> events = {};

  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

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

  List<QueryDocumentSnapshot> selectedEvents = [];

  DateTime normalize(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  Future<void> loadBookings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("businesses")
        .doc(widget.businessId)
        .collection("bookings")
        .get();

    Map<DateTime, List<QueryDocumentSnapshot>> map = {};

    for (var doc in snapshot.docs) {
      final start = (doc["startDate"] as Timestamp).toDate();
      final end = (doc["endDate"] as Timestamp).toDate();

      DateTime day = normalize(start);

      while (!day.isAfter(end)) {
        final key = normalize(day);

        if (!map.containsKey(key)) {
          map[key] = [];
        }

        map[key]!.add(doc);

        day = day.add(const Duration(days: 1));
      }
    }

    setState(() {
      events = map;
      selectedEvents = events[normalize(selectedDay)] ?? [];
    });
  }

  List<QueryDocumentSnapshot> getEventsForDay(DateTime day) {
    return events[normalize(day)] ?? [];
  }

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookings Calendar"),
      ),
      body: Column(
        children: [
          /// CALENDAR
      BookingsCalendarWidget(
        businessId: widget.businessId,
        onDaySelected: (day) {
          setState(() {
            selectedDay = day;
            selectedEvents = getEventsForDay(day);
          });
        },
      ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(thickness: 1),
          ),
          Expanded(
            child: selectedEvents.isEmpty
                ? const Center(child: Text("No bookings"))
                : ListView.builder(
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      var booking = selectedEvents[index];

                      DateTime start =
                          (booking["startDate"] as Timestamp).toDate();

                      String status = booking["status"] ?? "confirmed";

                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingDetailScreen(
                                  businessId: widget.businessId,
                                  bookingId: booking.id,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                /// LEFT SIDE
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      /// CUSTOMER NAME
                                      Text(
                                        booking["customerName"],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      /// EVENT
                                      Text(
                                        booking["eventName"],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      /// DATE
                                      Text(
                                        "${start.day}/${start.month}/${start.year}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                /// STATUS BADGE
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        _statusColor(status).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
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
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

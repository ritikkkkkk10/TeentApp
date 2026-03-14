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
          ),

          const SizedBox(height: 10),
          Expanded(
            child: selectedEvents.isEmpty
                ? const Center(child: Text("No bookings"))
                : ListView.builder(
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      var booking = selectedEvents[index];

                      DateTime start =
                          (booking["startDate"] as Timestamp).toDate();

                      return ListTile(
                        title: Text(booking["eventName"]),
                        subtitle: Text(
                          "${booking["customerName"]}\n"
                          "${start.day}/${start.month}/${start.year}",
                        ),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

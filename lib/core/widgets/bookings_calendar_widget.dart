import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingsCalendarWidget extends StatefulWidget {
  final String businessId;
  final bool isMini; // true when used on home screen

  const BookingsCalendarWidget({
    super.key,
    required this.businessId,
    this.isMini = false,
  });

  @override
  State<BookingsCalendarWidget> createState() => _BookingsCalendarWidgetState();
}

class _BookingsCalendarWidgetState extends State<BookingsCalendarWidget> {
  Map<DateTime, List<QueryDocumentSnapshot>> events = {};

  DateTime selectedDay = DateTime.now();
  DateTime focusedDay = DateTime.now();

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
    return IgnorePointer(
      ignoring: widget.isMini,
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2100),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        eventLoader: getEventsForDay,
        onDaySelected: widget.isMini
            ? null
            : (selected, focused) {
                setState(() {
                  selectedDay = selected;
                  focusedDay = focused;
                });
              },
        headerVisible: !widget.isMini,
        calendarStyle: const CalendarStyle(
          markerDecoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

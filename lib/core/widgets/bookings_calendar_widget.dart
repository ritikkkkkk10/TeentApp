import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingsCalendarWidget extends StatefulWidget {
  final String businessId;
  final bool isMini;
  final Function(DateTime)? onDaySelected;

  const BookingsCalendarWidget({
    super.key,
    required this.businessId,
    this.isMini = false,
    this.onDaySelected,
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
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;

            final isSelected = isSameDay(date, selectedDay);

            return Positioned(
              bottom: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((event) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.white : const Color(0xFF1E4FA3),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
        ),
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

                if (widget.onDaySelected != null) {
                  widget.onDaySelected!(selected);
                }
              },
        headerVisible: true,
        calendarStyle: CalendarStyle(
          markersMaxCount: 3,
          markerSize: 5,
          markerDecoration: const BoxDecoration(
            color: Color(0xFF1E4FA3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF1E4FA3),
            shape: BoxShape.circle,
          ),
          todayDecoration: const BoxDecoration(
            color: Color(0xFF1E4FA3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

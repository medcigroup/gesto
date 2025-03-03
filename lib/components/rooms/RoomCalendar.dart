import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../config/room_models.dart';



class RoomCalendar extends StatefulWidget {
  final List<Room> rooms;
  final List<Booking> bookings;

  RoomCalendar({
    required this.rooms,
    required this.bookings,
  });

  @override
  _RoomCalendarState createState() => _RoomCalendarState();
}

class _RoomCalendarState extends State<RoomCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Booking> _getEventsForDay(DateTime day) {
    return widget.bookings
        .where((booking) =>
    booking.checkIn.isBefore(day.add(Duration(days: 1))) &&
        booking.checkOut.isAfter(day))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar<Booking>(
      firstDay: DateTime.utc(2025, 1, 1),
      lastDay: DateTime.utc(2025, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        }
      },
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      eventLoader: _getEventsForDay,
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isNotEmpty) {
            return Positioned(
              right: 1,
              bottom: 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                width: 16.0,
                height: 16.0,
                child: Center(
                  child: Text(
                    '${events.length}',
                    style: TextStyle().copyWith(
                      color: Colors.white,
                      fontSize: 10.0,
                    ),
                  ),
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
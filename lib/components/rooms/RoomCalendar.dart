import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

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
    // Normaliser le jour à minuit pour une comparaison correcte
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(Duration(days: 1));

    return widget.bookings.where((booking) {
      return booking.checkIn.isBefore(dayEnd) && booking.checkOut.isAfter(dayStart);
    }).toList();
  }

  String _getRoomNumber(String roomId) {
    try {
      final room = widget.rooms.firstWhere((r) => r.id == roomId);
      return room.number;
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'enregistré':
        return Colors.green;
      case 'réservée':
        return Colors.orange;
      case 'hourly':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'enregistré':
        return 'Occupée';
      case 'réservée':
        return 'Réservée';
      case 'hourly':
        return 'Passage';
      default:
        return status;
    }
  }

  void _showBookingDetails(DateTime day) {
    final bookings = _getEventsForDay(day);

    if (bookings.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Réservations - ${DateFormat('dd MMMM yyyy', 'fr_FR').format(day)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final roomNumber = _getRoomNumber(booking.roomId);
                  final statusColor = _getStatusColor(booking.status);
                  final statusLabel = _getStatusLabel(booking.status);

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: statusColor, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.hotel, color: statusColor),
                                  SizedBox(width: 8),
                                  Text(
                                    'Chambre $roomNumber',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                booking.guestName,
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                'Du ${DateFormat('dd/MM/yyyy HH:mm').format(booking.checkIn)}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.event_available, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                'Au ${DateFormat('dd/MM/yyyy HH:mm').format(booking.checkOut)}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête moderne avec statistiques
            _buildHeader(),

            SizedBox(height: 16),

            // Calendrier
            Card(
              margin: EdgeInsets.symmetric(horizontal: 16),
              elevation: 8,
              shadowColor: Colors.blue.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TableCalendar<Booking>(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2026, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                locale: 'fr_FR',
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _showBookingDetails(selectedDay);
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
                calendarStyle: CalendarStyle(
                  // Style du jour actuel
                  todayDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade500],
                    ),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  // Style du jour sélectionné
                  selectedDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  selectedTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  // Style des weekends
                  weekendTextStyle: TextStyle(
                    color: Colors.red.shade400,
                  ),
                  // Style général
                  outsideDaysVisible: false,
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                  formatButtonDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: Colors.blue.shade700,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: Colors.blue.shade700,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                  weekendStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade400,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  // Constructeur personnalisé pour les marqueurs
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;

                    // Compter les types de réservations
                    int occupees = 0;
                    int reservees = 0;
                    int passages = 0;

                    for (var event in events) {
                      switch (event.status.toLowerCase()) {
                        case 'enregistré':
                          occupees++;
                          break;
                        case 'réservée':
                          reservees++;
                          break;
                        case 'hourly':
                          passages++;
                          break;
                      }
                    }

                    return Positioned(
                      bottom: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (occupees > 0) _buildMiniMarker(Colors.green, occupees),
                          if (reservees > 0) _buildMiniMarker(Colors.orange, reservees),
                          if (passages > 0) _buildMiniMarker(Colors.blue, passages),
                        ],
                      ),
                    );
                  },
                  // Constructeur pour les jours avec fond coloré selon occupation
                  defaultBuilder: (context, day, focusedDay) {
                    final events = _getEventsForDay(day);
                    if (events.isEmpty) return null;

                    Color? backgroundColor;
                    if (events.length >= 5) {
                      backgroundColor = Colors.red.shade50;
                    } else if (events.length >= 3) {
                      backgroundColor = Colors.orange.shade50;
                    } else if (events.length > 0) {
                      backgroundColor = Colors.green.shade50;
                    }

                    return Container(
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: backgroundColor?.withOpacity(0.5) ?? Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Légende modernisée
          _buildModernLegend(),

          SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMarker(Color color, int count) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Calculer les statistiques
    int totalBookings = widget.bookings.length;
    int occupees = widget.bookings.where((b) => b.status.toLowerCase() == 'enregistré').length;
    int reservees = widget.bookings.where((b) => b.status.toLowerCase() == 'réservée').length;
    int passages = widget.bookings.where((b) => b.status.toLowerCase() == 'hourly').length;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Vue d\'ensemble',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total', totalBookings, Icons.calendar_month, Colors.white),
              _buildStatCard('Occupées', occupees, Icons.hotel, Colors.green.shade300),
              _buildStatCard('Réservées', reservees, Icons.bookmark, Colors.orange.shade300),
              _buildStatCard('Passages', passages, Icons.access_time, Colors.blue.shade300),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildModernLegend() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                SizedBox(width: 8),
                Text(
                  'Légende',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _buildModernLegendItem('Occupée', Colors.green, Icons.hotel),
                _buildModernLegendItem('Réservée', Colors.orange, Icons.bookmark),
                _buildModernLegendItem('Passage', Colors.blue, Icons.access_time),
              ],
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cliquez sur un jour pour voir les détails des réservations',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLegendItem(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
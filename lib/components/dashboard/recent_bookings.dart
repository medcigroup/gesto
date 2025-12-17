import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum BookingPeriodFilter { jour, semaine, mois }
enum ActivityViewType { reservations, passages }

class RecentBooking {
  final String guestName;
  final String roomNumber;
  final String checkIn;
  final String checkOut;
  final String status;
  final Color statusColor;
  final String bookingId;
  final String phoneNumber;
  final DateTime checkInDate;
  final String? actionType; // 'check-in' ou 'check-out'
  final DateTime? actionDate; // Date de l'action pour les passages

  RecentBooking({
    required this.guestName,
    required this.roomNumber,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.statusColor,
    required this.bookingId,
    required this.phoneNumber,
    required this.checkInDate,
    this.actionType,
    this.actionDate,
  });
}

class RecentBookings extends StatefulWidget {
  RecentBookings({Key? key}) : super(key: key);

  @override
  _RecentBookingsState createState() => _RecentBookingsState();
}

class _RecentBookingsState extends State<RecentBookings> {
  List<RecentBooking> bookings = [];
  BookingPeriodFilter _selectedFilter = BookingPeriodFilter.semaine;
  ActivityViewType _viewType = ActivityViewType.reservations;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> _fetchData() async {
    if (_viewType == ActivityViewType.reservations) {
      await _fetchRecentBookings();
    } else {
      await _fetchRecentPassages();
    }
  }

  Future<void> _fetchRecentBookings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedFilter) {
        case BookingPeriodFilter.jour:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case BookingPeriodFilter.semaine:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case BookingPeriodFilter.mois:
          startDate = now.subtract(const Duration(days: 30));
          break;
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: _userId)
          .where('checkInDate', isGreaterThanOrEqualTo: startDate)
          .orderBy('checkInDate', descending: true)
          .limit(10)
          .get();

      List<RecentBooking> fetchedBookings = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final checkInDateTime = (data['checkInDate'] as Timestamp).toDate();
        return RecentBooking(
          guestName: data['customerName'] ?? 'Unknown',
          roomNumber: data['roomNumber'] ?? 'N/A',
          checkIn: DateFormat('dd/MM/yyyy').format(checkInDateTime),
          checkOut: DateFormat('dd/MM/yyyy').format((data['checkOutDate'] as Timestamp).toDate()),
          status: data['status'] ?? 'Unknown',
          statusColor: _getStatusColor(data['status']),
          bookingId: data['EnregistrementCode'] ?? 'N/A',
          phoneNumber: data['customerPhone'] ?? 'N/A',
          checkInDate: checkInDateTime,
        );
      }).toList();

      setState(() {
        bookings = fetchedBookings;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des réservations: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchRecentPassages() async {
    setState(() {
      isLoading = true;
    });

    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedFilter) {
        case BookingPeriodFilter.jour:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case BookingPeriodFilter.semaine:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case BookingPeriodFilter.mois:
          startDate = now.subtract(const Duration(days: 30));
          break;
      }

      // Récupérer les check-ins et check-outs récents
      List<RecentBooking> fetchedPassages = [];

      // Récupérer les enregistrements (check-ins)
      QuerySnapshot checkInsSnapshot = await FirebaseFirestore.instance
          .collection('bookingshours')
          .where('userId', isEqualTo: _userId)
          .where('status', isEqualTo: 'hourly')
          .where('checkInDate', isGreaterThanOrEqualTo: startDate)
          .orderBy('checkInDate', descending: true)
          .limit(5)
          .get();

      for (var doc in checkInsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final checkInDateTime = (data['checkInDate'] as Timestamp).toDate();
        fetchedPassages.add(RecentBooking(
          guestName: data['customerName'] ?? 'Unknown',
          roomNumber: data['roomNumber'] ?? 'N/A',
          checkIn: DateFormat('dd/MM/yyyy HH:mm').format(checkInDateTime),
          checkOut: DateFormat('dd/MM/yyyy').format((data['checkOutDate'] as Timestamp).toDate()),
          status: 'Arrivée',
          statusColor: Colors.green,
          bookingId: data['EnregistrementCode'] ?? 'N/A',
          phoneNumber: data['customerPhone'] ?? 'N/A',
          checkInDate: checkInDateTime,
          actionType: 'check-in',
          actionDate: checkInDateTime,
        ));
      }

      // Récupérer les départs (check-outs)
      QuerySnapshot checkOutsSnapshot = await FirebaseFirestore.instance
          .collection('bookingshours')
          .where('userId', isEqualTo: _userId)
          .where('status', isEqualTo: 'terminé')
          .where('checkOutDate', isGreaterThanOrEqualTo: startDate)
          .orderBy('checkOutDate', descending: true)
          .limit(5)
          .get();

      for (var doc in checkOutsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final checkOutDateTime = (data['checkOutDate'] as Timestamp).toDate();
        final checkInDateTime = (data['checkInDate'] as Timestamp).toDate();
        fetchedPassages.add(RecentBooking(
          guestName: data['customerName'] ?? 'Unknown',
          roomNumber: data['roomNumber'] ?? 'N/A',
          checkIn: DateFormat('dd/MM/yyyy').format(checkInDateTime),
          checkOut: DateFormat('dd/MM/yyyy HH:mm').format(checkOutDateTime),
          status: 'Départ',
          statusColor: Colors.red,
          bookingId: data['EnregistrementCode'] ?? 'N/A',
          phoneNumber: data['customerPhone'] ?? 'N/A',
          checkInDate: checkInDateTime,
          actionType: 'check-out',
          actionDate: checkOutDateTime,
        ));
      }

      // Trier par date d'action (la plus récente en premier)
      fetchedPassages.sort((a, b) =>
        (b.actionDate ?? b.checkInDate).compareTo(a.actionDate ?? a.checkInDate));

      setState(() {
        bookings = fetchedPassages.take(10).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des passages: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'enregistré':
        return Colors.green;
      case 'réservée':
        return Colors.blue;
      case 'terminé':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getPeriodLabel() {
    switch (_selectedFilter) {
      case BookingPeriodFilter.jour:
        return "Aujourd'hui";
      case BookingPeriodFilter.semaine:
        return "7 derniers jours";
      case BookingPeriodFilter.mois:
        return "30 derniers jours";
    }
  }

  String _getViewTypeLabel() {
    switch (_viewType) {
      case ActivityViewType.reservations:
        return "Réservations";
      case ActivityViewType.passages:
        return "Passages";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF263238) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statistiques et filtres
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getViewTypeLabel(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPeriodLabel(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Filtres modernes avec chips
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildFilterChip('J', BookingPeriodFilter.jour, isDark),
                        _buildFilterChip('S', BookingPeriodFilter.semaine, isDark),
                        _buildFilterChip('M', BookingPeriodFilter.mois, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                    onPressed: _fetchData,
                    tooltip: 'Actualiser',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Onglets pour basculer entre Réservations et Passages
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildViewTypeTab(
                    'Réservations',
                    ActivityViewType.reservations,
                    Icons.event_note,
                    isDark,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildViewTypeTab(
                    'Passages',
                    ActivityViewType.passages,
                    Icons.transfer_within_a_station,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Statistique rapide
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3F51B5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3F51B5).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _viewType == ActivityViewType.reservations
                      ? Icons.event_note
                      : Icons.transfer_within_a_station,
                  color: const Color(0xFF3F51B5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _viewType == ActivityViewType.reservations
                      ? '${bookings.length} réservation(s)'
                      : '${bookings.length} passage(s)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F51B5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Liste des réservations
          isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : bookings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune réservation',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bookings.length,
                      separatorBuilder: (context, index) => Divider(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        height: 24,
                      ),
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return _buildBookingCard(booking, isDark);
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(RecentBooking booking, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Badge chambre
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3F51B5),
                  const Color(0xFF5C6BC0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.meeting_room, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  booking.roomNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.guestName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: booking.statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.status,
                        style: TextStyle(
                          color: booking.statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${booking.checkIn} - ${booking.checkOut}",
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.phoneNumber,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, BookingPeriodFilter filter, bool isDark) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
          _fetchData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3F51B5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildViewTypeTab(String label, ActivityViewType viewType, IconData icon, bool isDark) {
    final isSelected = _viewType == viewType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewType = viewType;
          _fetchData();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF3F51B5) : const Color(0xFF3F51B5))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

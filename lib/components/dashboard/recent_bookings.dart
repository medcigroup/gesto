import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RecentBooking {
  final String guestName;
  final String roomNumber;
  final String checkIn;
  final String checkOut;
  final String status;
  final Color statusColor;
  final String bookingId;
  final String phoneNumber;

  RecentBooking({
    required this.guestName,
    required this.roomNumber,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.statusColor,
    required this.bookingId,
    required this.phoneNumber,
  });
}

class RecentBookings extends StatefulWidget {
  RecentBookings({Key? key}) : super(key: key);

  @override
  _RecentBookingsState createState() => _RecentBookingsState();
}

class _RecentBookingsState extends State<RecentBookings> {
  List<RecentBooking> bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchRecentBookings();
  }
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  Future<void> _fetchRecentBookings() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: _userId)

          .limit(4)
          .get();

      List<RecentBooking> fetchedBookings = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return RecentBooking(
          guestName: data['customerName'] ?? 'Unknown',
          roomNumber: data['roomNumber'] ?? 'N/A',
          checkIn: DateFormat('yyyy-MM-dd').format((data['checkInDate'] as Timestamp).toDate()),
          checkOut: DateFormat('yyyy-MM-dd').format((data['checkOutDate'] as Timestamp).toDate()),
          status: data['status'] ?? 'Unknown',
          statusColor: _getStatusColor(data['status']),
          bookingId: data['EnregistrementCode'] ?? 'N/A',
          phoneNumber: data['customerPhone'] ?? 'N/A',
        );
      }).toList();

      setState(() {
        bookings = fetchedBookings;
      });
    } catch (e) {
      print('Erreur lors du chargement des réservations: $e');
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Arrivés / Départs récents",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[800],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchRecentBookings,
                  ),
                  IconButton(
                    icon: const Icon(Icons.list),
                    onPressed: () {
                      // Action pour voir tous les arrivées/départs
                      print("Voir tous les arrivées/départs");
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "CHAMBRE ${booking.roomNumber}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.guestName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Booking ID: ${booking.bookingId}",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Phone: ${booking.phoneNumber}",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "${booking.checkIn} - ${booking.checkOut}",
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: booking.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        booking.status,
                        style: TextStyle(
                          color: booking.statusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

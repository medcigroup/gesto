import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gesto/config/room_models.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> bookRoom(Booking booking) async {
    await _firestore.collection('bookings').doc(booking.id).set(booking.toFirestore());
  }
}
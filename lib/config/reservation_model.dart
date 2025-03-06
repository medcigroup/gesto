class Reservation {
  final String id;
  final String customerName;
  final String roomNumber;
  final String? roomType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  String? status;
  final String roomId;
  final String reservationCode; // Assurez-vous qu'il n'y a pas 'late' ici
  final String? customerEmail;
  final String? customerPhone;
  final int? numberOfGuests;
  final String? specialRequests;

  Reservation({
    required this.id,
    required this.customerName,
    required this.roomNumber,
    this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    this.status,
    required this.roomId,
    required this.reservationCode,
    this.customerEmail,
    this.customerPhone,
    this.numberOfGuests,
    this.specialRequests,
  });
}
// room_models.dart

class Room {
  final String id;
  final String number;
  final String type;
  final String status;
  final double price;
  final int capacity;
  final List<String> amenities;
  final int floor;
  final String image;

  Room({
    required this.id,
    required this.number,
    required this.type,
    required this.status,
    required this.price,
    required this.capacity,
    required this.amenities,
    required this.floor,
    required this.image,
  });
}

class Booking {
  final String id;
  final String roomId;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final String status;

  Booking({
    required this.id,
    required this.roomId,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });
}
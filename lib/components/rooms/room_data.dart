// room_data.dart

import '../../config/room_models.dart';

List<Room> roomsData = [
  Room(
    id: '1',
    number: '101',
    type: 'simple', // 'single' traduit en 'simple'
    status: 'disponible', // 'available' traduit en 'disponible'
    price: 99,
    capacity: 1,
    amenities: [
      'WiFi',
      'TV',
      'Climatisation', // 'Air Conditioning' traduit en 'Climatisation'
      'Mini Bar',
    ],
    floor: 1,
    image:
    'https://images.unsplash.com/photo-1566665797739-1674de7a421a?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80', userId: '',
  ),
  Room(
    id: '2',
    number: '102',
    type: 'double',
    status: 'occupée', // 'occupied' traduit en 'occupée'
    price: 149,
    capacity: 2,
    amenities: [
      'WiFi',
      'TV',
      'Climatisation',
      'Mini Bar',
      'Machine à café', // 'Coffee Maker' traduit en 'Machine à café'
    ],
    floor: 1,
    image:
    'https://images.unsplash.com/photo-1590490360182-c33d57733427?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80', userId: '',
  ),
  Room(
    id: '3',
    number: '201',
    type: 'suite',
    status: 'réservée', // 'reserved' traduit en 'réservée'
    price: 299,
    capacity: 4,
    amenities: [
      'WiFi',
      'TV',
      'Climatisation',
      'Mini Bar',
      'Machine à café',
      'Baignoire', // 'Bathtub' traduit en 'Baignoire'
      'Balcon', // 'Balcony' traduit en 'Balcon'
    ],
    floor: 2,
    image:
    'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80', userId: '',
  ),
  Room(
    id: '4',
    number: '202',
    type: 'deluxe',
    status: 'maintenance',
    price: 249,
    capacity: 2,
    amenities: [
      'WiFi',
      'TV',
      'Climatisation',
      'Mini Bar',
      'Machine à café',
      'Baignoire',
    ],
    floor: 2,
    image:
    'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80', userId: '',
  ),
  Room(
    id: '5',
    number: '301',
    type: 'double',
    status: 'Disponible', // 'free' traduit en 'libre'
    price: 159,
    capacity: 2,
    amenities: [
      'WiFi',
      'TV',
      'Climatisation',
      'Mini Bar',
    ],
    floor: 3,
    image:
    'https://images.unsplash.com/photo-1566195992011-5f6b21e539aa?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80', userId: '',
  ),
  Room(
    id: '6',
    number: '302',
    type: 'simple',
    status: 'Disponible',
    price: 109,
    capacity: 1,
    amenities: [
      'WiFi',
      'TV',
      'Climatisation',
    ],
    floor: 3,
    image:
    'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80', userId: '',
  ),
  Room(
    id: '7',
    number: '401',
    type: 'suite',
    status: 'occupé',
    price: 329,
    capacity: 3,
    amenities: [
      'WiFi',
      'TV',
      'Climatisation',
      'Mini Bar',
      'Machine à café',
      'Baignoire',
      'Balcon',
    ],
    floor: 4,
    image:
    'https://images.unsplash.com/photo-1551776235-dde6d482980b?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80', userId: '',
  ),
  Room(
    id: '8',
    number: '402',
    type: 'deluxe',
    status: 'Libre',
    price: 269,
    capacity: 2,
    amenities: [
      'WiFi',
      'TV',
      'Climatisation',
      'Mini Bar',
      'Machine à café',
      'Baignoire',
    ],
    floor: 4,
    image:
    'https://images.unsplash.com/photo-1618773928121-c32242e63f39?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80', userId: '',
  ),
];

List<Booking> bookingsData = [
  Booking(
    id: '1',
    roomId: '1',
    guestName: 'Jean Dupont', // 'John Smith' traduit en 'Jean Dupont'
    checkIn: DateTime(2025, 5, 15),
    checkOut: DateTime(2025, 5, 18),
    status: 'confirmée', // 'confirmed' traduit en 'confirmée'
  ),
  Booking(
    id: '2',
    roomId: '3',
    guestName: 'Sophie Dubois', // 'Sarah Johnson' traduit en 'Sophie Dubois'
    checkIn: DateTime(2025, 5, 16),
    checkOut: DateTime(2025, 5, 20),
    status: 'confirmée',
  ),
  Booking(
    id: '3',
    roomId: '7',
    guestName: 'Michel Durand', // 'Michael Brown' traduit en 'Michel Durand'
    checkIn: DateTime(2025, 5, 14),
    checkOut: DateTime(2025, 5, 19),
    status: 'confirmée',
  ),
  Booking(
    id: '4',
    roomId: '2',
    guestName: 'Émilie Martin', // 'Emily Davis' traduit en 'Émilie Martin'
    checkIn: DateTime(2025, 5, 22),
    checkOut: DateTime(2025, 5, 25),
    status: 'confirmée',
  ),
  Booking(
    id: '5',
    roomId: '5',
    guestName: 'David Lefebvre', // 'David Wilson' traduit en 'David Lefebvre'
    checkIn: DateTime(2025, 5, 20),
    checkOut: DateTime(2025, 5, 23),
    status: 'confirmée',
  ),
  Booking(
    id: '6',
    roomId: '8',
    guestName: 'Jessica Dubois', // 'Jessica Taylor' traduit en 'Jessica Dubois'
    checkIn: DateTime(2025, 5, 25),
    checkOut: DateTime(2025, 5, 28),
    status: 'confirmée',
  ),
];
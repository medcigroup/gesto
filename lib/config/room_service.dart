import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_models.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Room>> getAvailableRooms(DateTime date) async {
    // Convertir la date en Timestamp
    Timestamp timestamp = Timestamp.fromDate(date);

    print('Recherche des chambres disponibles pour la date: $date');

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('rooms')
          .where('status', isEqualTo: 'disponible')
          .where('datedisponible', isEqualTo: timestamp) // Comparer les Timestamps
          .get();

      print('Nombre de chambres trouvées: ${snapshot.docs.length}');

      return snapshot.docs.map((doc) {
        print('Chambre trouvée: ${doc.data()}');
        return Room.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des chambres: $e');
      return [];
    }
  }
}
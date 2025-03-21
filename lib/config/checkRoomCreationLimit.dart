import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, dynamic>> checkRoomCreationLimit(String userId) async {
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      throw Exception("Utilisateur non trouvé");
    }

    String licenceType = (userDoc.data()?['licenceType'] ?? 'basic').toLowerCase();
    int maxRooms = getRoomLimit(licenceType);

    final roomsSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .where('userId', isEqualTo: userId)
        .get();

    int roomCount = roomsSnapshot.docs.length;
    bool canCreate = maxRooms == -1 || roomCount < maxRooms;

    return {
      "canCreate": canCreate,
      "limit": maxRooms,
      "roomCount": roomCount,
      "licenceType": licenceType
    };
  } catch (e) {
    print('Erreur lors de la vérification de la limite: $e');
    return {
      "canCreate": false,
      "error": e.toString()
    };
  }
}


// Fonction utilitaire pour obtenir la limite maximale de chambres selon le type de licence
int getRoomLimit(String licenceType) {
  switch (licenceType) {
    case 'basic':
      return 14;
    case 'starter':
      return 20;
    case 'pro':
    case 'entreprise':
      return -1; // -1 signifie illimité
    default:
      return 14;
  }
}

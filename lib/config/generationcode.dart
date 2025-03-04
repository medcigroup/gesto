import 'package:cloud_firestore/cloud_firestore.dart';

class CodeGenerator {
  // Méthode privée générique pour générer des codes
  static Future<String> _generateCode(String counterName, String prefix) async {
    final counterRef = FirebaseFirestore.instance.collection('counters').doc('${counterName}Counter');

    return FirebaseFirestore.instance.runTransaction<String>((transaction) async {
      // Récupérer le snapshot du compteur
      final counterSnapshot = await transaction.get(counterRef);

      // Gérer le compteur de manière sécurisée
      int currentCounter = 0;
      if (counterSnapshot.exists) {
        currentCounter = (counterSnapshot.data()?['lastNumber'] as int?) ?? 0;
      }

      // Incrémenter le compteur
      currentCounter++;

      // Mettre à jour le compteur dans la transaction
      transaction.set(counterRef, {
        'lastNumber': currentCounter,
        'lastUpdated': FieldValue.serverTimestamp()
      }, SetOptions(merge: true));

      // Formater le code avec le préfixe et un numéro de séquence
      return '$prefix${currentCounter.toString().padLeft(6, '0')}';
    });
  }

  // Méthode pour générer un code de réservation
  static Future<String> generateReservationCode() async {
    return _generateCode('reservation', 'RES');
  }

  // Méthode pour générer un code d'enregistrement
  static Future<String> generateRegistrationCode() async {
    return _generateCode('registration', 'ENG');
  }

  // Méthode statique pour générer des codes aléatoires sécurisés (optionnel)
  static String generateRandomCode({int length = 8}) {
    final random = DateTime.now().millisecondsSinceEpoch;
    return random.toString().padLeft(length, '0').substring(0, length);
  }
}
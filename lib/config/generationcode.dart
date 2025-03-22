import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class CodeGenerator {
  // Méthode privée générique pour générer des codes séquentiels
  static Future<String> _generateCode(String counterName, String prefix) async {
    final counterRef = FirebaseFirestore.instance.collection('counters').doc('${counterName}Counter');

    return FirebaseFirestore.instance.runTransaction<String>((transaction) async {
      try {
        final counterSnapshot = await transaction.get(counterRef);
        int currentCounter = counterSnapshot.exists ? (counterSnapshot.data()?['lastNumber'] ?? 0) as int : 0;

        currentCounter++;
        transaction.set(counterRef, {
          'lastNumber': currentCounter,
          'lastUpdated': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));

        return '$prefix${currentCounter.toString().padLeft(6, '0')}';
      } catch (e) {
        print('Erreur Firestore lors de la génération du code ($counterName) : $e');
        return '$prefix${Random().nextInt(999999).toString().padLeft(6, '0')}'; // Fallback aléatoire
      }
    });
  }

  // Générer un code de réservation
  static Future<String> generateReservationCode() async {
    return _generateCode('reservation', 'RES');
  }

  // Générer un code d'enregistrement
  static Future<String> generateRegistrationCode() async {
    return _generateCode('registration', 'ENG');
  }

  // Générer un code de transaction (méthode séparée)
  static Future<String> generateTransactionCode() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final DocumentReference counterRef = firestore.collection('counters').doc('transactionCounter');

    return await firestore.runTransaction((transaction) async {
      try {
        final snapshot = await transaction.get(counterRef);

        // ✅ Cast explicite pour éviter l'erreur
        final data = snapshot.data() as Map<String, dynamic>?;

        int lastNumber = data != null ? (data['lastNumber'] ?? 0) as int : 0;
        lastNumber++;

        transaction.set(counterRef, {
          'lastNumber': lastNumber,
          'lastUpdated': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));

        return 'T${lastNumber.toString().padLeft(6, '0')}';
      } catch (e) {
        print('Erreur Firestore lors de la génération du code transaction : $e');
        return 'T${Random().nextInt(999999).toString().padLeft(6, '0')}'; // Fallback aléatoire
      }
    });
  }


  // Générer un code aléatoire sécurisé
  static String generateRandomCode({int length = 8}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
}





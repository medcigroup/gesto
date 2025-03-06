import 'package:cloud_firestore/cloud_firestore.dart';

class CodeEntrepriseGenerator {
  static const _prefix = 'CGH';
  static final _codesCollection = FirebaseFirestore.instance.collection('entreprises');

  static Future<Map<String, dynamic>> generateUniqueCode(
      String entrepriseName, String email, String phoneNumber) async {
    int nextNumber = await _getNextNumber();
    String code = '';
    bool isUnique = false;

    while (!isUnique) {
      code = '$_prefix${nextNumber.toString().padLeft(5, '0')}';
      final querySnapshot = await _codesCollection.where('code', isEqualTo: code).get();

      if (querySnapshot.docs.isEmpty) {
        isUnique = true;
      } else {
        nextNumber++;
      }
    }

    // Calculer la date de création
    final creationDate = DateTime.now();

    // Stocker le code et les informations dans la base de données
    await _codesCollection.add({
      'code': code,
      'entrepriseName': entrepriseName,
      'email': email,
      'phoneNumber': phoneNumber,
      'creationDate': creationDate,
    });

    return {
      'code': code,
      'entrepriseName': entrepriseName,
      'email': email,
      'phoneNumber': phoneNumber,
      'creationDate': creationDate,
    };
  }

  static Future<int> _getNextNumber() async {
    final querySnapshot = await _codesCollection.orderBy('code', descending: true).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      final lastCode = querySnapshot.docs.first.get('code') as String;
      final lastNumber = int.parse(lastCode.substring(_prefix.length));
      return lastNumber + 1;
    } else {
      return 1; // Premier code
    }
  }
}
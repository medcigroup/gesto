import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class LicenceGenerator {
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final Random _rnd = Random();

  static String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  static Future<Map<String, dynamic>> generateUniqueLicence(int durationDays, String licenceType, String periodeType) async {
    String licence = '';
    bool isUnique = false;
    final licencesCollection = FirebaseFirestore.instance.collection('licences');

    while (!isUnique) {
      licence = getRandomString(16);
      final querySnapshot =
      await licencesCollection.where('code', isEqualTo: licence).get();
      if (querySnapshot.docs.isEmpty) {
        isUnique = true;
      }
    }

    // Calculer les dates
    final generationDate = DateTime.now();
    final expiryDate = generationDate.add(Duration(days: durationDays));

    // Stocker la licence et les dates dans la base de données
    await licencesCollection.add({
      'code': licence,
      'generationDate': generationDate,
      'expiryDate': expiryDate,
      'licenceType': licenceType, // Stocker le type de licence
      'periodeType': periodeType, // Stocker le type de période
    });

    return {
      'code': licence,
      'generationDate': generationDate,
      'expiryDate': expiryDate,
      'licenceType': licenceType,
      'periodeType': periodeType,
    };
  }
}
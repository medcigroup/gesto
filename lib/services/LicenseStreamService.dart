import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../LicenseFeatures.dart';

// Classe pour représenter l'état complet de la licence
class LicenseStatus {
  final bool isValid;
  final LicenseType? licenseType;
  final DateTime? expiryDate;
  final bool isExpired;
  final String? message;

  LicenseStatus({
    required this.isValid,
    this.licenseType,
    this.expiryDate,
    this.isExpired = false,
    this.message,
  });

  // Vérifier si une page est accessible
  bool canAccessPage(String pageTitle) {
    // ⚠️ Si la licence a expiré, seules les pages Licences et Paramètres sont accessibles
    // Le Dashboard n'est PAS accessible si la licence est expirée
    if (!isValid || isExpired) {
      return ['Licences', 'Paramètres'].contains(pageTitle);
    }

    if (licenseType == null) return false;

    return LicenseFeatures.isPageAccessible(pageTitle, licenseType!);
  }

  // Vérifier si une fonctionnalité est premium
  bool isFeaturePremium(String featureName) {
    if (licenseType == null) return true;
    return LicenseFeatures.isPremiumFeature(featureName, licenseType!);
  }

  @override
  String toString() {
    return 'LicenseStatus(isValid: $isValid, type: $licenseType, expired: $isExpired)';
  }
}

class LicenseStreamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription? _licenseSubscription;
  StreamSubscription? _ownerLicenseSubscription;

  // Stream pour vérifier la licence d'un administrateur/propriétaire
  Stream<LicenseStatus> listenToOwnerLicense(String userId) {
    print('[LICENSE] 🔍 Début de l\'écoute de licence pour propriétaire: $userId');

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      print('[LICENSE] 📡 Changement détecté pour propriétaire: $userId');

      if (!snapshot.exists) {
        print('[LICENSE] ❌ Document utilisateur n\'existe pas');
        return LicenseStatus(
          isValid: false,
          message: 'Utilisateur introuvable',
        );
      }

      final data = snapshot.data();
      print('[LICENSE] 📄 Données reçues: $data');

      // Vérifier si l'utilisateur a une licence
      if (data == null || data['licence'] == null) {
        print('[LICENSE] ❌ Pas de licence trouvée');
        return LicenseStatus(
          isValid: false,
          message: 'Aucune licence active',
        );
      }

      // Récupérer le type de licence
      String licenseTypeStr = data['licenceType'] ?? data['licence'] ?? 'basic';
      LicenseType licenseType = licenseTypeStr.toLicenseType();
      print('[LICENSE] 📋 Type de licence: $licenseType');

      // Vérifier l'expiration
      DateTime? expiryDate;
      bool isExpired = false;

      if (data['licenceExpiry'] != null || data['licenceExpiryDate'] != null) {
        Timestamp? expiryTimestamp = data['licenceExpiry'] ?? data['licenceExpiryDate'];
        expiryDate = expiryTimestamp?.toDate();

        if (expiryDate != null) {
          isExpired = expiryDate.isBefore(DateTime.now());
          print('[LICENSE] 📅 Expiration: $expiryDate, Expiré: $isExpired');

          if (isExpired) {
            print('[LICENSE] ⏰ Licence expirée !');
            return LicenseStatus(
              isValid: false,
              licenseType: licenseType,
              expiryDate: expiryDate,
              isExpired: true,
              message: 'Votre licence a expiré le ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
            );
          }
        }
      }

      print('[LICENSE] ✅ Licence valide');
      return LicenseStatus(
        isValid: true,
        licenseType: licenseType,
        expiryDate: expiryDate,
        isExpired: false,
      );
    });
  }

  // Stream pour vérifier la licence du propriétaire d'un employé
  // ⚠️ CORRIGÉ : Utilise maintenant snapshots() pour une écoute en temps réel
  Stream<LicenseStatus> listenToEmployeeOwnerLicense(String employeeId) {
    print('[LICENSE] 🔍 Début de l\'écoute pour employé: $employeeId');

    // Écouter les changements du document staff en temps réel
    return _firestore
        .collection('staff')
        .doc(employeeId)
        .snapshots()
        .asyncExpand((staffSnapshot) async* {

      if (!staffSnapshot.exists || staffSnapshot.data() == null) {
        print('[LICENSE] ❌ Document employé n\'existe pas');
        yield LicenseStatus(
          isValid: false,
          message: 'Employé introuvable',
        );
        return;
      }

      final staffData = staffSnapshot.data() as Map<String, dynamic>;

      if (staffData['idadmin'] == null) {
        print('[LICENSE] ❌ Pas d\'administrateur lié');
        yield LicenseStatus(
          isValid: false,
          message: 'Aucun administrateur lié',
        );
        return;
      }

      String ownerId = staffData['idadmin'];
      print('[LICENSE] 👤 Administrateur trouvé: $ownerId');

      // Maintenant écouter les changements de licence du propriétaire
      yield* _firestore
          .collection('users')
          .doc(ownerId)
          .snapshots()
          .map((snapshot) {
        print('[LICENSE] 📡 Changement détecté pour admin: $ownerId');

        if (!snapshot.exists) {
          print('[LICENSE] ❌ Document administrateur n\'existe pas');
          return LicenseStatus(
            isValid: false,
            message: 'Administrateur introuvable',
          );
        }

        final data = snapshot.data();

        if (data == null || data['licence'] == null) {
          print('[LICENSE] ❌ Administrateur sans licence');
          return LicenseStatus(
            isValid: false,
            message: 'Votre administrateur n\'a pas de licence active',
          );
        }

        // Récupérer le type de licence de l'admin
        String licenseTypeStr = data['licenceType'] ?? data['licence'] ?? 'basic';
        LicenseType licenseType = licenseTypeStr.toLicenseType();
        print('[LICENSE] 📋 Type de licence admin: $licenseType');

        // Vérifier l'expiration
        DateTime? expiryDate;
        bool isExpired = false;

        if (data['licenceExpiry'] != null || data['licenceExpiryDate'] != null) {
          Timestamp? expiryTimestamp = data['licenceExpiry'] ?? data['licenceExpiryDate'];
          expiryDate = expiryTimestamp?.toDate();

          if (expiryDate != null) {
            isExpired = expiryDate.isBefore(DateTime.now());
            print('[LICENSE] 📅 Expiration admin: $expiryDate, Expiré: $isExpired');

            if (isExpired) {
              print('[LICENSE] ⏰ Licence admin expirée !');
              return LicenseStatus(
                isValid: false,
                licenseType: licenseType,
                expiryDate: expiryDate,
                isExpired: true,
                message: 'La licence de votre administrateur a expiré',
              );
            }
          }
        }

        print('[LICENSE] ✅ Licence admin valide');
        return LicenseStatus(
          isValid: true,
          licenseType: licenseType,
          expiryDate: expiryDate,
          isExpired: false,
        );
      });
    });
  }

  // Vérifier si l'utilisateur est un employé
  Future<bool> isEmployee(String userId) async {
    try {
      final staffDoc = await _firestore.collection('staff').doc(userId).get();
      bool isEmp = staffDoc.exists;
      print('[LICENSE] 👥 Utilisateur $userId est employé: $isEmp');
      return isEmp;
    } catch (e) {
      print('[LICENSE] ❌ Erreur lors de la vérification du statut d\'employé: $e');
      return false;
    }
  }

  // Obtenir le stream approprié selon le type d'utilisateur
  Future<Stream<LicenseStatus>> getLicenseStream(String userId) async {
    bool isEmployeeUser = await isEmployee(userId);

    if (isEmployeeUser) {
      print('[LICENSE] 🔄 Stream pour employé');
      return listenToEmployeeOwnerLicense(userId);
    } else {
      print('[LICENSE] 🔄 Stream pour propriétaire');
      return listenToOwnerLicense(userId);
    }
  }

  // Nettoyer les subscriptions
  void dispose() {
    print('[LICENSE] 🧹 Nettoyage des subscriptions');
    _licenseSubscription?.cancel();
    _ownerLicenseSubscription?.cancel();
  }
}
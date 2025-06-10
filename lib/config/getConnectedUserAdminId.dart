import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Récupère l'idadmin de l'utilisateur connecté
///
/// Cette fonction vérifie d'abord si un utilisateur est connecté,
/// puis détermine son rôle (manager ou employé) en vérifiant les collections.
/// - Si c'est un manager (dans la collection 'users'), on utilise son propre userId
/// - Si c'est un employé (dans la collection 'staff'), on récupère son idadmin
///
/// Retourne null si aucun utilisateur n'est connecté ou si le document
/// correspondant n'existe pas dans les collections appropriées.
Future<String?> getConnectedUserAdminId() async {
  try {
    // Récupérer l'utilisateur actuellement connecté
    User? currentUser = FirebaseAuth.instance.currentUser;

    // Vérifier si un utilisateur est connecté
    if (currentUser == null) {
      print("Aucun utilisateur connecté");
      return null;
    }

    // Récupérer l'uid de l'utilisateur connecté
    String uid = currentUser.uid;

    // Vérifier d'abord si l'utilisateur est un manager (dans la collection 'users')
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    // Si le document existe dans la collection 'users', c'est un manager
    if (userDoc.exists) {
      print("Utilisateur connecté est un manager");
      // Pour un manager, son propre userId est retourné comme adminId
      return uid;
    }
    // Sinon, vérifier si c'est un employé (dans la collection 'staff')
    else {
      // Créer une référence à la collection 'staff'
      CollectionReference staffCollection = FirebaseFirestore.instance.collection('staff');

      // Exécuter la requête pour obtenir le document correspondant à l'uid
      DocumentSnapshot staffDoc = await staffCollection.doc(uid).get();

      // Vérifier si le document existe
      if (!staffDoc.exists) {
        print("L'utilisateur n'existe pas dans les collections users ou staff");
        return null;
      }

      // Convertir le DocumentSnapshot en Map
      Map<String, dynamic> staffData = staffDoc.data() as Map<String, dynamic>;

      // Récupérer et retourner l'idadmin pour l'employé
      if (staffData.containsKey('idadmin')) {
        return staffData['idadmin'];
      } else {
        print("Le champ 'idadmin' n'existe pas pour cet utilisateur dans staff");
        return null;
      }
    }
  } catch (e) {
    print("Erreur lors de la récupération de l'idadmin: $e");
    return null;
  }
}
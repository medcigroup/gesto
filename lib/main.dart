import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_file.dart';
import '../../../config/routes.dart';
import 'FirebaseOptions.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'LicenseFeatures.dart';
import 'components/messagerie/NotificationProvider.dart';
import 'config/AuthService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: FirebaseConfig.options);
    print("Firebase est bien connecté !");
  } catch (e) {
    print("Erreur de connexion à Firebase : $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => LicenseManager()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Hotel Management App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: AuthChecker(), // Vérifie l'état d'authentification au démarrage
        onGenerateRoute: AppRoutes.onGenerateRoute, // Utilisation de la méthode onGenerateRoute
      ),
    );
  }
}

class AuthChecker extends StatefulWidget {
  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        Future.microtask(() async {
          if (user != null) {
            // Vérifier d'abord si l'utilisateur est un employé
            bool isEmployee = await checkIfEmployee(user.uid);

            if (isEmployee) {
              // Si c'est un employé, vérifier la licence du propriétaire
              bool hasOwnerValidLicense = await checkEmployeeOwnerLicense(user.uid);

              if (hasOwnerValidLicense) {
                // Rediriger vers le dashboard employé si le propriétaire a une licence valide
                Navigator.pushReplacementNamed(context, AppRoutes.employeeDashboard);
              } else {
                // Licence du propriétaire non valide
                await FirebaseAuth.instance.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("L'accès est désactivé. Veuillez contacter votre administrateur."))
                );
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            } else {
              // Si c'est un administrateur/propriétaire, vérifier sa propre licence
              bool hasLicence = await checkUserLicence(user.uid);

              if (hasLicence) {
                // Initialiser le provider de notifications avant d'aller au dashboard
                Provider.of<NotificationProvider>(context, listen: false).initialiser();
                // Redirige vers le dashboard si connecté avec licence
                Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              } else {
                // Redirige vers la page de choix de licence si pas de licence
                Navigator.pushReplacementNamed(context, AppRoutes.choosePlan);
              }
            }
          } else {
            // Redirige vers la page d'accueil si non connecté
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        });
      }
    });
  }

  // Fonction pour vérifier si l'utilisateur est un employé
  Future<bool> checkIfEmployee(String userId) async {
    try {
      // Vérifier si l'utilisateur existe dans la collection 'staff'
      final staffDoc = await FirebaseFirestore.instance.collection('staff').doc(userId).get();
      return staffDoc.exists;
    } catch (e) {
      print('Erreur lors de la vérification du statut d\'employé: $e');
      return false;
    }
  }

  // Fonction pour vérifier la licence du propriétaire d'un employé
  Future<bool> checkEmployeeOwnerLicense(String employeeId) async {
    try {
      // Récupérer les données de l'employé depuis Firestore
      final staffDoc = await FirebaseFirestore.instance.collection('staff').doc(employeeId).get();

      if (!staffDoc.exists) {
        return false;
      }

      final staffData = staffDoc.data();

      // Récupérer l'ID du propriétaire/administrateur
      if (staffData == null || staffData['idadmin'] == null) {
        return false;
      }

      String ownerId = staffData['idadmin'];

      // Vérifier la licence du propriétaire
      final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();

      if (!ownerDoc.exists) {
        return false;
      }

      final ownerData = ownerDoc.data();

      // Vérifier si le propriétaire a une licence valide
      if (ownerData == null || ownerData['licence'] == null) {
        return false;
      }

      // Vérifier si la licence est expirée (si vous avez une date d'expiration)
      if (ownerData['licenceExpiry'] != null) {
        DateTime expiryDate = (ownerData['licenceExpiry'] as Timestamp).toDate();
        if (expiryDate.isBefore(DateTime.now())) {
          return false;
        }
      }

      // Propriétaire a une licence valide
      return true;
    } catch (e) {
      print('Erreur lors de la vérification de la licence du propriétaire: $e');
      return false;
    }
  }

  // Fonction pour vérifier si l'utilisateur a une licence
  Future<bool> checkUserLicence(String userId) async {
    try {
      // Récupérer les données de l'utilisateur depuis Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data();

      // Vérifier si l'utilisateur a une licence
      if (userData == null || userData['licence'] == null) {
        return false;
      }

      // Vérifier si la licence est expirée (si vous avez une date d'expiration)
      if (userData['licenceExpiry'] != null) {
        DateTime expiryDate = (userData['licenceExpiry'] as Timestamp).toDate();
        if (expiryDate.isBefore(DateTime.now())) {
          return false;
        }
      }

      // L'utilisateur a une licence valide
      return true;
    } catch (e) {
      print('Erreur lors de la vérification de la licence: $e');
      // En cas d'erreur, on suppose que l'utilisateur n'a pas de licence
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()), // Loader pendant la vérification
    );
  }
}
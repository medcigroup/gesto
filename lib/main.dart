import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_file.dart';
import '../../../config/routes.dart';
import 'FirebaseOptions.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hotel Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthChecker(), // Vérifie l'état d'authentification au démarrage
      onGenerateRoute: AppRoutes.onGenerateRoute, // Utilisation de la méthode onGenerateRoute
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
            // Utilisateur connecté, vérifier s'il a une licence
            bool hasLicence = await checkUserLicence(user.uid);

            if (hasLicence) {
              // Redirige vers le dashboard si connecté avec licence
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
            } else {
              // Redirige vers la page de choix de licence si pas de licence
              Navigator.pushReplacementNamed(context, AppRoutes.choosePlan);
            }
          } else {
            // Redirige vers la page d'accueil si non connecté
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        });
      }
    });
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

      // L'utilisateur a une licence
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




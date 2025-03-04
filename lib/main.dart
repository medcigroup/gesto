import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config/routes.dart';
import 'FirebaseOptions.dart';

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
        Future.microtask(() {
          if (user != null) {
            // Redirige vers le dashboard si connecté
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          } else {
            // Redirige vers la page d'accueil si non connecté
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()), // Loader pendant la vérification
    );
  }
}




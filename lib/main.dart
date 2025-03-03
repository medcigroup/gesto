import 'package:flutter/material.dart';
import '../../../config/routes.dart';
import 'package:firebase_core/firebase_core.dart';

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
      title: 'Hotel Management App',
      initialRoute: AppRoutes.dashboard, // Assure-toi que la route initiale existe
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
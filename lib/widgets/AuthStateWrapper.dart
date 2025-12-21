import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Wrapper qui gère la redirection automatique des utilisateurs connectés
/// Si l'utilisateur est déjà authentifié (session persistante), 
/// il est automatiquement redirigé vers son dashboard approprié
class AuthStateWrapper extends StatelessWidget {
  final Widget child;

  const AuthStateWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Vérifier une seule fois si l'utilisateur est déjà connecté
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Si l'utilisateur est déjà connecté, afficher un loader
    // Le AuthChecker de main.dart va gérer la redirection
    if (currentUser != null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Connexion en cours...'),
            ],
          ),
        ),
      );
    }

    // Utilisateur non connecté - afficher la page demandée
    return child;
  }
}


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/routes.dart';

/// Service de gestion de la déconnexion utilisateur
class LogoutService {
  /// Déconnecte l'utilisateur et le redirige vers la page d'accueil
  static Future<void> logout(BuildContext context, {bool showConfirmation = true}) async {
    if (showConfirmation) {
      // Afficher une confirmation avant de déconnecter
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Voulez-vous vraiment vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Déconnexion'),
              ),
            ],
          );
        },
      );

      if (shouldLogout != true) return;
    }

    try {
      // Déconnexion Firebase
      await FirebaseAuth.instance.signOut();

      // Redirection vers la page d'accueil
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false, // Supprime toutes les routes précédentes
        );

        // Message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez été déconnecté avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Bouton de déconnexion réutilisable
  static Widget logoutButton(BuildContext context, {
    String text = 'Déconnexion',
    IconData icon = Icons.logout,
    bool isMenuItem = false,
  }) {
    if (isMenuItem) {
      return ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(
          text,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        onTap: () => logout(context),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => logout(context),
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Icône de déconnexion pour la barre d'application
  static Widget logoutIconButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Déconnexion',
      onPressed: () => logout(context),
    );
  }
}

// services/initial_setup_tutorial_manager.dart
import 'package:flutter/material.dart';
import '../models/tutorial_step.dart';

class InitialSetupTutorialManager {
  static List<TutorialStep> getInitialSetupTutorialSteps() {
    return [
      TutorialStep(
        id: 'setup_intro',
        title: 'Configuration initiale',
        description: 'Bienvenue ! Commençons par configurer votre hôtel. Nous allons vous guider à travers les 3 étapes essentielles pour démarrer.',
        icon: '🏨',
        position: TutorialPosition.center,
        pageIndex: 0, // Dashboard
        actions: [
          'Configurer les informations de l\'hôtel',
          'Créer vos chambres',
          'Ajouter votre personnel',
        ],
      ),
      TutorialStep(
        id: 'hotel_settings',
        title: 'Étape 1 : Informations de l\'hôtel',
        description: 'Rendez-vous dans les paramètres pour saisir les informations de votre établissement.',
        icon: '⚙️',
        position: TutorialPosition.right,
        pageIndex: 18, // Index de la page Paramètres (mis à jour)
        actions: [
          'Nom de l\'hôtel',
          'Adresse et contact',
          'Informations bancaires',
          'Taxes et pourcentages',
        ],
      ),
      TutorialStep(
        id: 'create_rooms',
        title: 'Étape 2 : Création des chambres',
        description: 'Créez maintenant vos chambres avec leurs caractéristiques et tarifs.',
        icon: '🛏️',
        position: TutorialPosition.right,
        pageIndex: 5, // Index de la page Chambres (mis à jour)
        actions: [
          'Numéro et type de chambre',
          'Capacité et équipements',
          'Prix par nuit',
          'Statut (disponible/maintenance)',
        ],
      ),
      TutorialStep(
        id: 'add_staff',
        title: 'Étape 3 : Ajout du personnel',
        description: 'Créez les comptes pour votre équipe avec leurs rôles et permissions.',
        icon: '👥',
        position: TutorialPosition.right,
        pageIndex: 11, // Index de la page Personnel
        actions: [
          'Nom et contact du personnel',
          'Rôle (réception, ménage, cuisine)',
          'Identifiants de connexion',
          'Permissions d\'accès',
        ],
      ),
      TutorialStep(
        id: 'setup_complete',
        title: 'Configuration terminée !',
        description: 'Félicitations ! Votre hôtel est maintenant configuré. Vous pouvez commencer à utiliser toutes les fonctionnalités.',
        icon: '🎉',
        position: TutorialPosition.center,
        pageIndex: 0, // Retour au Dashboard
        actions: [
          'Vous pouvez maintenant créer des réservations',
          'Gérer les enregistrements clients',
          'Suivre les paiements',
          'Utiliser le module restaurant',
        ],
      ),
    ];
  }

  static Map<String, GlobalKey> createInitialSetupKeys() {
    return {
      'settings': GlobalKey(),
      'rooms': GlobalKey(),
      'personnel': GlobalKey(),
    };
  }
}
// services/restaurant_tutorial_manager.dart
import 'package:flutter/material.dart';
import '../models/tutorial_step.dart';

class RestaurantTutorialManager {
  static List<TutorialStep> getRestaurantTutorialSteps() {
    return [
      TutorialStep(
        id: 'restaurant_intro',
        title: 'Bienvenue dans le module Restaurant',
        description: 'Découvrez comment gérer efficacement votre restaurant : tables, commandes, menu et statistiques.',
        icon: '🍽️',
        position: TutorialPosition.center,
        pageIndex: 0, // Onglet Accueil
        actions: [
          'Gérer vos tables',
          'Prendre des commandes',
          'Gérer le menu',
          'Suivre les statistiques',
        ],
      ),
      TutorialStep(
        id: 'restaurant_dashboard',
        title: 'Tableau de bord Restaurant',
        description: 'Voici votre vue d\'ensemble. Consultez rapidement l\'état de vos tables, commandes actives et statistiques du jour.',
        icon: '📊',
        position: TutorialPosition.center,
        pageIndex: 0, // Onglet Accueil
        actions: [
          'Vue en temps réel des tables',
          'Nombre de commandes actives',
          'Chiffre d\'affaires du jour',
          'Accès rapide aux actions',
        ],
      ),
      TutorialStep(
        id: 'restaurant_tables',
        title: 'Gestion des Tables',
        description: 'Créez et gérez vos tables. Définissez le nombre de places, l\'emplacement et suivez leur statut en temps réel.',
        icon: '🪑',
        position: TutorialPosition.right,
        pageIndex: 1, // Onglet Tables
        actions: [
          'Créer de nouvelles tables',
          'Numéro et capacité',
          'Statut : libre, occupée, réservée',
          'Associer des commandes aux tables',
        ],
      ),
      TutorialStep(
        id: 'restaurant_orders',
        title: 'Prise de Commandes',
        description: 'Prenez les commandes facilement. Sélectionnez une table, ajoutez des articles du menu et envoyez en cuisine.',
        icon: '📝',
        position: TutorialPosition.right,
        pageIndex: 2, // Onglet Commandes
        actions: [
          'Sélectionner une table',
          'Ajouter des articles au menu',
          'Quantités et notes spéciales',
          'Envoyer la commande en cuisine',
        ],
      ),
      TutorialStep(
        id: 'restaurant_menu',
        title: 'Gestion du Menu',
        description: 'Créez et organisez votre menu. Ajoutez des catégories, des plats avec photos, descriptions et prix.',
        icon: '📋',
        position: TutorialPosition.right,
        pageIndex: 2, // Reste sur Commandes (menu accessible depuis là)
        actions: [
          'Créer des catégories (Entrées, Plats, Desserts...)',
          'Ajouter des articles avec photos',
          'Définir prix et descriptions',
          'Gérer la disponibilité des articles',
        ],
      ),
      TutorialStep(
        id: 'restaurant_payment',
        title: 'Encaissement et Facturation',
        description: 'Gérez les paiements facilement. Visualisez les commandes, calculez le total et encaissez.',
        icon: '💰',
        position: TutorialPosition.right,
        pageIndex: 2, // Onglet Commandes
        actions: [
          'Voir le détail des commandes',
          'Calcul automatique du total',
          'Modes de paiement multiples',
          'Impression de reçus',
        ],
      ),
      TutorialStep(
        id: 'restaurant_stats',
        title: 'Statistiques et Rapports',
        description: 'Suivez vos performances. Consultez le chiffre d\'affaires, les articles populaires et exportez des rapports.',
        icon: '📈',
        position: TutorialPosition.right,
        pageIndex: 3, // Onglet Stats
        actions: [
          'Chiffre d\'affaires par période',
          'Articles les plus vendus',
          'Taux d\'occupation des tables',
          'Export Excel et PDF',
        ],
      ),
      TutorialStep(
        id: 'restaurant_reservations',
        title: 'Réservations de Tables',
        description: 'Gérez les réservations de vos clients. Planifiez à l\'avance et optimisez le placement.',
        icon: '📅',
        position: TutorialPosition.right,
        pageIndex: 1, // Onglet Tables
        actions: [
          'Créer des réservations',
          'Nom du client et heure',
          'Nombre de personnes',
          'Confirmation et rappels',
        ],
      ),
      TutorialStep(
        id: 'restaurant_complete',
        title: 'Prêt à gérer votre restaurant !',
        description: 'Vous êtes maintenant prêt à utiliser le module restaurant. Bonne gestion !',
        icon: '🎉',
        position: TutorialPosition.center,
        pageIndex: 0, // Retour à l'Accueil
        actions: [
          'Commencez par créer vos tables',
          'Configurez votre menu',
          'Prenez votre première commande',
          'Consultez vos statistiques',
        ],
      ),
    ];
  }

  static Map<String, GlobalKey> createRestaurantKeys() {
    return {
      'dashboard': GlobalKey(),
      'tables': GlobalKey(),
      'orders': GlobalKey(),
      'menu': GlobalKey(),
      'stats': GlobalKey(),
    };
  }
}

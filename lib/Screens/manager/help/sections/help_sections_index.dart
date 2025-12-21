import 'package:flutter/material.dart'; // Nécessaire pour IconData

import '../help_models.dart';
// Imports de toutes les sections de fonctionnalités existantes
import 'checkin_help.dart';
import 'dashboard_help.dart';
import 'finance_help.dart';
import 'licenses_help.dart';
import 'payments_help.dart';
import 'reservations_help.dart';
import 'restaurant_help.dart';
import 'rooms_help.dart';
import 'settings_help.dart';
import 'staff_help.dart';
import 'tasks_help.dart';
import 'options_store_help.dart';
import 'support_help.dart';


// 💡 Nouvelle fonction pour la Documentation (à développer)
HelpCategory getConceptualOverview() {
  return HelpCategory(
    title: 'Aperçu Conceptuel',
    icon: Icons.lightbulb_outline,
    sections: [
      HelpSection(
        title: 'Principes de Gestion',
        content: 'Cette section explique la philosophie derrière la gestion des flux de travail dans l\'application Gesto.',
      ),
      HelpSection(
        title: 'Architecture des Données',
        content: 'Un aperçu de la manière dont les réservations, les chambres et les paiements sont liés.',
      ),
    ],
  );
}

// 📌 NOUVELLE FONCTION PRINCIPALE
List<HelpMenu> getAllHelpMenus() {

  // ----------------------------------------------------
  // 1. Définition du contenu pour le menu "AIDE (Fonctionnalités)"
  // ----------------------------------------------------
  final List<HelpCategory> aideCategories = [
    getDashboardHelp(),
    getReservationsHelp(),
    getCheckinHelp(),
    getRoomsHelp(),
    getPaymentsHelp(),
    getFinanceHelp(),
    getRestaurantHelp(),
    getTasksHelp(),
    getStaffHelp(),
    getSettingsHelp(),
    getOptionsStoreHelp(),  // Nouvelle section : Boutique d'Options
    getSupportHelp(),        // Nouvelle section : Support et Assistance
  ];

  // ----------------------------------------------------
  // 2. Définition du contenu pour le menu "DOCUMENTATION"
  // ----------------------------------------------------
  final List<HelpCategory> documentationCategories = [
    getConceptualOverview(), // Exemples de nouvelles catégories
    getLicensesHelp(),       // Vos informations de licence existantes
    HelpCategory(
      title: 'Politique de Confidentialité',
      icon: Icons.security,
      sections: [
        HelpSection(title: 'Utilisation des données', content: 'Détails sur la collecte et l\'utilisation des données personnelles.'),
      ],
    ),
  ];


  // ----------------------------------------------------
  // 3. Création de la structure de menu de niveau supérieur
  // ----------------------------------------------------
  return [
    HelpMenu(
      title: 'Aide (Fonctionnalités)',
      icon: Icons.help_outline,
      categories: aideCategories,
    ),
    HelpMenu(
      title: 'Documentation',
      icon: Icons.book_outlined,
      categories: documentationCategories,
    ),
  ];
}
import 'package:flutter/material.dart';

// NOUVEAU MODÈLE
/// Modèle pour le niveau de menu supérieur (ex: "Aide", "Documentation")
class HelpMenu {
  final String title;
  final IconData icon; // Optionnel : icône pour le menu principal
  final List<HelpCategory> categories;

  HelpMenu({
    required this.title,
    required this.icon,
    required this.categories,
  });
}

/// Modèle pour une catégorie d'aide
class HelpCategory {
  final String title;
  final IconData icon;
  final List<HelpSection> sections;

  HelpCategory({
    required this.title,
    required this.icon,
    required this.sections,
  });
}

/// Modèle pour une section d'aide
class HelpSection {
  final String title;
  final String? content;        // Texte optionnel
  final List<String> steps;
  final Widget? customWidget;   // UI avancée optionnelle

  HelpSection({
    required this.title,
    this.content,
    this.steps = const [],
    this.customWidget,
  });
}


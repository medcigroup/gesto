import 'package:flutter/material.dart';
import '../help_models.dart';

HelpCategory getSupportHelp() {
  return HelpCategory(
    title: 'Support et Assistance',
    icon: Icons.support_agent,
    sections: [
      // Section 1 : Vue d'ensemble
      HelpSection(
        title: '📞 Vue d\'ensemble du Support',
        content:
            'Le système de support intégré permet aux utilisateurs de signaler des bugs, demander de l\'aide, ou suggérer des améliorations. Les managers peuvent suivre et répondre à tous les tickets depuis un tableau de bord centralisé.',
        steps: [],
      ),

      // Section 2 : Créer un ticket de support
      HelpSection(
        title: '🎫 Créer un Ticket de Support',
        content:
            'Tous les utilisateurs peuvent créer des tickets de support :',
        steps: [
          'Accédez à la page "Support" depuis le menu principal',
          'Cliquez sur "Nouveau Ticket" ou "Créer un ticket"',
          'Remplissez le formulaire avec les informations requises',
          'Sujet : Titre court et descriptif du problème',
          'Description : Expliquez le problème en détail',
          'Catégorie : Bug, Fonctionnalité, Question, Feedback, Autre',
          'Priorité : Basse, Moyenne, Haute, Urgente (selon la gravité)',
          'Attachements : Joignez des captures d\'écran si nécessaire (optionnel)',
          'Cliquez sur "Envoyer" pour soumettre votre ticket',
        ],
      ),

      // Section 3 : Catégories de tickets
      HelpSection(
        title: '📂 Catégories de Tickets',
        content:
            'Choisissez la catégorie appropriée pour votre demande :',
        steps: [
          '🐛 BUG : Dysfonctionnement ou erreur dans l\'application',
          '✨ FONCTIONNALITÉ : Suggestion de nouvelle fonctionnalité',
          '❓ QUESTION : Besoin d\'aide ou d\'information',
          '💬 FEEDBACK : Retour d\'expérience ou commentaire général',
          '📋 AUTRE : Demandes diverses ne correspondant pas aux catégories ci-dessus',
        ],
      ),

      // Section 4 : Niveaux de priorité
      HelpSection(
        title: '⚡ Niveaux de Priorité',
        content:
            'Sélectionnez le niveau de priorité adapté à votre situation :',
        steps: [
          '🔵 BASSE : Amélioration mineure, pas d\'impact sur l\'utilisation',
          '🟡 MOYENNE : Problème gênant mais contournable',
          '🟠 HAUTE : Problème important affectant votre travail',
          '🔴 URGENTE : Blocage total, impossible de travailler',
          'Les tickets urgents sont traités en priorité par l\'équipe support',
        ],
      ),

      // Section 5 : Suivre vos tickets
      HelpSection(
        title: '👀 Suivre vos Tickets',
        content:
            'Consultez l\'état d\'avancement de vos demandes :',
        steps: [
          'Accédez à "Mes Tickets" depuis la page Support',
          'Tous vos tickets sont listés avec leur statut actuel',
          'Cliquez sur un ticket pour voir les détails et les échanges',
          'Vous recevez une notification quand un admin répond',
          'Consultez l\'historique complet des messages',
        ],
      ),

      // Section 6 : Statuts des tickets
      HelpSection(
        title: '🏷️ Statuts des Tickets',
        content:
            'Comprendre les différents statuts :',
        steps: [
          '🆕 OUVERT (Open) : Ticket créé, en attente de traitement',
          '🔄 EN COURS (In Progress) : Un administrateur travaille sur votre demande',
          '⏸️ EN ATTENTE (Waiting) : En attente d\'informations supplémentaires de votre part',
          '✅ RÉSOLU (Resolved) : Problème résolu, en attente de votre confirmation',
          '🔒 FERMÉ (Closed) : Ticket traité et clôturé définitivement',
        ],
      ),

      // Section 7 : Communiquer avec le support
      HelpSection(
        title: '💬 Communiquer avec le Support',
        content:
            'Échangez avec l\'équipe support directement dans vos tickets :',
        steps: [
          'Ouvrez un ticket existant depuis votre liste',
          'Scrollez vers le bas pour voir la zone de messagerie',
          'Tapez votre message dans le champ de texte',
          'Ajoutez des pièces jointes si nécessaire (captures d\'écran, documents)',
          'Cliquez sur "Envoyer" pour poster votre message',
          'Les réponses des admins apparaissent avec un badge "Admin"',
          'Vous êtes notifié en temps réel des nouvelles réponses',
        ],
      ),

      
      // Section 8 : Roadmap publique
      HelpSection(
        title: '🗺️ Roadmap (Feuille de Route)',
        content:
            'Consultez les fonctionnalités en développement et à venir :',
        steps: [
          'Accédez à "Roadmap" depuis le menu Support',
          'Visualisez toutes les améliorations prévues',
          'Statuts : Planifié, En cours, Complété, Annulé',
          'Votez pour les fonctionnalités qui vous intéressent (👍)',
          'Les fonctionnalités les plus demandées sont priorisées',
          'Consultez les dates estimées de livraison',
          'Recevez des notifications quand une fonctionnalité est complétée',
        ],
      ),

      // Section 9 : Créer des éléments roadmap (Admin)
      HelpSection(
        title: '🛠️ Gérer la Roadmap (Managers)',
        content:
            'Créez et gérez la feuille de route publique :',
        steps: [
          'Accédez à "Roadmap Admin" depuis le dashboard manager',
          'Cliquez sur "Nouvel Élément"',
          'Remplissez : Titre, Description, Catégorie, Priorité',
          'Définissez le statut actuel (Planifié/En cours/Complété)',
          'Ajoutez une date estimée si possible',
          'Ajoutez des tags pour faciliter la recherche',
          'Publiez - L\'élément devient visible pour tous les utilisateurs',
          'Mettez à jour le statut régulièrement pour tenir vos utilisateurs informés',
        ],
      ),

      // Section 10 : Bonnes pratiques
      HelpSection(
        title: '✅ Bonnes Pratiques',
        content:
            'Conseils pour une utilisation optimale du support :',
        steps: [
          'Utilisateurs : Soyez précis dans vos descriptions de problèmes',
          'Joignez toujours des captures d\'écran pour les bugs visuels',
          'Vérifiez les tickets existants avant de créer un doublon',
          'Répondez rapidement aux demandes d\'information des admins',
          'Fermez les tickets une fois votre problème résolu',
          
        ],
      ),

      // Section 14 : Notifications
      HelpSection(
        title: '🔔 Système de Notifications',
        content:
            'Restez informé en temps réel :',
        steps: [
          'Notifications push lors de nouvelles réponses à vos tickets',
          'Notifications email pour les mises à jour importantes',
          'Badge de notification sur l\'icône Support',
          'Personnalisez vos préférences de notification dans Paramètres',
          
        ],
      ),

      // Section 15 : Sécurité et confidentialité
      HelpSection(
        title: '🔐 Sécurité et Confidentialité',
        content:
            'Vos données de support sont protégées :',
        steps: [
          'Seul le créateur du ticket et les admins peuvent voir son contenu',
          'Les données sont stockées de manière sécurisée dans Firebase',
          'Chiffrement des communications sensibles',
          'Possibilité de supprimer vos tickets (selon politique de rétention)',
          'Conformité RGPD : Vos données personnelles sont protégées',
          'Archivage automatique des tickets de plus de 6 mois',
        ],
      ),

      // Section 16 : FAQ rapide
      HelpSection(
        title: '❓ FAQ Support',
        content:
            'Réponses aux questions fréquentes :',
        steps: [
          'Q: Combien de temps pour une réponse ? R: 24-48h en moyenne, plus rapide pour les urgences',
          'Q: Puis-je modifier un ticket ? R: Oui, via les messages additionnels',
          'Q: Puis-je supprimer un ticket ? R: Contactez un admin',
          'Q: Comment joindre une capture d\'écran ? R: Bouton "Pièce jointe" lors de la création ou message',
          'Q: Qui voit mes tickets ? R: Uniquement vous et l\'équipe support',
          'Q: Comment voter pour une fonctionnalité ? R: Page Roadmap, clic sur 👍',
        ],
      ),
    ],
  );
}

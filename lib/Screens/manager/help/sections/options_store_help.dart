import 'package:flutter/material.dart';
import '../help_models.dart';

HelpCategory getOptionsStoreHelp() {
  return HelpCategory(
    title: 'Boutique d\'Options',
    icon: Icons.storefront,
    sections: [
      // Section 1 : Vue d'ensemble
      HelpSection(
        title: '📋 Vue d\'ensemble',
        content:
            'La Boutique d\'Options permet de vendre des services supplémentaires à vos clients (petit-déjeuner, spa, piscine, etc.). Le système supporte les clients enregistrés et les clients externes avec génération automatique de tickets.',
        steps: [],
      ),

      // Section 2 : Accéder à la boutique
      HelpSection(
        title: '🏪 Accéder à la Boutique d\'Options',
        content:
            'Vous pouvez accéder à la boutique depuis plusieurs endroits :',
        steps: [
          'Depuis le Dashboard Manager : Cliquez sur le bouton "Boutique d\'options"',
          'Lors d\'un check-in : Proposez des options au client via le bouton "Ajouter des options"',
          'Page publique : Les clients externes peuvent accéder directement à la boutique',
        ],
      ),

      // Section 3 : Vendre à un client enregistré
      HelpSection(
        title: '👤 Vendre à un Client Enregistré',
        content:
            'Pour un client qui a déjà une réservation :',
        steps: [
          'Depuis la fiche de réservation ou check-in, cliquez sur "Ajouter des options"',
          'Les informations client (nom, email, téléphone, chambre) sont pré-remplies',
          'Sélectionnez les options désirées dans le catalogue',
          'Pour chaque option : choisissez la période (heure/jour/semaine/mois) et la quantité',
          'Vérifiez le panier et le montant total',
          'Cliquez sur "Confirmer l\'achat"',
          'Le ticket sera généré automatiquement au format 80x80mm',
        ],
      ),

      // Section 4 : Vendre à un client externe
      HelpSection(
        title: '🌐 Vendre à un Client Externe',
        content:
            'Pour un client sans réservation (client de passage) :',
        steps: [
          'Accédez à la Boutique d\'Options',
          'Le formulaire client apparaît automatiquement',
          'Remplissez : Nom, Email, Téléphone du client',
          'Sélectionnez les options dans le catalogue',
          'Ajustez période et quantité pour chaque option',
          'Validez les informations et confirmez l\'achat',
          'Le ticket est généré avec un code-barres unique',
        ],
      ),

      // Section 5 : Catalogue d'options
      HelpSection(
        title: '🛒 Catalogue et Catégories',
        content:
            'Les options sont organisées par catégories pour faciliter la recherche :',
        steps: [
          '🍽️ Restauration : Petit-déjeuner, room service, déjeuner, dîner',
          '🏊 Équipements : Piscine, gym, spa, jacuzzi, sauna',
          '🛎️ Services : Concierge, blanchisserie, pressing, ménage supplémentaire',
          '🚗 Transport : Navette aéroport, location voiture, taxi',
          '💆 Bien-être : Massage, soins du visage, yoga, méditation',
          'Utilisez les filtres pour afficher une catégorie spécifique',
        ],
      ),

      // Section 6 : Périodes de tarification
      HelpSection(
        title: '⏰ Périodes de Tarification',
        content:
            'Chaque option peut avoir différentes périodes de tarification :',
        steps: [
          'À l\'HEURE : Pour services courts (massage 1h, spa 2h)',
          'AU JOUR : Pour services journaliers (petit-déjeuner, accès piscine)',
          'À LA SEMAINE : Pour forfaits hebdomadaires (gym 7 jours)',
          'AU MOIS : Pour abonnements mensuels (parking longue durée)',
          'Le calcul du total est automatique : Prix unitaire × Quantité',
          'Exemple : Piscine à 5000 FCFA/jour × 3 jours = 15000 FCFA',
        ],
      ),

      // Section 7 : Panier et validation
      HelpSection(
        title: '🛍️ Panier et Validation',
        content:
            'Le panier affiche en temps réel votre sélection :',
        steps: [
          'Chaque option ajoutée apparaît dans le panier à droite',
          'Vous voyez : Nom, période sélectionnée, quantité, sous-total',
          'Modifiez la quantité directement depuis le panier',
          'Supprimez une option en cliquant sur la corbeille',
          'Le TOTAL GÉNÉRAL se met à jour automatiquement',
          'Sélectionnez le mode de paiement (Espèces, Carte, Mobile Money, Virement)',
          'Cliquez sur "Confirmer l\'achat" pour finaliser',
        ],
      ),

      // Section 8 : Génération du ticket
      HelpSection(
        title: '🎫 Ticket et Impression',
        content:
            'Un ticket au format professionnel est généré après chaque achat :',
        steps: [
          'Format standard 80x80mm (imprimantes thermiques)',
          'Contient : Nom hôtel, infos client, liste détaillée des options',
          'Code-barres unique pour traçabilité',
          'Montant total et mode de paiement',
          'Actions disponibles : Imprimer, Partager par Email/WhatsApp, Télécharger PDF',
          'Aperçu disponible avant impression',
        ],
      ),

      // Section 9 : Configurer les options
      HelpSection(
        title: '⚙️ Configurer les Options Disponibles',
        content:
            'Seuls les managers peuvent créer et modifier les options vendues :',
        steps: [
          'Accédez à "Gestion des Packages" depuis Paramètres',
          'Cliquez sur "Ajouter un nouveau package"',
          'Remplissez : Nom, Description, Catégorie',
          'Sélectionnez "Payant" (non inclus dans le séjour)',
          'Définissez les prix : par heure, jour, semaine et/ou mois',
          'Choisissez l\'icône appropriée',
          'Activez l\'option pour qu\'elle apparaisse dans la boutique',
          'Sauvegardez - L\'option est immédiatement disponible à la vente',
        ],
      ),

      // Section 10 : Historique et suivi
      HelpSection(
        title: '📊 Suivi des Ventes',
        content:
            'Toutes les ventes sont enregistrées dans Firestore pour analyse :',
        steps: [
          'Collection "option_purchases" stocke chaque transaction',
          'Informations enregistrées : Client, options achetées, montants, date',
          'Statuts possibles : paid (payé), pending (en attente), cancelled (annulé)',
          'Consultez les ventes depuis la page Finance',
          'Filtrez par période, client, ou type d\'option',
          'Exportez les données pour comptabilité',
        ],
      ),

      // Section 11 : Modes de paiement
      HelpSection(
        title: '💳 Modes de Paiement',
        content:
            'Plusieurs modes de paiement sont disponibles :',
        steps: [
          'Espèces : Paiement en liquide au comptoir',
          'Carte bancaire : Terminal de paiement électronique',
          'Mobile Money : Orange Money, MTN Money, Moov Money, Wave',
          'Virement : Transfert bancaire direct',
          'Le mode de paiement est enregistré sur le ticket et dans le système',
        ],
      ),

      // Section 12 : Conseils et bonnes pratiques
      HelpSection(
        title: '💡 Conseils et Bonnes Pratiques',
        content:
            'Pour optimiser l\'utilisation de la Boutique d\'Options :',
        steps: [
          'Proposez les options dès le check-in pour augmenter les ventes',
          'Créez des packages attractifs (ex: "Forfait Bien-être 3 jours")',
          'Utilisez des photos de qualité pour les options (à venir)',
          'Formez votre équipe sur les options disponibles',
          'Offrez des réductions pour les achats de longue durée',
          'Analysez régulièrement les options les plus vendues',
          'Ajustez les tarifs selon la saisonnalité',
          'Imprimez et remettez toujours le ticket au client',
        ],
      ),

      // Section 13 : Dépannage
      HelpSection(
        title: '🔧 Dépannage',
        content:
            'Solutions aux problèmes courants :',
        steps: [
          'Options non visibles : Vérifiez qu\'elles sont bien activées et en mode "Payant"',
          'Impression impossible : Vérifiez la connexion de l\'imprimante thermique',
          'Total incorrect : Actualisez la page et recalculez',
          'Client introuvable : Utilisez le mode "Client externe" avec formulaire manuel',
          'Ticket non généré : Vérifiez votre connexion Internet et réessayez',
        ],
      ),
    ],
  );
}

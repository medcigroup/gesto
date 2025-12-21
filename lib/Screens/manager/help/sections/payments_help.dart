import 'package:flutter/material.dart';
import '../help_models.dart';

HelpCategory getPaymentsHelp() {
  return HelpCategory(
    title: 'Paiements',
    icon: Icons.payment_rounded,
    sections: [
      HelpSection(
        title: 'Comprendre le système de paiement',
        content: '''Le module de paiement gère tous les flux financiers liés aux réservations : acomptes, paiements partiels, soldes, réductions et remboursements. Il assure une traçabilité complète de toutes les transactions.

Architecture du système de paiement :

1. Acompte lors de la réservation :
Montant initial versé pour confirmer la réservation. Généralement 10% à 50% du total.

2. Paiements intermédiaires :
Le client peut payer en plusieurs fois pendant son séjour.

3. Solde final :
Montant restant dû, généralement payé au check-out.

4. Services supplémentaires :
Consommations du minibar, room service, spa, ajoutés à la facture.

Chaque paiement génère :
• Une transaction enregistrée dans la base de données
• Un reçu imprimable avec numéro unique
• Une mise à jour du solde restant
• Une trace dans l'historique des paiements

Modes de paiement acceptés :
✓ Espèces (cash)
✓ Carte bancaire (CB, Visa, Mastercard)
✓ Virement bancaire
✓ Mobile money (Wave, Orange Money, MTN, Moov)
✓ Chèque (avec période de validation)''',
        steps: [
          'Accédez au menu "Paiements" pour voir toutes les réservations actives',
          'La liste affiche les clients avec leur statut de paiement : Payé, Partiellement payé, Impayé',
          'Un code couleur facilite l\'identification : Vert = Payé, Orange = Partiel, Rouge = Impayé',
          'Utilisez la recherche pour trouver rapidement un client par nom ou code',
          'Filtrez par statut pour voir uniquement les paiements en attente',
        ],
      ),
      HelpSection(
        title: 'Enregistrer un paiement',
        content: '''L'enregistrement d'un paiement est une opération critique qui doit être précise et tracée. Le système vous guide pour éviter les erreurs et garantit que chaque montant reçu est correctement comptabilisé.

Informations enregistrées pour chaque paiement :
• Montant exact reçu
• Mode de paiement utilisé
• Date et heure de transaction (automatique)
• Numéro de transaction unique (généré automatiquement)
• Référence bancaire si virement ou CB
• Nom de l'opérateur qui a encaissé
• Commentaires éventuels

Le système calcule automatiquement :
• Le solde restant après ce paiement
• Le pourcentage payé du total
• Les éventuels trop-perçus (crédit client)''',
        steps: [
          'Dans la liste des paiements, trouvez la réservation concernée',
          'Cliquez sur "Enregistrer un paiement" ou l\'icône €',
          'Une fenêtre s\'ouvre affichant le récapitulatif complet : Montant total du séjour, Acompte déjà versé, Paiements intermédiaires, Solde restant',
          'Choisissez le type de paiement : "Paiement partiel" (montant personnalisé) ou "Solde complet" (tout le restant)',
          'Si paiement partiel : Saisissez le montant exact reçu du client',
          'Sélectionnez le mode de paiement dans la liste déroulante',
          'Ajoutez une description ou référence si nécessaire (n° de chèque, référence virement)',
          'Vérifiez le nouveau solde restant affiché automatiquement',
          'Cochez "Appliquer une réduction" si vous offrez un rabais commercial',
          'Si réduction : Indiquez le pourcentage ou le montant fixe',
          'Cliquez sur "Valider le paiement" pour enregistrer',
          'Le système génère un reçu de paiement avec numéro unique',
          'Imprimez le reçu et remettez-le au client',
          'La transaction apparaît immédiatement dans l\'historique',
        ],
      ),
      HelpSection(
        title: 'Historique et suivi des transactions',
        content: '''L'historique des transactions est un journal complet de tous les mouvements financiers. Il est essentiel pour la comptabilité, les audits et la résolution de litiges.

Informations disponibles dans l'historique :
• Date et heure exacte de chaque transaction
• Numéro unique de transaction
• Type (acompte, paiement, réduction, remboursement)
• Montant
• Mode de paiement
• Solde avant et après transaction
• Opérateur ayant effectué la transaction
• Commentaires et notes

Utilisation de l'historique :
✓ Vérifier qu'un client a bien payé
✓ Justifier un montant en cas de contestation
✓ Tracer les paiements pour la comptabilité
✓ Identifier les anomalies ou erreurs
✓ Générer des rapports financiers
✓ Préparer les clôtures journalières et mensuelles''',
        steps: [
          'Cliquez sur une réservation dans la liste des paiements',
          'Dans la fiche détaillée, accédez à l\'onglet "Historique des paiements"',
          'Tous les paiements et réductions apparaissent chronologiquement',
          'Chaque ligne affiche : Date, Type, Montant, Mode, Solde restant',
          'Cliquez sur une transaction pour voir tous ses détails',
          'Vous pouvez réimprimer le reçu d\'une transaction passée',
          'Utilisez les filtres pour voir seulement certains types de transactions',
          'Exportez l\'historique en PDF ou Excel pour vos archives',
        ],
      ),
    ],
  );
}

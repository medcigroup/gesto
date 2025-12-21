import 'package:flutter/material.dart';
import '../help_models.dart';

HelpCategory getReservationsHelp() {
  return HelpCategory(
    title: 'Réservations',
    icon: Icons.event_note_rounded,
    sections: [
      HelpSection(
        title: 'Processus de réservation en 4 étapes',
        content: '''Le système de réservation est conçu comme un assistant intelligent qui vous guide à travers chaque étape. Cette approche progressive réduit les erreurs et garantit que toutes les informations nécessaires sont collectées.

Étape 1 - Sélection des dates :
Choisissez les dates d'arrivée et de départ. Le système vérifie automatiquement la disponibilité des chambres pour cette période en croisant les données des réservations, bookings et passages horaires.

Étape 2 - Choix de la chambre :
Une fois les dates validées, vous voyez uniquement les chambres réellement disponibles. Chaque chambre affiche son type, son prix, sa capacité et ses équipements (WiFi, climatisation, balcon, etc.).

Étape 3 - Informations du client :
Saisissez les coordonnées complètes du client : nom, email, téléphone, nombre d'invités et demandes spéciales (lit bébé, étage élevé, vue mer).

Étape 4 - Acompte et confirmation :
Définissez le montant de l'acompte (pourcentage personnalisable : 10%, 20%, 30%, 50% ou 100%). Le système calcule automatiquement le montant total, l'acompte et le solde restant.''',
        steps: [
          'Cliquez sur "Nouvelle réservation" depuis le tableau de bord ou le menu Réservations',
          'Sélectionnez la date d\'arrivée en utilisant le calendrier interactif. Les dates passées sont désactivées automatiquement',
          'Choisissez la date de départ. Si elle est antérieure à l\'arrivée, un message d\'erreur apparaît',
          'Cliquez sur "Rechercher les chambres disponibles" pour lancer la vérification de disponibilité',
          'Parcourez la liste des chambres disponibles avec leurs caractéristiques détaillées',
          'Sélectionnez la chambre qui correspond aux besoins du client',
          'Remplissez le formulaire client avec toutes les informations requises (champs avec * sont obligatoires)',
          'Définissez le pourcentage d\'acompte souhaité. Par défaut 30% mais modifiable selon votre politique',
          'Choisissez le mode de paiement de l\'acompte : Espèces, Carte bancaire, Virement, Mobile money',
          'Vérifiez le récapitulatif complet avec le calcul détaillé des montants',
          'Confirmez la réservation pour l\'enregistrer dans le système',
          'Imprimez le reçu de réservation à remettre au client ou à envoyer par email',
        ],
      ),
      HelpSection(
        title: 'Gérer les réservations existantes',
        content: '''La liste des réservations vous offre une vue complète de toutes les réservations passées, présentes et futures. Vous pouvez filtrer, rechercher et modifier facilement chaque réservation.

Fonctionnalités de recherche avancée :
• Recherche par nom de client
• Recherche par code de réservation
• Filtrage par statut (réservée, confirmée, annulée, terminée)
• Filtrage par période (aujourd'hui, cette semaine, ce mois)

Codes couleur des statuts :
🟢 Réservée (vert) : Réservation confirmée avec acompte versé
🟡 En attente (jaune) : Réservation créée sans acompte
🔴 Annulée (rouge) : Réservation annulée par le client ou l'hôtel
⚫ Terminée (gris) : Séjour terminé, client parti''',
        steps: [
          'Accédez au menu "Réservations" pour voir la liste complète',
          'Utilisez la barre de recherche en haut pour trouver une réservation spécifique',
          'Tapez le nom du client ou le code de réservation',
          'Cliquez sur une réservation pour voir tous ses détails (dates, chambre, paiements effectués, solde restant)',
          'Pour modifier : Cliquez sur l\'icône crayon ou le bouton "Modifier"',
          'Changez les dates, la chambre ou les informations client selon les besoins',
          'Pour annuler : Cliquez sur "Annuler la réservation". Une confirmation vous sera demandée',
          'En cas d\'annulation, spécifiez la raison (annulation client, no-show, overbooking, etc.)',
          'Le système met automatiquement à jour la disponibilité de la chambre',
          'Vous pouvez réimprimer le reçu à tout moment en cliquant sur l\'icône imprimante',
        ],
      ),
      HelpSection(
        title: 'Calendrier des réservations',
        content: '''Le calendrier visuel offre une vue d'ensemble de toutes vos réservations dans le temps. C'est l'outil idéal pour anticiper les périodes de forte affluence et planifier vos ressources.

Types d'affichage :
• Vue mensuelle : Aperçu global du mois avec le nombre de réservations par jour
• Vue hebdomadaire : Détail semaine par semaine avec les noms des clients
• Vue journalière : Planning détaillé heure par heure (utile pour les passages)

Codes couleur dans le calendrier :
🟦 Bleu clair : Chambres disponibles
🟧 Orange : Réservations à venir
🟥 Rouge : Chambres occupées
🟨 Jaune : Check-in prévu aujourd'hui
🟪 Violet : Check-out prévu aujourd'hui''',
        steps: [
          'Ouvrez le calendrier des réservations depuis le menu',
          'Choisissez le type d\'affichage (mois, semaine, jour) selon vos besoins',
          'Naviguez entre les périodes avec les flèches gauche/droite',
          'Cliquez sur une date pour voir les réservations de ce jour précis',
          'Survolez une réservation pour voir un aperçu rapide (nom client, chambre, statut)',
          'Double-cliquez sur une réservation pour ouvrir sa fiche complète',
          'Identifiez visuellement les périodes creuses pour lancer des promotions',
          'Repérez les périodes de haute affluence pour ajuster les tarifs à la hausse',
        ],
      ),
      HelpSection(
        title: 'Gestion des acomptes et paiements',
        content: '''Le système de paiement est entièrement intégré au processus de réservation. Vous pouvez personnaliser le pourcentage d'acompte et suivre précisément tous les paiements reçus.

Politique d'acompte flexible :
Vous définissez librement le pourcentage d'acompte requis :
• 10% pour les réservations de longue durée ou clients fidèles
• 30% pour la politique standard (par défaut)
• 50% pour les périodes de haute saison
• 100% pour les paiements anticipés ou promotions spéciales

Modes de paiement acceptés :
• Espèces
• Carte bancaire (Visa, Mastercard)
• Virement bancaire
• Mobile money (Wave, Orange Money, MTN Money)
• Chèque (avec délai d'encaissement)''',
        steps: [
          'Lors de la création de la réservation, arrivez à l\'étape "Paiement"',
          'Sélectionnez le pourcentage d\'acompte souhaité dans la liste déroulante',
          'Le système calcule automatiquement le montant de l\'acompte et le solde restant',
          'Exemple : Séjour de 50 000 FCFA avec acompte 30% = 15 000 FCFA d\'acompte, reste 35 000 FCFA',
          'Choisissez le mode de paiement utilisé par le client',
          'Validez le paiement pour l\'enregistrer dans le système',
          'Le reçu généré automatiquement indique l\'acompte versé et le solde dû',
          'Le solde restant sera demandé lors du check-in ou du check-out selon votre politique',
        ],
      ),
    ],
  );
}

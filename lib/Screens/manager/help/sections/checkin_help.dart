import 'package:flutter/material.dart';
import '../help_models.dart';

HelpCategory getCheckinHelp() {
  return HelpCategory(
    title: 'Enregistrement (Check-in)',
    icon: Icons.login_rounded,
    sections: [
      HelpSection(
        title: 'Processus de check-in avec réservation',
        content: '''Le check-in est le moment où vous accueillez officiellement votre client et lui remettez les clés de sa chambre. Ce processus transforme une réservation en séjour actif.

Déroulement standard du check-in :
1. Vérification de l'identité du client (carte d'identité, passeport)
2. Confirmation des dates de séjour et du type de chambre
3. Collecte des informations complémentaires si nécessaire
4. Encaissement du solde restant (si l'acompte n'était pas de 100%)
5. Signature du registre des voyageurs (obligation légale)
6. Remise des clés et explication des services de l'hôtel
7. Accompagnement à la chambre si demandé

Informations importantes à vérifier :
• Correspondance entre le nom sur la réservation et la pièce d'identité
• Validité de la carte bancaire pour la garantie
• Nombre réel de personnes (certains clients ajoutent des invités)
• Demandes spéciales (allergies, préférences alimentaires, mobilité)''',
        steps: [
          'Accédez à la page "Enregistrement" depuis le menu principal',
          'Deux options s\'offrent à vous : "Check-in avec réservation" ou "Walk-in sans réservation"',
          'Pour un client avec réservation : Recherchez la réservation par nom ou code',
          'Sélectionnez la réservation dans la liste des résultats',
          'Vérifiez que toutes les informations affichées sont correctes (dates, chambre, nombre de personnes)',
          'Demandez au client sa pièce d\'identité et saisissez le numéro dans le champ "N° Pièce d\'identité"',
          'Complétez la nationalité et l\'adresse du client si non renseignées',
          'Vérifiez le montant du solde restant à payer',
          'Encaissez le paiement si nécessaire via le bouton "Enregistrer paiement"',
          'Une fois le paiement validé, cliquez sur "Valider le check-in"',
          'Le système change automatiquement le statut de la chambre en "Occupée"',
          'Imprimez la fiche de police (registre des voyageurs) si requis par la législation locale',
          'Remettez les clés au client et souhaitez-lui un bon séjour',
        ],
      ),
      HelpSection(
        title: 'Enregistrement sans réservation (Walk-in)',
        content: '''Les walk-in sont des clients qui se présentent directement à la réception sans réservation préalable. Ce processus requiert de vérifier en temps réel la disponibilité des chambres et de créer un dossier client complet.

Avantages d'accepter les walk-in :
• Maximisation du taux d'occupation
• Opportunité de revenus supplémentaires
• Fidélisation de clients spontanés
• Tarification potentiellement plus élevée (dernière minute)

Points de vigilance :
• Vérifier attentivement la disponibilité (éviter le overbooking)
• Demander un paiement anticipé ou une empreinte de carte
• Expliquer clairement la politique d'annulation
• Être flexible sur le prix selon la période et le taux d'occupation''',
        steps: [
          'Dans la page "Enregistrement", cliquez sur "Nouvel enregistrement sans réservation"',
          'Sélectionnez les dates de séjour souhaités par le client',
          'Cliquez sur "Vérifier la disponibilité" pour lancer la recherche en temps réel',
          'Le système affiche toutes les chambres disponibles pour cette période',
          'Présentez les options au client avec les tarifs et caractéristiques',
          'Une fois le client d\'accord, sélectionnez la chambre choisie',
          'Remplissez le formulaire complet du client : Nom, prénom, email, téléphone obligatoires',
          'Ajoutez le numéro de pièce d\'identité, la nationalité et l\'adresse',
          'Indiquez le nombre de personnes qui occuperont la chambre',
          'Notez les demandes spéciales éventuelles',
          'Calculez le montant total du séjour (nombre de nuits × prix de la chambre)',
          'Encaissez le paiement initial (recommandé : au moins 50% ou totalité)',
          'Sélectionnez le mode de paiement utilisé',
          'Validez l\'enregistrement pour créer le dossier',
          'Le système génère automatiquement un code d\'enregistrement unique',
          'Imprimez le reçu et la fiche de police',
          'Remettez les clés et expliquez les horaires de l\'hôtel',
        ],
      ),
      HelpSection(
        title: 'Gérer les options et services additionnels',
        content: '''Lors du check-in, vous pouvez proposer et ajouter des services supplémentaires qui amélioreront l'expérience client et augmenteront vos revenus.

Services couramment proposés :
• Petit-déjeuner (continental, buffet, en chambre)
• Parking (couvert, découvert, avec voiturier)
• WiFi premium (débit élevé garanti)
• Spa et bien-être (massage, jacuzzi, sauna)
• Minibar (prérempli selon les préférences)
• Late check-out (départ après l'heure standard)
• Surclassement de chambre (upgrade vers catégorie supérieure)
• Transfert aéroport
• Service de blanchisserie
• Room service 24h/24

Chaque service a un prix défini dans vos paramètres. Le montant est automatiquement ajouté à la facture finale du client.''',
        steps: [
          'Pendant le processus de check-in, accédez à la section "Options et services"',
          'Consultez la liste de tous les services disponibles avec leurs prix',
          'Proposez au client les services qui pourraient l\'intéresser selon son profil',
          'Cochez les cases des services sélectionnés par le client',
          'Le système met à jour automatiquement le montant total du séjour',
          'Les services sont enregistrés et apparaîtront sur la facture finale',
          'Vous pouvez ajouter ou retirer des services même après le check-in en modifiant le dossier',
        ],
      ),
    ],
  );
}

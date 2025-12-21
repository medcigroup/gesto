import 'package:flutter/material.dart';
import '../help_models.dart';

HelpCategory getSettingsHelp() {
  return HelpCategory(
    title: 'Paramètres',
    icon: Icons.settings_rounded,
    sections: [
      // Section 1 : Vue d'ensemble
      HelpSection(
        title: '⚙️ Vue d\'ensemble',
        content:
            'La page Paramètres vous permet de configurer votre établissement, gérer les services proposés, personnaliser les horaires et définir les informations qui apparaîtront sur tous vos documents (factures, tickets, reçus).',
        steps: [],
      ),

      // Section 2 : Accéder aux paramètres
      HelpSection(
        title: '🔍 Accéder aux Paramètres',
        content:
            'Accédez à la page de configuration :',
        steps: [
          'Depuis le Dashboard Manager, cliquez sur "Paramètres"',
          'Ou utilisez le menu latéral et sélectionnez "Paramètres"',
          'La page se charge avec tous vos paramètres actuels',
        ],
      ),

      // Section 3 : Services & Packages
      HelpSection(
        title: '🎁 Gérer les Services & Packages',
        content:
            'Configurez les options et services proposés à vos clients (petit-déjeuner, piscine, spa, room service, etc.) :',
        steps: [
          'Dans la carte "Services & Packages" en haut de la page',
          'Cliquez sur "Gérer les Options & Packages"',
          'Vous accédez à l\'interface de gestion complète',
          'Créez des packages INCLUS (dans le prix de la chambre)',
          'Ou des packages PAYANTS (vendus séparément via la Boutique d\'Options)',
          'Catégories disponibles : Restauration 🍽️, Équipements 🏊, Services 🛎️',
          'Définissez les tarifs par période (heure, jour, semaine, mois)',
          'Activez/désactivez chaque option selon la disponibilité',
        ],
      ),

      // Section 4 : Ma Page Publique (Entreprise)
      HelpSection(
        title: '🌐 Ma Page Publique (Licence Entreprise)',
        content:
            'Créez une page web publique avec une URL unique pour votre établissement :',
        steps: [
          'Cette fonctionnalité est réservée aux licences ENTREPRISE',
          'Dans la carte "Ma Page Publique", cliquez sur "Gérer Ma Page Publique"',
          'Vous pouvez personnaliser : Photos, Description, Services, Tarifs',
          'Votre URL sera : gestoapp.cloud/hotel/votre-hotel',
          'Les clients peuvent consulter vos chambres et réserver en ligne',
          'La page est responsive (adaptée mobile, tablette, desktop)',
          'Mettez à jour les informations quand vous voulez',
        ],
      ),

      // Section 5 : Informations de l'établissement
      HelpSection(
        title: '🏨 Informations de l\'Établissement',
        content:
            'Ces informations apparaissent sur tous vos documents officiels (factures, reçus, tickets) :',
        steps: [
          'Nom de l\'établissement : Nom officiel de votre hôtel/résidence',
          'Adresse : Adresse complète avec ville et pays',
          'Numéro de téléphone : Contact principal (format : +225 XX XX XX XX XX)',
          'Email : Adresse email professionnelle',
          'Tous ces champs sont REQUIS',
          'Cliquez "Enregistrer les paramètres" en bas de page pour sauvegarder',
          'Les modifications s\'appliquent immédiatement à tous les nouveaux documents',
        ],
      ),

      // Section 6 : Informations du restaurant
      HelpSection(
        title: '🍴 Informations du Restaurant',
        content:
            'Configurez les informations spécifiques pour votre restaurant (apparaissent sur les tickets de caisse et factures du restaurant) :',
        steps: [
          'Nom du restaurant : Si différent du nom de l\'établissement',
          'Adresse du restaurant : Si située ailleurs que l\'établissement principal',
          'Téléphone du restaurant : Ligne directe du restaurant',
          'Ces champs sont OPTIONNELS',
          'Si vous les laissez vides, les informations de l\'établissement seront utilisées',
          'Utile si votre restaurant a une identité séparée ou un emplacement différent',
          'Sauvegardez pour appliquer les changements',
        ],
      ),

      // Section 7 : Informations générales
      HelpSection(
        title: '📋 Informations Générales',
        content:
            'Paramètres globaux de fonctionnement de votre établissement :',
        steps: [
          'DEVISE : Actuellement uniquement FCFA (Franc CFA)',
          'Heure d\'arrivée en chambre : Heure de check-in standard (ex: 14:00)',
          'Heure de départ de la chambre : Heure de check-out standard (ex: 11:00)',
          'Pourcentage d\'acompte : % requis lors d\'une réservation (ex: 30%)',
          'Cliquez sur l\'icône horloge pour sélectionner les heures facilement',
          'Le pourcentage d\'acompte doit être entre 0 et 100',
          'Ces paramètres s\'appliquent à toutes les nouvelles réservations',
        ],
      ),

      // Section 8 : Types de chambre
      HelpSection(
        title: '🛏️ Types de Chambre',
        content:
            'Définissez les différents types de chambres disponibles dans votre établissement :',
        steps: [
          'Exemples de types : Chambre Simple, Double, Suite, Deluxe, etc.',
          'Dans le champ "Nouveau type de chambre", tapez le nom',
          'Cliquez sur le bouton + pour ajouter',
          'Le type apparaît dans la liste en dessous',
          'Pour supprimer un type : Cliquez sur l\'icône corbeille rouge',
          'Les types définis ici seront disponibles lors de la création de chambres',
          'Vous pouvez ajouter autant de types que nécessaire',
          'N\'oubliez pas de sauvegarder en bas de page',
        ],
      ),

      // Section 9 : Sauvegarder les modifications
      HelpSection(
        title: '💾 Enregistrer les Paramètres',
        content:
            'Comment sauvegarder vos modifications :',
        steps: [
          'Après avoir modifié vos paramètres, scrollez en bas de la page',
          'Cliquez sur le bouton "ENREGISTRER LES PARAMÈTRES"',
          'Un message de confirmation apparaît en haut : "Paramètres enregistrés avec succès"',
          'Les modifications sont sauvegardées dans Firebase instantanément',
          'Si une erreur se produit, un message rouge s\'affiche avec les détails',
          'Tous les paramètres sont validés avant sauvegarde',
          'Les champs requis doivent être remplis pour pouvoir sauvegarder',
        ],
      ),

      // Section 10 : Validation des champs
      HelpSection(
        title: '✅ Validation des Champs',
        content:
            'Règles de validation pour chaque champ :',
        steps: [
          'Nom de l\'établissement : REQUIS, ne peut pas être vide',
          'Adresse : REQUIS, ne peut pas être vide',
          'Téléphone : REQUIS, format numérique',
          'Email : REQUIS, doit être une adresse email valide (ex: hotel@example.com)',
          'Heures check-in/out : REQUIS, format HH:MM',
          'Pourcentage d\'acompte : Nombre entre 0 et 100',
          'Nom/Adresse/Téléphone restaurant : OPTIONNELS',
          'Si un champ est invalide, un message d\'erreur rouge s\'affiche en dessous',
        ],
      ),

      // Section 11 : Impact des paramètres
      HelpSection(
        title: '📄 Impact sur les Documents',
        content:
            'Où apparaissent vos paramètres dans l\'application :',
        steps: [
          'NOM & ADRESSE : Sur toutes les factures, reçus, tickets de réservation',
          'EMAIL & TÉLÉPHONE : Contact client sur les documents et emails automatiques',
          'INFO RESTAURANT : Sur les tickets de caisse du restaurant uniquement',
          'HEURES CHECK-IN/OUT : Affichées sur les confirmations de réservation',
          'POURCENTAGE ACOMPTE : Calculé automatiquement lors des réservations',
          'TYPES DE CHAMBRE : Liste déroulante lors de la création de chambres',
          'Modification = Impact immédiat sur tous les nouveaux documents',
        ],
      ),

      // Section 12 : Conseils et bonnes pratiques
      HelpSection(
        title: '💡 Conseils et Bonnes Pratiques',
        content:
            'Recommandations pour une configuration optimale :',
        steps: [
          'Vérifiez l\'exactitude des informations avant de sauvegarder',
          'Utilisez une adresse email professionnelle (évitez Gmail/Yahoo)',
          'Format téléphone international : +225 XX XX XX XX XX (Côte d\'Ivoire)',
          'Heures check-in/out : Respectez les standards hôteliers (14h/11h)',
          'Acompte : 30% est le standard, ajustez selon votre politique',
          'Types de chambre : Noms clairs et descriptifs',
          'Informations restaurant : Remplissez si vous avez un restaurant séparé',
          'Mettez à jour régulièrement si vos coordonnées changent',
        ],
      ),

      // Section 13 : Paramètres avancés via Packages
      HelpSection(
        title: '🔧 Configuration Avancée des Packages',
        content:
            'Détails sur la gestion des packages et options :',
        steps: [
          'Accédez via "Gérer les Options & Packages"',
          'Deux types : INCLUS (gratuit pour le client) et PAYANT (à vendre)',
          'Options INCLUSES : Petit-déjeuner, WiFi, parking inclus dans le prix chambre',
          'Options PAYANTES : Services supplémentaires vendus via la Boutique d\'Options',
          'Pour chaque package : Nom, Description, Catégorie, Icône',
          'Tarification flexible : Prix par heure, jour, semaine, mois',
          'Activez/désactivez selon disponibilité saisonnière',
          'Les packages apparaissent lors du check-in et dans la boutique',
        ],
      ),

      // Section 14 : Sécurité des données
      HelpSection(
        title: '🔐 Sécurité et Confidentialité',
        content:
            'Protection de vos paramètres et données :',
        steps: [
          'Tous les paramètres sont stockés dans Firebase (Cloud sécurisé)',
          'Chiffrement des données en transit et au repos',
          'Seuls les utilisateurs Manager peuvent modifier les paramètres',
          'Historique des modifications conservé pour audit',
          'Sauvegarde automatique toutes les 24h',
          'Restauration possible en cas d\'erreur de modification',
          'Conformité RGPD : Vos données vous appartiennent',
        ],
      ),

      // Section 15 : Dépannage
      HelpSection(
        title: '🔧 Dépannage',
        content:
            'Solutions aux problèmes courants :',
        steps: [
          'Erreur "Email invalide" : Vérifiez le format (doit contenir @)',
          'Erreur "Pourcentage invalide" : Entrez un nombre entre 0 et 100',
          'Paramètres non sauvegardés : Vérifiez tous les champs requis',
          'Bouton "Gérer Packages" inactif : Problème de connexion, actualisez',
          'Heures non sélectionnables : Cliquez sur l\'icône horloge, pas le champ',
          'Type de chambre non ajouté : Le champ est vide, tapez d\'abord le nom',
          'Modifications non visibles : Actualisez la page ou reconnectez-vous',
        ],
      ),

      // Section 16 : Chargement des paramètres
      HelpSection(
        title: '🔄 Chargement Automatique',
        content:
            'Comment vos paramètres sont chargés :',
        steps: [
          'À l\'ouverture de la page : Chargement automatique depuis Firebase',
          'Indicateur de chargement (roue tournante) pendant le téléchargement',
          'Tous les champs se remplissent avec vos valeurs actuelles',
          'Si première utilisation : Valeurs par défaut (FCFA, 30% acompte)',
          'En cas d\'erreur de chargement : Message d\'erreur affiché',
          'Vous pouvez réessayer en actualisant la page',
          'Le chargement prend généralement 1-2 secondes',
        ],
      ),

      // Section 17 : Intégration avec autres modules
      HelpSection(
        title: '🔗 Intégration dans GESTO',
        content:
            'Comment les paramètres interagissent avec les autres fonctionnalités :',
        steps: [
          'RÉSERVATIONS : Heures check-in/out et acompte appliqués automatiquement',
          'FINANCES : Devise utilisée pour tous les calculs et factures',
          'CHAMBRES : Types de chambre disponibles dans la gestion des chambres',
          'RESTAURANT : Informations restaurant sur tickets de caisse',
          'BOUTIQUE OPTIONS : Packages payants vendables aux clients',
          'CHECK-IN : Packages inclus proposés lors du check-in',
          'DOCUMENTS : Nom, adresse, contacts sur factures et reçus',
        ],
      ),

      // Section 18 : FAQ Paramètres
      HelpSection(
        title: '❓ FAQ Paramètres',
        content:
            'Questions fréquentes sur les paramètres :',
        steps: [
          'Q: Puis-je changer de devise ? R: Actuellement seul FCFA est supporté',
          'Q: Les modifications affectent-elles les anciennes réservations ? R: Non, seulement les nouvelles',
          'Q: Combien de types de chambre puis-je créer ? R: Illimité',
          'Q: Puis-je supprimer un type de chambre utilisé ? R: Oui, mais vérifiez d\'abord qu\'aucune chambre ne l\'utilise',
          'Q: Où apparaît le nom du restaurant ? R: Sur les tickets de caisse du restaurant uniquement',
          'Q: Puis-je avoir différents acomptes par type de chambre ? R: Non, c\'est global pour le moment',
          'Q: Les infos sont-elles sauvegardées si je ferme sans cliquer sur "Enregistrer" ? R: Non, pensez à sauvegarder',
        ],
      ),
    ],
  );
}

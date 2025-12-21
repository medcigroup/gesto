import 'package:flutter/material.dart';
import '../help_models.dart';

HelpCategory getRestaurantHelp() {
  return HelpCategory(
    title: 'Restaurant',
    icon: Icons.restaurant_rounded,
    sections: [
      HelpSection(
        title: 'Vue d\'ensemble du module restaurant',
        content: '''Le module Restaurant de Gesto transforme la gestion de votre service de restauration. Il permet de gérer les tables, prendre les commandes, suivre les préparations en cuisine et encaisser les paiements de manière fluide et efficace.

Architecture du système :

1. Gestion des tables :
Créez et organisez vos tables (numéros, capacités, zones). Suivez leur statut en temps réel (libre, occupée, réservée, en nettoyage).

2. Gestion du menu :
Créez votre carte complète avec catégories (entrées, plats, desserts, boissons), prix, descriptions, photos et gestion des stocks.

3. Prise de commande :
Interface intuitive pour saisir rapidement les commandes, avec notes spéciales (allergies, cuisson, modifications).

4. Cuisine (KDS - Kitchen Display System) :
Les commandes apparaissent automatiquement en cuisine sur un écran dédié. Les cuisiniers peuvent marquer les plats en cours et terminés.

5. Facturation et encaissement :
Génération automatique de l'addition avec calcul des taxes, répartition des paiements, pourboires.

Avantages :
✓ Réduction des erreurs de commande
✓ Accélération du service
✓ Meilleure communication cuisine-salle
✓ Traçabilité complète
✓ Statistiques de ventes par plat''',
        steps: [
          'Accédez au menu "Restaurant" depuis le tableau de bord principal',
          'Le dashboard restaurant s\'ouvre avec 4 onglets : Accueil, Tables, Commandes, Stats',
          'L\'onglet Accueil affiche le résumé : Nombre de tables libres/occupées/réservées, Commandes en cours, Revenus du jour',
          'Des cartes colorées facilitent la lecture rapide du statut global',
        ],
      ),
      HelpSection(
        title: 'Gestion des tables',
        content: '''La gestion des tables est la base de l'organisation de votre restaurant. Chaque table a un numéro unique, une capacité et un statut qui évolue en temps réel.

Organisation recommandée :
• Numérotez les tables de manière logique (zone par zone)
• Exemple : Tables 1-10 en terrasse, 11-20 en salle intérieure, 21-30 en VIP

Statuts des tables :

🟢 Libre (Vert) :
Table propre et prête à accueillir des clients. Peut être assignée immédiatement.

🔴 Occupée (Rouge) :
Table avec clients installés. Une ou plusieurs commandes sont associées.

🟡 Réservée (Jaune) :
Table réservée pour une heure précise. Ne peut pas être assignée à d'autres clients.

🟣 En nettoyage (Violet) :
Table en cours de nettoyage après le départ des clients. Bientôt disponible.

🔵 Hors service (Bleu) :
Table temporairement indisponible (problème matériel, zone fermée).

Vous pouvez combiner des tables pour les grands groupes (ex: tables 5+6 pour un groupe de 8 personnes).''',
        steps: [
          'Dans l\'onglet "Tables" du module Restaurant, vous voyez toutes vos tables',
          'Cliquez sur "Ajouter une table" pour créer une nouvelle table',
          'Remplissez : Numéro (unique), Capacité (nombre de couverts), Zone (terrasse, salle, VIP)',
          'La table apparaît immédiatement avec le statut "Libre"',
          'Pour modifier une table : Cliquez dessus puis "Modifier"',
          'Pour changer le statut : Cliquez sur la table et sélectionnez le nouveau statut',
          'Pour réserver une table : Cliquez dessus, "Réserver", indiquez nom du client et heure',
          'Pour assigner des clients : Cliquez sur "Occuper", entrez le nombre de personnes',
          'Le système vous alertera si vous essayez d\'assigner plus de personnes que la capacité',
        ],
      ),
      HelpSection(
        title: 'Prise de commande',
        content: '''La prise de commande digitale remplace le carnet papier traditionnel. Elle est plus rapide, plus précise et transmet instantanément la commande en cuisine. Fini les tickets illisibles ou les plats oubliés !

Processus de prise de commande :

1. Sélection de la table :
Choisissez la table concernée dans la vue plan de salle.

2. Ajout des plats :
Parcourez le menu par catégorie ou utilisez la recherche rapide. Cliquez sur chaque plat commandé. Ajustez les quantités avec les boutons +/-.

3. Personnalisation :
Pour chaque plat, vous pouvez ajouter :
• Cuisson (saignant, à point, bien cuit pour les viandes)
• Modifications (sans oignon, sauce à part, etc.)
• Allergies du client à noter
• Niveau de piment souhaité

4. Boissons :
Ajoutez les boissons commandées avec leurs tailles (25cl, 33cl, 50cl, 1L).

5. Notes spéciales :
Zone de texte libre pour toute instruction particulière.

6. Validation :
La commande part instantanément en cuisine et s'affiche sur l'écran KDS.''',
        steps: [
          'Dans l\'onglet "Commandes", cliquez sur "Nouvelle commande"',
          'Sélectionnez la table dans la liste ou sur le plan de salle',
          'Indiquez le nombre de couverts pour cette table',
          'Le menu s\'affiche, organisé par catégories',
          'Cliquez sur chaque plat/boisson commandé',
          'Ajustez la quantité si plusieurs fois le même plat (ex: 3 × Salade César)',
          'Cliquez sur "Options" si besoin de spécifier la cuisson ou modifications',
          'Saisissez les notes spéciales dans le champ dédié',
          'Vérifiez le récapitulatif de la commande affiché sur le côté',
          'Le total se calcule automatiquement',
          'Cliquez sur "Envoyer en cuisine" pour valider',
          'Un numéro de commande unique est généré',
          'La commande apparaît immédiatement sur l\'écran de la cuisine',
          'Le statut passe à "En préparation"',
        ],
      ),
    ],
  );
}

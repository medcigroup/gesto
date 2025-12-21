# 📋 Guide d'utilisation - Système de Support et Roadmap

## 🎯 Vue d'ensemble

Ce système intègre deux fonctionnalités majeures dans votre application Gesto :

1. **Support Client-Admin** : Communication bidirectionnelle entre clients et administrateurs
2. **Roadmap** : Feuille de route publique des fonctionnalités à venir

## 📱 Pages créées

### 1. Support Client (`SupportClientPage`)
**Emplacement** : Menu latéral > Support  
**Accessible par** : Tous les utilisateurs authentifiés

#### Fonctionnalités :
- ✅ Voir tous ses tickets de support
- ✅ Créer un nouveau ticket via un bottom sheet
- ✅ Filtrer par catégorie (Bug, Fonctionnalité, Question, Feedback, Autre)
- ✅ Définir la priorité (Urgente, Haute, Moyenne, Basse)
- ✅ Communiquer avec l'équipe support via messages
- ✅ Fermer un ticket résolu
- ✅ Voir l'historique complet des échanges

#### Utilisation :
```dart
// Créer un nouveau ticket
1. Cliquer sur le bouton flottant "Nouveau ticket"
2. Remplir le formulaire (sujet, description, catégorie, priorité)
3. Soumettre

// Répondre à un ticket
1. Cliquer sur un ticket dans la liste
2. Saisir le message dans la zone de texte
3. Envoyer
```

### 2. Support Admin (`SupportAdminPage`)
**Emplacement** : Menu latéral > Support Admin  
**Accessible par** : Administrateurs uniquement

#### Fonctionnalités :
- ✅ Voir tous les tickets de tous les utilisateurs
- ✅ Statistiques en temps réel (Total, Ouverts, En cours, Résolus, Fermés)
- ✅ Filtrer par statut via onglets
- ✅ Répondre aux tickets en tant qu'admin
- ✅ Modifier le statut (Ouvert, En cours, En attente, Résolu, Fermé)
- ✅ Modifier la priorité
- ✅ Assigner un ticket à un admin spécifique
- ✅ Supprimer un ticket

#### Utilisation :
```dart
// Gérer un ticket
1. Sélectionner l'onglet approprié (Ouverts, En cours, etc.)
2. Cliquer sur un ticket
3. Utiliser le menu (⋮) pour :
   - Changer le statut
   - Changer la priorité
   - Supprimer le ticket
4. Répondre directement dans la conversation
```

### 3. Roadmap (`RoadmapPage`)
**Emplacement** : Barre supérieure > Bouton "Roadmap"  
**Accessible par** : Tous (même visiteurs pour transparence)

#### Fonctionnalités :
- ✅ Voir toutes les fonctionnalités planifiées
- ✅ Filtrer par statut (Planifié, En cours, Terminé, Annulé)
- ✅ Voter pour les fonctionnalités souhaitées
- ✅ Voir les dates estimées de livraison
- ✅ Catégories et tags pour organiser
- ✅ Badge de priorité (Haute, Moyenne, Basse)

#### Utilisation :
```dart
// Voter pour une fonctionnalité
1. Accéder à la Roadmap via le bouton en haut
2. Cliquer sur le 👍 d'un élément
3. Le vote est enregistré instantanément

// Admin : Ajouter un élément (via console Firebase)
// Voir FIREBASE_SUPPORT_SETUP.md
```

## 🗂️ Structure des fichiers

```
lib/
├── models/
│   ├── support_ticket.dart       # Modèle de ticket de support
│   └── roadmap_item.dart         # Modèle d'élément de roadmap
├── services/
│   └── support_service.dart      # Service Firebase pour support & roadmap
├── Screens/
│   └── manager/
│       ├── support_client_page.dart   # Page support client
│       ├── support_admin_page.dart    # Page support admin
│       └── roadmap_page.dart          # Page roadmap
└── DashboardManager.dart         # Intégration dans le dashboard
```

## 🔥 Configuration Firebase

### Collections Firestore

#### `support_tickets`
```javascript
{
  userId: "user123",
  userEmail: "user@example.com",
  userName: "Jean Dupont",
  subject: "Problème de connexion",
  description: "Je n'arrive pas à me connecter...",
  category: "bug",                    // bug, feature, question, feedback, other
  priority: "high",                   // low, medium, high, urgent
  status: "open",                     // open, inProgress, waiting, resolved, closed
  createdAt: Timestamp,
  updatedAt: Timestamp,
  closedAt: Timestamp,
  assignedTo: "admin456",
  attachmentUrls: [],
  messages: [
    {
      id: "msg1",
      senderId: "user123",
      senderName: "Jean Dupont",
      senderEmail: "user@example.com",
      isAdmin: false,
      message: "Bonjour, j'ai besoin d'aide...",
      timestamp: Timestamp,
      attachmentUrls: []
    }
  ]
}
```

#### `roadmap`
```javascript
{
  title: "Intégration calendrier Google",
  description: "Synchronisation automatique avec Google Calendar",
  status: "inProgress",              // planned, inProgress, completed, cancelled
  priority: "high",                  // low, medium, high
  createdAt: Timestamp,
  estimatedDate: Timestamp,
  completedAt: Timestamp,
  category: "Intégrations",
  tags: ["calendrier", "google", "sync"],
  votesCount: 42,
  voters: ["user1", "user2", ...]
}
```

### Règles de sécurité

Voir le fichier `FIREBASE_SUPPORT_SETUP.md` pour :
- Les règles de sécurité complètes
- Les index composites requis
- La configuration des notifications
- Les scripts de migration

## 🎨 Personnalisation

### Couleurs et thèmes

Les pages s'adaptent automatiquement au thème clair/sombre de l'application.

```dart
// Couleurs des statuts de tickets
TicketStatus.open        → Bleu
TicketStatus.inProgress  → Orange
TicketStatus.waiting     → Violet
TicketStatus.resolved    → Vert
TicketStatus.closed      → Gris

// Couleurs des priorités
TicketPriority.urgent    → Rouge
TicketPriority.high      → Orange
TicketPriority.medium    → Jaune
TicketPriority.low       → Vert
```

### Modifier les catégories

Pour ajouter/modifier les catégories de tickets :

```dart
// Dans lib/models/support_ticket.dart
enum TicketCategory {
  bug,
  feature,
  question,
  feedback,
  other,
  // Ajoutez vos catégories ici
  billing,
  technical,
}
```

## 📊 Analytics et Statistiques

### Côté Admin

La page admin affiche en temps réel :
- Nombre total de tickets
- Tickets ouverts
- Tickets en cours de traitement
- Tickets résolus
- Tickets fermés

```dart
// Obtenir les statistiques
final stats = await supportService.getTicketStatistics();
print('Total: ${stats['total']}');
print('Ouverts: ${stats['open']}');
```

## 🔔 Notifications (Optionnel)

Pour activer les notifications push :

1. Configurer Firebase Cloud Messaging (FCM)
2. Déployer les Cloud Functions (voir `FIREBASE_SUPPORT_SETUP.md`)
3. Les admins reçoivent une notification pour chaque nouveau ticket
4. Les utilisateurs sont notifiés des réponses admin

## 🧪 Tests

### Test du flux complet

1. **En tant qu'utilisateur** :
   ```
   ✓ Créer un ticket
   ✓ Envoyer un message
   ✓ Recevoir une réponse
   ✓ Fermer le ticket
   ```

2. **En tant qu'admin** :
   ```
   ✓ Voir tous les tickets
   ✓ Répondre à un ticket
   ✓ Changer le statut
   ✓ Modifier la priorité
   ✓ Supprimer un ticket
   ```

3. **Roadmap** :
   ```
   ✓ Voir la roadmap
   ✓ Voter pour un élément
   ✓ Filtrer par statut
   ```

## 🚀 Déploiement

### Checklist avant déploiement

- [ ] Configurer les règles de sécurité Firestore
- [ ] Créer les index composites
- [ ] Tester les permissions (user vs admin)
- [ ] Vérifier la gestion des erreurs
- [ ] Tester sur différents rôles utilisateurs
- [ ] Configurer les notifications (optionnel)
- [ ] Documenter pour l'équipe

### Commandes

```bash
# Publier les règles Firestore
firebase deploy --only firestore:rules

# Publier les index
firebase deploy --only firestore:indexes

# Publier les Cloud Functions (si configurées)
firebase deploy --only functions
```

## 🛠️ Maintenance

### Nettoyage des données

Créez une tâche planifiée pour :
- Archiver les tickets fermés > 6 mois
- Supprimer les anciens éléments de roadmap
- Nettoyer les pièces jointes orphelines

```dart
// Exemple de fonction de nettoyage
Future<void> cleanupOldTickets() async {
  final sixMonthsAgo = DateTime.now().subtract(Duration(days: 180));
  
  final oldTickets = await FirebaseFirestore.instance
    .collection('support_tickets')
    .where('status', isEqualTo: 'closed')
    .where('closedAt', isLessThan: Timestamp.fromDate(sixMonthsAgo))
    .get();
  
  for (var doc in oldTickets.docs) {
    await doc.reference.delete();
  }
}
```

## 📞 Support

Pour toute question sur cette implémentation :
- Consultez `FIREBASE_SUPPORT_SETUP.md` pour la configuration Firebase
- Vérifiez les logs console avec les préfixes `[SUPPORT]` et `[ROADMAP]`
- Testez avec différents rôles utilisateurs

## 🎯 Prochaines améliorations possibles

- [ ] Pièces jointes (images, fichiers)
- [ ] Recherche avancée de tickets
- [ ] Export de rapports
- [ ] Réponses automatiques (chatbot)
- [ ] Satisfaction client (ratings)
- [ ] SLA (temps de réponse)
- [ ] Intégration email
- [ ] Support multi-langue
- [ ] Tableau de bord analytics avancé
- [ ] Gestion des équipes de support

---

**Version** : 1.0.0  
**Dernière mise à jour** : 17 décembre 2025

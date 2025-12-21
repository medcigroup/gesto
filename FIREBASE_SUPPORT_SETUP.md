# Configuration Firebase - Support et Roadmap

## Collections Firestore

### 1. Collection `support_tickets`
Stocke tous les tickets de support créés par les utilisateurs.

**Structure:**
```
support_tickets/
  {ticketId}/
    - userId: string
    - userEmail: string
    - userName: string
    - subject: string
    - description: string
    - category: string (bug, feature, question, feedback, other)
    - priority: string (low, medium, high, urgent)
    - status: string (open, inProgress, waiting, resolved, closed)
    - createdAt: timestamp
    - updatedAt: timestamp (nullable)
    - closedAt: timestamp (nullable)
    - assignedTo: string (nullable)
    - attachmentUrls: array<string>
    - messages: array<object>
      - id: string
      - senderId: string
      - senderName: string
      - senderEmail: string
      - isAdmin: boolean
      - message: string
      - timestamp: timestamp
      - attachmentUrls: array<string>
```

### 2. Collection `roadmap`
Stocke les éléments de la feuille de route publique.

**Structure:**
```
roadmap/
  {itemId}/
    - title: string
    - description: string
    - status: string (planned, inProgress, completed, cancelled)
    - priority: string (low, medium, high)
    - createdAt: timestamp
    - estimatedDate: timestamp (nullable)
    - completedAt: timestamp (nullable)
    - category: string
    - tags: array<string>
    - votesCount: number
    - voters: array<string> (liste des userId qui ont voté)
```

## Règles de sécurité Firestore

Ajoutez ces règles à votre fichier `firestore.rules` :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Support Tickets
    match /support_tickets/{ticketId} {
      // Fonction helper pour vérifier si l'utilisateur est admin
      function isAdmin() {
        return request.auth != null && 
               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['superadmin', 'manager'];
      }
      
      // Fonction pour vérifier si c'est le propriétaire du ticket
      function isOwner() {
        return request.auth != null && 
               resource.data.userId == request.auth.uid;
      }
      
      // Lecture : propriétaire ou admin
      allow read: if request.auth != null && (isOwner() || isAdmin());
      
      // Création : utilisateur authentifié
      allow create: if request.auth != null && 
                      request.resource.data.userId == request.auth.uid;
      
      // Mise à jour : propriétaire (pour messages) ou admin (pour tout)
      allow update: if request.auth != null && (
        // L'utilisateur peut ajouter des messages à son propre ticket
        (isOwner() && 
         request.resource.data.diff(resource.data).affectedKeys().hasOnly(['messages', 'updatedAt'])) ||
        // L'admin peut tout modifier
        isAdmin()
      );
      
      // Suppression : seulement admin
      allow delete: if isAdmin();
    }
    
    // Roadmap
    match /roadmap/{itemId} {
      // Fonction helper pour vérifier si l'utilisateur est admin
      function isAdmin() {
        return request.auth != null && 
               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['superadmin', 'manager'];
      }
      
      // Lecture : tout le monde (même non authentifié pour la transparence)
      allow read: if true;
      
      // Création : seulement admin
      allow create: if isAdmin();
      
      // Mise à jour : 
      // - Admin peut tout modifier
      // - Utilisateurs authentifiés peuvent voter
      allow update: if request.auth != null && (
        isAdmin() ||
        // Utilisateur peut seulement ajouter/retirer son vote
        (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['voters', 'votesCount']) &&
         request.auth.uid in request.resource.data.voters || 
         request.auth.uid in resource.data.voters)
      );
      
      // Suppression : seulement admin
      allow delete: if isAdmin();
    }
  }
}
```

## Index Firestore requis

Pour optimiser les performances, créez les index composites suivants dans Firestore :

### Collection `support_tickets`

1. **Index pour getUserTickets (tri par date)**
   - Collection: `support_tickets`
   - Champs indexés:
     - `userId` (Ascendant)
     - `createdAt` (Descendant)

2. **Index pour getTicketsByStatus**
   - Collection: `support_tickets`
   - Champs indexés:
     - `status` (Ascendant)
     - `createdAt` (Descendant)

### Collection `roadmap`

1. **Index pour getRoadmapItems (tri par priorité et date)**
   - Collection: `roadmap`
   - Champs indexés:
     - `priority` (Descendant)
     - `createdAt` (Descendant)

2. **Index pour getRoadmapItemsByStatus**
   - Collection: `roadmap`
   - Champs indexés:
     - `status` (Ascendant)
     - `priority` (Descendant)

## Configuration dans Firebase Console

1. **Créer les index composites** :
   - Allez dans Firebase Console > Firestore Database > Index
   - Cliquez sur "Create Index"
   - Ajoutez les index listés ci-dessus

2. **Appliquer les règles de sécurité** :
   - Allez dans Firebase Console > Firestore Database > Rules
   - Copiez-collez les règles ci-dessus
   - Publiez les modifications

## Notifications (optionnel)

Pour notifier les admins lors de nouveaux tickets, vous pouvez configurer des Cloud Functions :

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Notifier les admins lors d'un nouveau ticket
exports.onNewTicket = functions.firestore
  .document('support_tickets/{ticketId}')
  .onCreate(async (snap, context) => {
    const ticket = snap.data();
    
    // Récupérer tous les admins
    const adminsSnapshot = await admin.firestore()
      .collection('users')
      .where('role', 'in', ['superadmin', 'manager'])
      .get();
    
    const tokens = [];
    adminsSnapshot.forEach(doc => {
      if (doc.data().fcmToken) {
        tokens.push(doc.data().fcmToken);
      }
    });
    
    // Envoyer la notification
    if (tokens.length > 0) {
      const message = {
        notification: {
          title: 'Nouveau ticket de support',
          body: `${ticket.userName}: ${ticket.subject}`
        },
        tokens: tokens
      };
      
      await admin.messaging().sendMulticast(message);
    }
  });

// Notifier l'utilisateur lors d'une réponse admin
exports.onAdminReply = functions.firestore
  .document('support_tickets/{ticketId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    
    // Vérifier si un nouveau message a été ajouté
    if (after.messages.length > before.messages.length) {
      const lastMessage = after.messages[after.messages.length - 1];
      
      // Si c'est un message admin
      if (lastMessage.isAdmin) {
        // Récupérer le token FCM de l'utilisateur
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(after.userId)
          .get();
        
        if (userDoc.exists && userDoc.data().fcmToken) {
          const message = {
            notification: {
              title: 'Réponse à votre ticket',
              body: lastMessage.message.substring(0, 100)
            },
            token: userDoc.data().fcmToken
          };
          
          await admin.messaging().send(message);
        }
      }
    }
  });
```

## Migration des données existantes (si nécessaire)

Si vous avez déjà des données à migrer, utilisez ce script :

```dart
// migration_script.dart
Future<void> migrateData() async {
  final firestore = FirebaseFirestore.instance;
  
  // Exemple : migrer des anciens tickets vers la nouvelle structure
  final oldTickets = await firestore.collection('old_tickets').get();
  
  for (var doc in oldTickets.docs) {
    final oldData = doc.data();
    
    final newTicket = SupportTicket(
      id: doc.id,
      userId: oldData['user_id'] ?? '',
      userEmail: oldData['email'] ?? '',
      userName: oldData['name'] ?? '',
      subject: oldData['title'] ?? '',
      description: oldData['content'] ?? '',
      category: TicketCategory.question,
      priority: TicketPriority.medium,
      status: TicketStatus.open,
      createdAt: (oldData['created'] as Timestamp).toDate(),
      messages: [],
    );
    
    await firestore
      .collection('support_tickets')
      .doc(doc.id)
      .set(newTicket.toFirestore());
  }
  
  print('Migration terminée !');
}
```

## Tests

Pour tester le système :

1. **Test côté client** :
   - Créer un nouveau ticket
   - Ajouter des messages
   - Vérifier les notifications

2. **Test côté admin** :
   - Voir tous les tickets
   - Répondre à un ticket
   - Changer le statut et la priorité
   - Assigner un ticket

3. **Test Roadmap** :
   - Voir la roadmap
   - Voter pour un élément
   - (Admin) Ajouter/modifier des éléments

## Maintenance

- Nettoyez régulièrement les tickets fermés de plus de 6 mois
- Archivez les anciens éléments de roadmap complétés
- Surveillez les quotas Firestore et les performances

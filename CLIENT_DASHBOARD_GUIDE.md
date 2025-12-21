# Guide Dashboard Client

## Vue d'ensemble

Le système client permet aux visiteurs de :
- Créer un compte client
- Se connecter à un espace personnel
- Rechercher et réserver des chambres
- Gérer leurs réservations

## Structure

### 1. Fichiers principaux

- **ClientDashboard.dart** : Interface principale client avec 3 onglets
- **PublicHotelPage.dart** : Page publique avec système de connexion/inscription
- **routes.dart** : Configuration du routing incluant `/client-dashboard`
- **main.dart** : Gestion de l'authentification avec détection du type d'utilisateur

### 2. Collections Firestore

#### Collection `clients`
```
{
  userId: string,
  fullName: string,
  email: string,
  phone: string,
  hotelSlug: string (optionnel),
  createdAt: Timestamp
}
```

#### Collection `bookings`
```
{
  clientId: string,
  clientName: string,
  clientEmail: string,
  clientPhone: string,
  hotelSlug: string,
  roomId: string,
  roomName: string,
  checkInDate: Timestamp,
  checkOutDate: Timestamp,
  numberOfNights: number,
  numberOfGuests: number,
  totalPrice: number,
  status: 'pending' | 'confirmed' | 'cancelled',
  createdAt: Timestamp
}
```

### 3. Onglets du Dashboard Client

#### Onglet 1 : Nouvelle Réservation
- Instructions pour réserver
- Bouton "Rechercher des hôtels" (redirection vers page d'accueil)
- Design moderne avec gradient et icônes

#### Onglet 2 : Mes Réservations
- Liste en temps réel des réservations (StreamBuilder)
- Affichage du statut (confirmée, en attente, annulée)
- Informations : dates, nombre de nuits, prix total
- Option d'annulation pour réservations en attente

#### Onglet 3 : Mon Profil
- Informations personnelles (nom, email, téléphone)
- Date d'inscription
- Bouton de modification (en développement)

## Flux d'utilisation

### Inscription Client

1. Visiteur clique sur "Espace Client" dans l'AppBar de la page publique
2. Sélectionne "Créer un compte"
3. Remplit le formulaire (nom, email, téléphone, mot de passe)
4. Compte créé dans Firebase Auth + données dans Firestore `/clients`
5. **Redirection automatique vers `/client-dashboard`**

### Connexion Client

1. Visiteur clique sur "Espace Client" > "Se connecter"
2. Entre email et mot de passe
3. Authentification Firebase
4. **Redirection automatique vers `/client-dashboard`**

### Persistance de session

Au démarrage de l'app :
1. `main.dart/AuthenticationGate` vérifie l'état d'authentification
2. Si utilisateur connecté → `AuthChecker` analyse le type :
   - Collection `clients` existe → **Client** → `ClientDashboard`
   - Collection `staff` existe → **Employé** → `EmployeeDashboard`
   - Collection `users` existe → **Gérant** → `DashboardManager`
3. Si non connecté → `GestoLandingPage`

### Réservation

1. Client authentifié va sur la page publique d'un hôtel
2. Clique sur "Réserver Maintenant"
3. Remplit le formulaire de recherche :
   - Dates d'arrivée et départ
   - Nombre de personnes
4. Le système filtre les chambres disponibles
5. Client sélectionne une chambre
6. Confirmation → Enregistrement dans `/bookings`

## Routes

- **Page publique** : `/hotel/{slug}` (accessible sans connexion)
- **Dashboard client** : `/client-dashboard` (authentification requise)
- **Page d'accueil** : `/home`

## Fonctionnalités à venir

- [ ] Modification du profil client
- [ ] Annulation de réservation avec confirmation
- [ ] Paiement en ligne (Stripe/PayPal)
- [ ] Notifications email de confirmation
- [ ] Vérification disponibilité temps réel
- [ ] Page détails de réservation
- [ ] Historique complet avec filtres
- [ ] Programme de fidélité

## Sécurité

- Authentification Firebase (email/password)
- Règles Firestore à configurer :
  ```javascript
  // clients : lecture/écriture uniquement pour l'utilisateur concerné
  match /clients/{userId} {
    allow read, write: if request.auth.uid == userId;
  }
  
  // bookings : lecture pour le client concerné
  match /bookings/{bookingId} {
    allow read: if request.auth.uid == resource.data.clientId;
    allow create: if request.auth != null;
  }
  ```

## Design

- **Palette de couleurs** :
  - Primaire : `#1A237E` (bleu indigo)
  - Secondaire : `#FFD700` (doré)
  - Succès : Vert
  - En attente : Orange
  - Annulé : Rouge

- **Composants** :
  - Material Design 3
  - Cards avec élévation
  - Gradients pour sections importantes
  - Icônes Material Icons

## Tests recommandés

1. ✅ Inscription nouveau client
2. ✅ Connexion client existant
3. ✅ Persistance session (fermer/rouvrir app)
4. ✅ Navigation entre onglets
5. ✅ Affichage réservations en temps réel
6. ⏳ Recherche et réservation chambre
7. ⏳ Annulation réservation
8. ⏳ Déconnexion client

## Notes techniques

- **Provider** : Pas de state management nécessaire (StreamBuilder pour temps réel)
- **Navigation** : `pushReplacementNamed` après login/register
- **Responsive** : Optimisé mobile (TabBarView)
- **Performance** : StreamBuilder avec limitation `.orderBy('createdAt', descending: true)`

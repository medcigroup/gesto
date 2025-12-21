# Guide d'utilisation - Boutique d'Options Hôtel

## Vue d'ensemble

Le système de vente d'options payantes permet aux hôtels de proposer des services supplémentaires à leurs clients, qu'ils soient enregistrés dans le système de booking ou des clients externes.

## Fichiers créés

1. **HotelOptionsStorePage.dart** - Page principale de vente d'options
2. **OptionPurchase.dart** - Modèle de données pour les achats
3. **TicketGeneratorService.dart** - Service de génération de tickets au format 80x80mm

## Fonctionnalités principales

### 1. Interface utilisateur moderne
- **Grille d'options** avec filtres par catégorie
- **Panier en temps réel** affichant la sélection
- **Sélection de période** (heure, jour, semaine, mois) pour chaque option
- **Contrôle de quantité** pour chaque option
- **Formulaire client** pour les clients externes
- **Calcul automatique** du total selon période et quantité

### 2. Génération de tickets
- Format **80x80mm** (standard pour imprimantes thermiques)
- Code-barres pour traçabilité
- Impression directe
- Partage par email/WhatsApp
- Aperçu avant impression

### 3. Types de clients supportés

#### Client enregistré (booking)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HotelOptionsStorePage(
      hotelId: 'hotel_id_123',
      bookingId: 'booking_id_456',
      customerName: 'Jean Dupont',
      customerEmail: 'jean@example.com',
      customerPhone: '+225 01 02 03 04 05',
      roomNumber: '205',
    ),
  ),
);
```

#### Client externe
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HotelOptionsStorePage(
      hotelId: 'hotel_id_123',
      // Pas de bookingId = client externe
      // Le formulaire apparaîtra automatiquement
    ),
  ),
);
```

## Utilisation depuis un Dashboard

### Exemple 1 : Bouton dans le Dashboard Manager

```dart
// Dans ManagerDashboard.dart ou EmployeeDashboard.dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelOptionsStorePage(
          hotelId: currentHotelId, // Votre ID d'hôtel
        ),
      ),
    );
  },
  icon: Icon(Icons.store),
  label: Text('Boutique d\'options'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.purple,
    foregroundColor: Colors.white,
  ),
)
```

### Exemple 2 : Depuis une page de check-in

```dart
// Lors du check-in, proposer les options
TextButton.icon(
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelOptionsStorePage(
          hotelId: hotelId,
          bookingId: bookingId,
          customerName: customerName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          roomNumber: roomNumber,
        ),
      ),
    );
    
    // result contient les informations de l'achat si effectué
    if (result != null) {
      print('Achat effectué : ${result['totalAmount']} FCFA');
    }
  },
  icon: Icon(Icons.add_shopping_cart),
  label: Text('Ajouter des options'),
)
```

### Exemple 3 : Page publique pour clients externes

```dart
// Dans GestoLandingPage.dart ou une page web publique
Card(
  child: ListTile(
    leading: Icon(Icons.storefront, color: Colors.purple),
    title: Text('Boutique d\'options'),
    subtitle: Text('Découvrez nos services supplémentaires'),
    trailing: Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HotelOptionsStorePage(
            // Pas de paramètres = client complètement externe
            // Le système demandera toutes les infos
          ),
        ),
      );
    },
  ),
)
```

## Structure de données Firestore

### Collection : `option_purchases`

```javascript
{
  "id": "auto-generated",
  "hotelId": "hotel_id_123",
  "bookingId": "booking_id_456", // null si client externe
  "customerName": "Jean Dupont",
  "customerEmail": "jean@example.com",
  "customerPhone": "+225 01 02 03 04 05",
  "roomNumber": "205", // optionnel
  "purchasedOptions": [
    {
      "id": "option_id_1",
      "name": "Petit-déjeuner continental",
      "description": "Buffet complet de 7h à 10h",
      "icon": "restaurant",
      "category": "breakfast",
      "period": "day", // 'hour', 'day', 'week', 'month'
      "quantity": 3,
      "unitPrice": 5000,
      "subtotal": 15000
    }
  ],
  "totalAmount": 15000,
  "paymentMethod": "Espèces",
  "purchaseDate": "2025-12-21T10:30:00Z",
  "status": "paid"
}
```

## Gestion des périodes de tarification

Le système supporte 4 types de périodes de tarification :

### Périodes disponibles
- **Heure** (`hour`) - Pour services courts (spa, massage, etc.)
- **Jour** (`day`) - Pour services journaliers (petit-déjeuner, piscine, etc.)
- **Semaine** (`week`) - Pour forfaits hebdomadaires
- **Mois** (`month`) - Pour abonnements mensuels

### Fonctionnement
1. Chaque option peut avoir un ou plusieurs tarifs définis
2. L'utilisateur sélectionne l'option puis choisit la période désirée
3. Il peut ajuster la quantité (nombre d'heures, jours, semaines ou mois)
4. Le système calcule automatiquement le sous-total : `prix unitaire × quantité`
5. Le total général est la somme de tous les sous-totaux

### Exemple d'utilisation
```dart
// Option avec plusieurs tarifs
HotelPackage(
  name: "Accès piscine",
  pricing: PackagePricing(
    pricePerHour: 2000,    // 2000 FCFA/heure
    pricePerDay: 5000,     // 5000 FCFA/jour
    pricePerWeek: 30000,   // 30000 FCFA/semaine
    pricePerMonth: null,   // Non disponible au mois
  ),
)

// Client sélectionne : 3 jours
// Calcul : 5000 × 3 = 15000 FCFA
```

## Format du ticket généré

Le ticket est au format **80mm de largeur** (standard pour imprimantes thermiques) et contient :

1. **En-tête** : Logo et nom de l'hôtel
2. **Informations de transaction** : N°, date, statut
3. **Informations client** : Nom, email, téléphone, chambre
4. **Liste des options** : Nom, description, prix
5. **Total** : Montant total et mode de paiement
6. **Code-barres** : Pour traçabilité
7. **Pied de page** : Message de remerciement

## Méthodes du TicketGeneratorService

### 1. Générer un ticket PDF

```dart
final purchase = OptionPurchase(...);
final pdfBytes = await TicketGeneratorService.generateOptionTicket(purchase);
```

### 2. Imprimer directement

```dart
await TicketGeneratorService.printTicket(pdfBytes);
```

### 3. Sauvegarder et partager

```dart
await TicketGeneratorService.saveAndShareTicket(pdfBytes, purchaseId);
```

### 4. Afficher l'aperçu

```dart
await TicketGeneratorService.showTicketPreview(context, pdfBytes);
```

### 5. Générer un ticket texte (pour imprimantes thermiques simples)

```dart
final textTicket = TicketGeneratorService.generateSimpleTextTicket(purchase);
print(textTicket);
// Envoi direct vers l'imprimante thermique via Bluetooth, USB, etc.
```

## Catégories d'options disponibles

- 🍽️ **Restauration** (breakfast) - Petit-déjeuner, room service, etc.
- 🏊 **Équipements** (amenities) - Piscine, gym, spa, etc.
- 🛎️ **Services** (services) - Concierge, blanchisserie, etc.
- 🚗 **Transport** (transport) - Navette aéroport, location voiture, etc.
- 💆 **Bien-être** (wellness) - Massage, soins, yoga, etc.

## Configuration des options

Les options sont gérées dans **HotelPackagesManagement.dart**. Pour créer une option payante :

1. Accéder à la gestion des packages
2. Créer un nouveau package
3. Sélectionner **"Payant"** (non inclus)
4. Définir les prix (par heure, jour, semaine, mois)
5. Choisir la catégorie appropriée
6. Sauvegarder

## Modes de paiement supportés

- Espèces
- Carte bancaire
- Mobile Money
- Virement

## Statuts d'achat

- **paid** : Payé et confirmé
- **pending** : En attente de paiement
- **cancelled** : Annulé

## Sécurité et validation

- ✅ Validation des formulaires côté client
- ✅ Génération d'ID uniques pour chaque transaction
- ✅ Timestamps automatiques
- ✅ Code-barres pour traçabilité
- ✅ Stockage sécurisé dans Firestore

## Responsive Design

La page s'adapte automatiquement :
- **Desktop** : Affichage en deux colonnes (options + panier)
- **Tablette** : Layout optimisé
- **Mobile** : Vue empilée verticale

## Prochaines améliorations possibles

1. **Notifications email** automatiques après achat
2. **Historique des achats** pour les clients
3. **Remises et promotions** sur les options
4. **Packages d'options** (bundle deals)
5. **Intégration paiement en ligne** (Stripe, PayPal)
6. **QR Code** pour accès rapide à la boutique
7. **Multi-langues** pour clients internationaux

## Support technique

Pour toute question ou problème :
- Consulter la documentation Firestore
- Vérifier les logs console pour les erreurs
- Tester avec des données de démonstration

## Licence

Propriété de GESTO - Système de gestion hôtelière

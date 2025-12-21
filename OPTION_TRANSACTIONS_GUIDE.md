# Guide - Transactions Financières pour les Achats d'Options

## Vue d'ensemble

Ce document explique comment les transactions financières sont créées et suivies lors de l'achat d'options hôtelières via la boutique d'options.

## Architecture du Système

### 1. Collections Firestore Impliquées

#### `option_purchases`
Stocke les détails complets de chaque achat d'option :
- Informations client (nom, email, téléphone, chambre)
- Liste des options achetées avec quantités et prix
- Montant total
- Méthode de paiement
- Date d'achat
- ID de réservation (si applicable)

#### `transactions`
Stocke les transactions financières pour la comptabilité de l'hôtel :
- **Type** : `option_purchase` (pour différencier des paiements de réservation)
- **customerId** : ID de l'hôtel (pour récupérer dans les finances)
- **Amount** : Montant total de l'achat
- **Description** : Liste des options achetées
- **Méthode de paiement** : Espèces, Carte bancaire, Mobile Money, etc.
- **optionPurchaseId** : Référence vers l'achat complet dans `option_purchases`

### 2. Flux de Création de Transaction

Lors de la validation d'un achat d'option dans `HotelOptionsStorePage.dart` :

```dart
// 1. Sauvegarder l'achat dans option_purchases
final docRef = await FirebaseFirestore.instance
    .collection('option_purchases')
    .add(purchase.toMap());

// 2. Créer la transaction financière
final transactionCode = await CodeGenerator.generateTransactionCode();
await FirebaseFirestore.instance.collection('transactions').add({
  'transactionCode': transactionCode,
  'bookingId': bookingId,
  'roomId': roomNumber != null ? 'Room-$roomNumber' : null,
  'customerId': hotelId, // ID de l'hôtel
  'customerName': customerName,
  'amount': _totalAmount,
  'date': Timestamp.now(),
  'type': 'option_purchase',
  'paymentMethod': _paymentMethod,
  'description': 'Achat d\'options: ${_selectedOptions.map((o) => o.name).join(', ')}',
  'optionPurchaseId': docRef.id,
  'createdAt': Timestamp.now(),
  'createdBy': hotelId,
});

// 3. Générer le ticket de vente
final ticketBytes = await TicketGeneratorService.generateOptionTicket(
  purchase.copyWith(id: docRef.id),
);
```

## Intégration avec les Finances

### Page des Finances (`FinancePage.dart`)

Les transactions d'achats d'options sont automatiquement incluses dans :

#### 1. **Liste des Transactions Récentes**
```dart
Future<List<Map<String, dynamic>>> getTransactionsForCurrentUser() async {
  final QuerySnapshot snapshot = await _firestore
      .collection('transactions')
      .where('customerId', isEqualTo: currentUser.uid)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .get();
  // Inclut automatiquement tous les types de transactions
}
```

#### 2. **Calcul des Revenus Journaliers**
```dart
Future<double> getTotalRevenueForDate(DateTime date) async {
  final QuerySnapshot snapshot = await _firestore
      .collection('transactions')
      .where('customerId', isEqualTo: currentUser.uid)
      .where('type', whereIn: ['payment', 'option_purchase'])
      .get();
  // Calcule le revenu total incluant les options
}
```

#### 3. **Répartition des Revenus par Type**
```dart
Future<Map<String, double>> getRevenueByType(DateTime date) async {
  // Calcule séparément les revenus des chambres et des options
  return {
    'rooms': roomRevenue,      // Revenus des réservations de chambres
    'options': optionRevenue,  // Revenus des achats d'options
  };
}
```

#### 4. **Graphique de Répartition**
Un graphique circulaire (Pie Chart) affiche visuellement :
- **Part verte** : Revenus des chambres (réservations)
- **Part rose** : Revenus des options (achats d'options)
- **Pourcentages** : Affichés directement sur le graphique
- **Détails** : Montants et pourcentages dans la légende

#### 5. **Affichage Visuel des Transactions**
Les transactions d'achats d'options sont affichées avec :
- **Icône distincte** : 🛍️ (shopping_bag_rounded)
- **Couleur spécifique** : Rose (#E91E63)
- **Label** : "Achat d'options"

## Types de Transactions

| Type | Description | Icône | Couleur |
|------|-------------|-------|---------|
| `payment` | Paiement de réservation | 💰 | Vert (#4CAF50) |
| `option_purchase` | Achat d'options | 🛍️ | Rose (#E91E63) |
| `discount` | Réduction appliquée | 🎫 | Violet (#9C27B0) |

## Détails de Transaction

Lorsqu'on clique sur une transaction d'achat d'option dans les finances, les informations suivantes sont affichées :

- **Montant** : Montant total de l'achat
- **Description** : Liste des options achetées
- **Mode de paiement** : Méthode utilisée
- **Client** : Nom du client
- **ID Réservation** : Si lié à une réservation
- **ID Chambre** : Si applicable
- **ID Achat Option** : Référence vers l'achat complet
- **Type de transaction** : "Achat d'options"

## Rapports Financiers

Les transactions d'achats d'options sont automatiquement incluses dans :

1. **Revenus journaliers** : Contribuent au total des revenus
2. **Rapports imprimés** : Apparaissent dans les bilans financiers
3. **Statistiques** : Comptabilisées dans les métriques (RevPAR, ADR, etc.)

## Avantages du Système

✅ **Traçabilité complète** : Chaque achat d'option est enregistré avec tous les détails

✅ **Comptabilité unifiée** : Tous les revenus (réservations + options) dans une seule vue

✅ **Rapports automatiques** : Les options sont incluses automatiquement dans tous les rapports

✅ **Différenciation visuelle** : Facile de distinguer les types de revenus

✅ **Référencement croisé** : Lien entre la transaction et l'achat détaillé

## Exemple de Flux Complet

1. **Client achète des options** :
   - Petit-déjeuner (2x) : 5000 FCFA
   - Spa (1x) : 15000 FCFA
   - **Total** : 20000 FCFA

2. **Système crée** :
   - Document dans `option_purchases` avec tous les détails
   - Transaction dans `transactions` avec `type: 'option_purchase'`
   - Ticket PDF généré

3. **Dans les finances** :
   - Transaction visible dans la liste récente avec icône 🛍️ rose
   - 20000 FCFA ajouté au revenu journalier
   - Inclus dans les rapports imprimables

4. **Historique** :
   - Accessible dans l'onglet "Historique" de la boutique d'options
   - Possibilité de réimprimer le ticket
   - Détails complets de l'achat conservés

## Structure de Données

### Transaction d'Achat d'Option
```javascript
{
  "transactionCode": "TRX-20250121-ABCD",
  "bookingId": "booking_xyz123" ou null,
  "roomId": "Room-101" ou null,
  "customerId": "hotel_uid", // ID de l'hôtel
  "customerName": "Jean Dupont",
  "amount": 20000,
  "date": Timestamp,
  "type": "option_purchase",
  "paymentMethod": "Espèces",
  "description": "Achat d'options: Petit-déjeuner, Spa",
  "optionPurchaseId": "opt_purchase_abc456",
  "createdAt": Timestamp,
  "createdBy": "hotel_uid"
}
```

## Fichiers Modifiés

1. **lib/Screens/client/HotelOptionsStorePage.dart** (lignes 486-502)
   - Création de la transaction lors de l'achat
   - Import de `generationcode.dart` pour les codes de transaction

2. **lib/Screens/manager/FinancePage.dart**
   - Lignes 17-44 : Récupération des transactions
   - Lignes 46-105 : Calcul des revenus totaux avec options
   - Lignes 107-159 : Nouvelle méthode `getRevenueByType()` pour calculer la répartition
   - Lignes 281-284 : Variables d'état pour les revenus par type
   - Lignes 698-990 : Widget graphique de répartition avec Pie Chart
   - Lignes 1071-1112 : Affichage des transactions avec icône spécifique
   - Lignes 1240-1278 : Détails de transaction avec type et icône

## Visualisation des Données

### Graphique de Répartition des Revenus

Le graphique circulaire affiche :

```
┌─────────────────────────────────────────┐
│  Répartition des revenus                │
│                                          │
│     ╭────╮          Revenus Chambres    │
│     │ 📊 │          ████████ 75.0%      │
│     ╰────╯          150,000 FCFA        │
│                                          │
│   [Graphique]       Revenus Options     │
│      Vert &         ████ 25.0%          │
│      Rose           50,000 FCFA         │
│                                          │
│                     ─────────────────    │
│                     Total: 200,000 FCFA │
└─────────────────────────────────────────┘
```

### Caractéristiques du Graphique

- **Responsive** : S'adapte aux différentes tailles d'écran
  - Desktop : Graphique à gauche, légende à droite
  - Mobile : Graphique en haut, légende en bas
- **Interactif** : Affiche les pourcentages directement sur le graphique
- **Informatif** : Légende détaillée avec montants et pourcentages
- **Visuel** : Couleurs distinctives pour chaque type de revenu

## Notes Importantes

⚠️ **customerId = hotelId** : Crucial pour que les transactions apparaissent dans les finances de l'hôtel

⚠️ **Type = 'option_purchase'** : Permet de différencier des paiements de réservation

⚠️ **optionPurchaseId** : Permet de retrouver les détails complets de l'achat

---

**Date de création** : 21 Janvier 2025
**Version** : 1.3.1

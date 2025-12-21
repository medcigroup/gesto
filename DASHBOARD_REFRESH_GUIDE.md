# Guide du système de rafraîchissement du Dashboard

## Vue d'ensemble

Le `DashboardManager` dispose d'un système de rafraîchissement intelligent qui permet de recharger automatiquement les pages lors de la navigation et de forcer un rafraîchissement manuel si nécessaire.

## Comment ça fonctionne

### 1. Rafraîchissement automatique lors de la navigation

Chaque fois que vous changez de page via `changeSelectedIndex()`, la page est automatiquement rafraîchie grâce au système de clés :

```dart
void changeSelectedIndex(int index) {
  setState(() {
    _selectedIndex = index;
  });
  _saveSelectedIndex(index);
  _refreshCurrentPage(); // ← Rafraîchissement automatique
}
```

### 2. Mécanisme de rafraîchissement

Le rafraîchissement fonctionne en générant une nouvelle `UniqueKey()` pour la page active :

```dart
void _refreshCurrentPage() {
  // Génère une nouvelle clé unique
  setState(() {
    _pageKeys[_selectedIndex] = UniqueKey();
  });

  // Force Flutter à reconstruire complètement le widget
  // Les StreamBuilders se reconnectent automatiquement à Firestore
}
```

### 3. Pages supportées avec logs personnalisés

Le système reconnaît intelligemment le type de page et affiche des logs appropriés :

| Page | Log de rafraîchissement |
|------|------------------------|
| Tableau de bord | 🏠 Dashboard rafraîchi avec nouvelle clé |
| Réservations | 📅 Réservations rafraîchies |
| Chambres | 🏨 État des chambres rafraîchi |
| Personnel / Administration | 👥 Liste du personnel rafraîchie |
| Finances | 💰 Données financières rafraîchies |
| Restaurant | 🍽️ Dashboard restaurant rafraîchi |
| Support / Support Admin | 💬 Support rafraîchi |
| Tâches | ✅ Tâches rafraîchies |
| Emplois du temps | 📆 Emplois du temps rafraîchis |

## Utilisation

### Depuis une page enfant

Si vous voulez rafraîchir le Dashboard depuis une page enfant (par exemple après une création/modification) :

```dart
// Exemple dans CheckInPage.dart
class CheckInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              // Faire une action (ex: créer un check-in)
              await createCheckIn();

              // Rafraîchir le Dashboard
              final dashboardState = context.findAncestorStateOfType<DashboardManagerState>();
              dashboardState?.refreshCurrentPage();
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
```

### Depuis un Provider

Si vous utilisez un Provider et voulez rafraîchir après une modification :

```dart
class ReservationProvider extends ChangeNotifier {
  Future<void> confirmReservation(String reservationId) async {
    // Confirmer la réservation dans Firestore
    await FirebaseFirestore.instance
        .collection('reservations')
        .doc(reservationId)
        .update({'status': 'confirmée'});

    // Notifier les listeners (si vous avez des StreamBuilders, pas besoin de rafraîchir)
    notifyListeners();

    // OU rafraîchir explicitement le Dashboard si nécessaire
    // (généralement pas nécessaire avec les Streams Firestore)
  }
}
```

### Avec GlobalKey (méthode alternative)

Si vous avez besoin d'accéder au Dashboard depuis n'importe où dans l'app :

```dart
// Dans main.dart
final GlobalKey<DashboardManagerState> dashboardKey = GlobalKey();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardManager(key: dashboardKey),
    );
  }
}

// Depuis n'importe où
dashboardKey.currentState?.refreshCurrentPage();
```

## Bonnes pratiques

### ✅ À faire

1. **Utiliser les Streams Firestore** : La plupart de vos pages utilisent déjà des `StreamBuilder`. Ils se rafraîchissent automatiquement, pas besoin d'appeler `refreshCurrentPage()` manuellement.

2. **Rafraîchir après des actions importantes** :
   - Après une création/modification/suppression
   - Après un changement de statut important
   - Après une synchronisation avec le backend

3. **Vérifier que le widget est monté** :
```dart
if (mounted) {
  dashboardState?.refreshCurrentPage();
}
```

### ❌ À éviter

1. **Ne pas rafraîchir en boucle** : Évitez de rafraîchir dans un `initState()` ou un build qui pourrait créer une boucle infinie.

2. **Ne pas rafraîchir si vous utilisez des Streams** : Les `StreamBuilder` se mettent à jour automatiquement quand Firestore change.

3. **Ne pas surcharger** : Le rafraîchissement reconstruit tout le widget. Ne l'appelez pas trop souvent.

## Système de filtrage des pages

Le Dashboard filtre automatiquement les pages selon :

### Rôle utilisateur

- **Admin** : Accès à toutes les pages
- **Autres rôles** : Accès à toutes les pages SAUF :
  - Administration
  - Support Admin
  - Roadmap Admin

### Licence

- **Licence expirée** : Uniquement 4 pages essentielles
  - Tableau de bord
  - Licences
  - Support
  - Paramètres

- **Licence active** : Accès selon le type de licence
  - Basic : Pages de base
  - Starter : + quelques fonctionnalités
  - Pro : + fonctionnalités avancées
  - Entreprise : Toutes les fonctionnalités + page publique

## Débogage

Pour déboguer le système de rafraîchissement, surveillez les logs dans la console :

```
[DASHBOARD] 📄 Changement vers page: Réservations
[DASHBOARD] 🔄 Rafraîchissement de la page: Réservations
[DASHBOARD] 📅 Réservations rafraîchies
```

Les emoji vous aident à identifier rapidement :
- 📄 = Changement de page
- 🔄 = Début du rafraîchissement
- 🏠📅🏨💰 etc. = Type de page rafraîchie

## Maintenance

### Ajouter une nouvelle page

1. Ajoutez la page à `_allPages` :
```dart
final List<Widget Function()> _allPages = [
  // ... pages existantes
  () => MaNouvellePageWidget(),
];
```

2. Ajoutez le titre à `_allPageTitles` :
```dart
final List<String> _allPageTitles = [
  // ... titres existants
  'Ma Nouvelle Page',
];
```

3. Ajoutez l'icône à `_allPageIcons` :
```dart
final List<IconData> _allPageIcons = [
  // ... icônes existantes
  Icons.new_releases_rounded,
];
```

4. (Optionnel) Ajoutez un case dans `_refreshCurrentPage()` pour un log personnalisé :
```dart
case 'Ma Nouvelle Page':
  print('[DASHBOARD] 🆕 Ma nouvelle page rafraîchie');
  break;
```

### Modifier le filtrage

Les constantes de filtrage sont dans `_initPagesBasedOnRoleAndLicense()` :

```dart
// Pages admin uniquement
const adminOnlyPages = ['Administration', 'Support Admin', 'Roadmap Admin'];

// Pages toujours accessibles même avec licence expirée
const essentialPages = ['Tableau de bord', 'Licences', 'Support', 'Paramètres'];
```

Pour ajouter une page réservée aux admins :
```dart
const adminOnlyPages = ['Administration', 'Support Admin', 'Roadmap Admin', 'Ma Page Admin'];
```

Pour ajouter une page essentielle (accessible même licence expirée) :
```dart
const essentialPages = ['Tableau de bord', 'Licences', 'Support', 'Paramètres', 'Ma Page Essentielle'];
```

## Exemples concrets

### Rafraîchir après création d'une réservation

```dart
// Dans ModernReservationPage.dart
Future<void> _createReservation() async {
  try {
    // Créer la réservation
    await FirebaseFirestore.instance.collection('reservations').add({
      'clientName': _clientNameController.text,
      'status': 'en attente',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Afficher un message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Réservation créée avec succès')),
    );

    // Rafraîchir le Dashboard (optionnel si vous utilisez des Streams)
    final dashboardState = context.findAncestorStateOfType<DashboardManagerState>();
    dashboardState?.refreshCurrentPage();

  } catch (e) {
    print('Erreur création réservation: $e');
  }
}
```

### Rafraîchir après changement de statut

```dart
// Dans OccupiedRoomsPage.dart
Future<void> _checkoutRoom(String roomId) async {
  try {
    // Libérer la chambre
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .update({'status': 'disponible'});

    // Le StreamBuilder va se mettre à jour automatiquement
    // Pas besoin de rafraîchir manuellement !

  } catch (e) {
    print('Erreur checkout: $e');
  }
}
```

## Questions fréquentes

**Q : Dois-je appeler `refreshCurrentPage()` après chaque modification Firestore ?**
R : Non ! Si vous utilisez des `StreamBuilder`, Firestore notifie automatiquement vos widgets des changements. Le rafraîchissement manuel n'est utile que pour les widgets qui ne sont pas connectés à un Stream.

**Q : Comment rafraîchir une page spécifique (pas la page actuelle) ?**
R : Vous ne pouvez pas. Le système rafraîchit uniquement la page active. Si vous devez rafraîchir une autre page, naviguez vers elle d'abord avec `changeSelectedIndex()`.

**Q : Le rafraîchissement efface-t-il les données de la page ?**
R : Oui, le widget est complètement reconstruit. C'est pourquoi vos données importantes doivent venir de Firestore (avec Streams) ou être sauvegardées dans un Provider/State Manager.

**Q : Puis-je désactiver le rafraîchissement automatique lors du changement de page ?**
R : Oui, commentez simplement l'appel à `_refreshCurrentPage()` dans `changeSelectedIndex()`. Mais ce n'est généralement pas recommandé.

---

**Dernière mise à jour** : 2025-12-21
**Version Gesto** : 1.3.1

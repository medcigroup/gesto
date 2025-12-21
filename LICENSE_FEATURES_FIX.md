# Correction du système de licences

## 🐛 Problèmes corrigés

### 1. Support manquant dans licence expirée
**Avant :**
```dart
if (_isExpired) {
  return ['Tableau de bord', 'Licences', 'Paramètres'].contains(pageTitle);
}
```

**Après :**
```dart
if (_isExpired) {
  return ['Tableau de bord', 'Licences', 'Support', 'Paramètres'].contains(pageTitle);
}
```

### 2. Pages réorganisées et complétées par licence

#### Basic (11 pages)
- Tableau de bord
- Enregistrement
- Passages
- Départ
- Chambres
- Paiements
- Personnel
- Finances
- Licences
- Paramètres
- Support

**Fonctionnalités de base pour une petite structure.**

#### Starter (14 pages = Basic + 3)
Toutes les pages Basic **PLUS :**
- ✅ **Réservations** (nouveau)
- ✅ **Tâches** (nouveau)
- ✅ **Emplois du temps** (nouveau)

**Pour gérer les réservations et planifier le personnel.**

#### Pro (15 pages = Starter + 1)
Toutes les pages Starter **PLUS :**
- ✅ **Restaurant** (nouveau)

**Pour les hôtels avec service de restauration.**

#### Entreprise (18 pages = Pro + 3)
Toutes les pages Pro **PLUS :**
- ✅ **Boutique d'options** (nouveau)
- ✅ **Administration** (nouveau, réservé aux admins)
- ✅ **Support Admin** (nouveau, réservé aux admins)
- ✅ **Roadmap Admin** (nouveau, réservé aux admins)

**Solution complète avec fonctionnalités avancées et page publique.**

## 📊 Comparaison avant/après

| Page | Basic | Starter | Pro | Entreprise | Status |
|------|-------|---------|-----|------------|--------|
| Tableau de bord | ✅ | ✅ | ✅ | ✅ | - |
| **Réservations** | ❌ | ✅ | ✅ | ✅ | **Ajouté à Starter** |
| Enregistrement | ✅ | ✅ | ✅ | ✅ | - |
| Passages | ✅ | ✅ | ✅ | ✅ | - |
| Départ | ✅ | ✅ | ✅ | ✅ | - |
| Chambres | ✅ | ✅ | ✅ | ✅ | - |
| Paiements | ✅ | ✅ | ✅ | ✅ | - |
| **Restaurant** | ❌ | ❌ | ✅ | ✅ | **Ajouté à Pro** |
| **Boutique d'options** | ❌ | ❌ | ❌ | ✅ | **Déjà OK** |
| **Tâches** | ❌ | ✅ | ✅ | ✅ | **Ajouté à Starter** |
| **Emplois du temps** | ❌ | ✅ | ✅ | ✅ | **Ajouté à Starter** |
| Personnel | ✅ | ✅ | ✅ | ✅ | - |
| Administration | ❌ | ❌ | ❌ | ✅ | - |
| Finances | ✅ | ✅ | ✅ | ✅ | - |
| Licences | ✅ | ✅ | ✅ | ✅ | - |
| Support | ✅ | ✅ | ✅ | ✅ | **Corrigé en licence expirée** |
| Support Admin | ❌ | ❌ | ❌ | ✅ | - |
| Roadmap Admin | ❌ | ❌ | ❌ | ✅ | - |
| Paramètres | ✅ | ✅ | ✅ | ✅ | - |

## 🧪 Comment tester

### Option 1 : Utiliser le widget de debug

1. Importez le widget de debug dans votre page de paramètres :

```dart
import 'package:votre_app/debug_license_checker.dart';

// Dans SettingsPage.dart, ajoutez un bouton
ElevatedButton(
  onPressed: () {
    final licenseManager = Provider.of<LicenseManager>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LicenseDebugChecker(licenseManager: licenseManager),
      ),
    );
  },
  child: Text('🔍 Debug - Vérifier ma licence'),
)
```

2. Lancez l'app et cliquez sur le bouton pour voir :
   - Votre type de licence actuel
   - Les pages accessibles
   - Les pages bloquées
   - La comparaison entre tous les types de licences

### Option 2 : Vérifier dans la console

Regardez les logs au démarrage :

```
[DASHBOARD] 👑 Administrateur : accès complet à toutes les pages
ou
[DASHBOARD] 📄 14 pages accessibles initialisées
[DASHBOARD] 📋 Pages disponibles: Tableau de bord, Réservations, ...
```

### Option 3 : Test manuel dans Firestore

1. Ouvrez Firebase Console
2. Allez dans Firestore Database
3. Collection `users` → votre document utilisateur
4. Vérifiez/modifiez les champs :
   - `licenceType`: "basic" | "starter" | "pro" | "entreprise"
   - `licenceExpiryDate`: Timestamp (optionnel)
   - `role`: "superadmin" | "manager" | "receptionist" | "employee" | "kitchen"

5. Rechargez l'application et vérifiez les pages affichées

## 🔧 Dépannage

### Problème : Je ne vois toujours pas certaines pages

**Solution 1 : Vérifiez votre licence dans Firestore**
```bash
# Dans la console Firebase
users/{votre_uid}
  - licenceType: "entreprise"  ← Vérifiez ce champ
  - role: "superadmin"          ← Vérifiez ce champ
```

**Solution 2 : Vérifiez que vous n'êtes pas en licence expirée**
```dart
// Dans la console de debug, cherchez :
[DASHBOARD] ⏰ Licence expirée, accès limité aux pages essentielles
```

**Solution 3 : Vérifiez votre rôle utilisateur**
Les pages `Administration`, `Support Admin` et `Roadmap Admin` sont réservées aux **superadmin** uniquement, même avec une licence Entreprise.

```dart
// Dans Firestore
role: "superadmin"  // ← Doit être exactement "superadmin" (en minuscules)
```

**Solution 4 : Forcez le rechargement de la licence**
```dart
// Dans votre code, forcez le rechargement
final licenseManager = Provider.of<LicenseManager>(context, listen: false);
await licenseManager.loadLicenseInfo();
```

### Problème : Erreur "Page non trouvée"

Vérifiez que le titre de la page dans `_allPageTitles` correspond **exactement** au titre dans `LicenseFeatures.pageAccess` :

```dart
// DashboardManager.dart
'Boutique d\'options',  // ← Apostrophe échappée

// LicenseFeatures.dart
'Boutique d\'options',  // ← Doit être identique
```

## 📝 Modifications de code nécessaires

### Fichiers modifiés
1. ✅ `lib/LicenseFeatures.dart` - Correction des pages accessibles
2. ✅ `lib/debug_license_checker.dart` - Widget de debug (nouveau)
3. ✅ `lib/DashboardManager.dart` - Déjà à jour avec le nouveau système de filtrage

### Aucune migration nécessaire
Les utilisateurs existants conservent leur licence actuelle. Les nouvelles pages apparaîtront automatiquement selon leur type de licence.

## 🎯 Recommandations

### Pour les tests
1. **Testez avec chaque type de licence** :
   - Créez 4 comptes test (Basic, Starter, Pro, Entreprise)
   - Vérifiez que chaque compte voit les bonnes pages

2. **Testez la licence expirée** :
   - Modifiez `licenceExpiryDate` dans le passé
   - Vérifiez que seules 4 pages sont accessibles

3. **Testez les rôles** :
   - Admin : toutes les pages
   - Manager/Receptionist/Employee : pages selon licence (sauf admin)

### Pour la production
1. **Documentez les différences** entre licences sur votre page de pricing
2. **Ajoutez un système d'upgrade** pour permettre aux utilisateurs de changer de licence
3. **Notifications** : Alertez les utilisateurs 7 jours avant l'expiration de leur licence

## 🚀 Prochaines étapes

1. **Tester le système** avec le widget de debug
2. **Vérifier dans Firestore** que vos licences sont correctement configurées
3. **Valider l'affichage** de toutes les pages selon chaque licence
4. **Supprimer le widget de debug** avant la mise en production (ou le masquer)

---

**Date de correction** : 2025-12-21
**Version Gesto** : 1.3.1

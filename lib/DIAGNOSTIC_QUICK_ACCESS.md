# 🔍 Accès rapide au diagnostic

## Problème
Vous avez une licence **Pro** et le rôle **manager**, mais vous ne voyez pas :
- ❌ Restaurant
- ❌ Tâches
- ❌ Emplois du temps
- ❌ Réservations

## Solution rapide - Ajouter le diagnostic à votre app

### Option 1 : Depuis n'importe quelle page (RECOMMANDÉ)

Ajoutez ce bouton temporairement dans **n'importe quelle page** :

```dart
import 'package:votre_app/diagnostic_complete.dart';

// Dans votre build() ou dans une AppBar action
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiagnosticCompletePage()),
    );
  },
  child: const Icon(Icons.bug_report),
  backgroundColor: Colors.red,
)
```

### Option 2 : Depuis le Dashboard (AppBar)

Dans `lib/DashboardManager.dart`, ajoutez dans les actions de l'AppBar (ligne ~645) :

```dart
// Après les autres IconButton, ajoutez :
if (!kReleaseMode) // Seulement en mode debug
  IconButton(
    icon: const Icon(Icons.bug_report),
    tooltip: 'Diagnostic',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DiagnosticCompletePage(),
        ),
      );
    },
  ),
```

N'oubliez pas d'ajouter les imports :
```dart
import 'diagnostic_complete.dart';
import 'package:flutter/foundation.dart'; // Pour kReleaseMode
```

### Option 3 : Route dédiée (pour un accès permanent)

Dans `lib/config/routes.dart`, ajoutez :

```dart
import '../diagnostic_complete.dart';

// Dans vos routes
static const String diagnostic = '/diagnostic';

// Dans onGenerateRoute ou routes
case AppRoutes.diagnostic:
  return MaterialPageRoute(builder: (_) => const DiagnosticCompletePage());
```

Puis accédez via : `Navigator.pushNamed(context, '/diagnostic');`

## Ce que le diagnostic va vous montrer

1. **Résumé rapide**
   - Type de licence actuel
   - Rôle utilisateur
   - Statut de la licence (active/expirée)

2. **Pages attendues vs réelles**
   - Liste des pages qui DEVRAIENT être visibles
   - Vérification si elles sont effectivement accessibles
   - Identification des pages bloquées à tort

3. **Vérifications détaillées**
   - ✅/❌ Licence configurée
   - ✅/❌ Licence active
   - ✅/❌ Rôle défini
   - ✅/❌ Chaque page problématique testée individuellement

4. **Solution automatique**
   - Bouton pour recharger la licence depuis Firestore
   - Suggestions de correction

## Causes probables de votre problème

### Cause 1 : Typo dans Firestore (TRÈS PROBABLE)
Le champ `licenceType` doit être exactement `"pro"` (en minuscules).

**Vérification :**
```
Firebase Console → Firestore → users → {votre-uid}
licenceType: "pro"  ← Vérifiez la casse (minuscules)
```

❌ **Valeurs INCORRECTES** :
- `"Pro"` (majuscule)
- `"PRO"` (tout en majuscule)
- `" pro "` (avec espaces)
- `"pro "` (espace à la fin)

✅ **Valeur CORRECTE** :
- `"pro"` (tout en minuscules, pas d'espace)

### Cause 2 : Rôle non défini ou incorrect
Le champ `role` doit être l'un de ces valeurs exactes :
- `"superadmin"` (accès complet)
- `"manager"` (accès selon licence)
- `"receptionist"` (accès selon licence)
- `"employee"` (accès selon licence)
- `"kitchen"` (accès selon licence)

### Cause 3 : Licence expirée
Si le champ `licenceExpiryDate` est dans le passé, vous n'aurez accès qu'à 4 pages essentielles.

### Cause 4 : Cache non actualisé
L'app n'a pas rechargé les données depuis Firestore.

## Actions immédiates

### Action 1 : Vérifier Firestore (5 min)

1. Ouvrez Firebase Console
2. Firestore Database → Collection `users`
3. Trouvez votre document (votre UID)
4. Vérifiez ces champs :

```
{
  "licenceType": "pro",                    ← Exactement comme ça
  "role": "manager",                       ← Exactement comme ça
  "licenceExpiryDate": Timestamp(2026...)  ← Date future (optionnel)
}
```

5. Si incorrect, cliquez sur le champ et modifiez
6. Redémarrez l'app

### Action 2 : Utiliser le diagnostic (2 min)

1. Ajoutez le bouton de diagnostic (Option 1 ci-dessus)
2. Lancez l'app
3. Cliquez sur le bouton diagnostic
4. Lisez les résultats
5. Cliquez sur "Recharger la licence" si disponible

### Action 3 : Vérifier les logs (1 min)

Cherchez dans la console au démarrage :

```
[DASHBOARD] 📋 Pages disponibles: ...
```

Combien de pages voyez-vous ? Pour Pro + Manager, vous devriez avoir **15 pages**.

## Résolution automatique

Le widget `DiagnosticCompletePage` inclut un bouton **"Recharger la licence depuis Firestore"** qui :
1. Force le rechargement des données Firestore
2. Actualise le LicenseManager
3. Rafraîchit l'affichage

## Après correction

Une fois le problème résolu :
1. ✅ Redémarrez l'application complètement
2. ✅ Vérifiez que toutes les pages s'affichent
3. ✅ Supprimez le bouton de diagnostic (ou laissez-le en mode debug)

## Structure attendue pour Licence Pro

Avec **Licence Pro + Rôle Manager**, vous devriez voir **15 pages** :

1. Tableau de bord ✅
2. Réservations ✅
3. Enregistrement ✅
4. Passages ✅
5. Départ ✅
6. Chambres ✅
7. Paiements ✅
8. Restaurant ✅ (spécifique Pro)
9. Tâches ✅
10. Emplois du temps ✅
11. Personnel ✅
12. Finances ✅
13. Licences ✅
14. Support ✅
15. Paramètres ✅

**Pages NON visibles** (normales pour Manager) :
- Administration (réservé superadmin + Entreprise)
- Support Admin (réservé superadmin + Entreprise)
- Roadmap Admin (réservé superadmin + Entreprise)
- Boutique d'options (réservé Entreprise uniquement)

## Support

Si le problème persiste après avoir tout vérifié :

1. Partagez les résultats du diagnostic
2. Partagez une capture d'écran de votre document Firestore (users/{uid})
3. Partagez les logs de la console au démarrage

---

**Fichiers de diagnostic créés :**
- `lib/diagnostic_complete.dart` - Page de diagnostic principal
- `lib/debug_user_info.dart` - Affiche les données Firestore
- `lib/debug_license_checker.dart` - Teste toutes les pages

**Dernière mise à jour** : 2025-12-21

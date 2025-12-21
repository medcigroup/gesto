# 🚨 SOLUTION IMMÉDIATE - Pages manquantes avec Licence Pro

## ✅ J'AI DÉJÀ AJOUTÉ LE BOUTON DIAGNOSTIC POUR VOUS !

Un bouton rouge 🐛 a été ajouté dans la barre supérieure de votre Dashboard.

## Étapes à suivre MAINTENANT :

### 1️⃣ Lancez votre application (1 min)

```bash
flutter run
```

### 2️⃣ Cliquez sur l'icône 🐛 rouge en haut à droite (30 sec)

L'icône bug (🐛) rouge se trouve dans la barre supérieure, à gauche des notifications.

### 3️⃣ Lisez le diagnostic (2 min)

Le diagnostic vous montrera :
- ✅ Votre licence actuelle (devrait être "PRO")
- ✅ Votre rôle (devrait être "MANAGER")
- ✅ Les pages qui DEVRAIENT être visibles
- ✅ Les pages BLOQUÉES à tort
- ✅ Le problème EXACT

### 4️⃣ Suivez les instructions du diagnostic (5 min)

Le diagnostic vous dira probablement une de ces choses :

#### Problème A : Typo dans Firestore (le plus probable)
```
❌ Votre licenceType est "Pro" au lieu de "pro"
```

**Solution :**
1. Ouvrez Firebase Console
2. Firestore → users → {votre-uid}
3. Modifiez `licenceType: "Pro"` → `licenceType: "pro"` (tout en minuscules)
4. Redémarrez l'app

#### Problème B : Rôle non défini
```
❌ Votre role n'est pas défini
```

**Solution :**
1. Firebase Console → Firestore → users → {votre-uid}
2. Ajoutez le champ `role: "manager"` (tout en minuscules)
3. Redémarrez l'app

#### Problème C : Licence expirée
```
❌ Votre licence a expiré le ...
```

**Solution :**
1. Firebase Console → Firestore → users → {votre-uid}
2. Modifiez `licenceExpiryDate` pour une date future
3. OU supprimez ce champ (pas d'expiration)
4. Redémarrez l'app

### 5️⃣ Cliquez sur "Recharger la licence" dans le diagnostic (5 sec)

Si le diagnostic affiche un bouton orange "Recharger la licence depuis Firestore", cliquez dessus.

### 6️⃣ Vérifiez que les pages s'affichent (10 sec)

Avec **Licence Pro + Rôle Manager**, vous devriez maintenant voir **15 pages** :

✅ Tableau de bord
✅ **Réservations** ← Devrait apparaître
✅ Enregistrement
✅ Passages
✅ Départ
✅ Chambres
✅ Paiements
✅ **Restaurant** ← Devrait apparaître
✅ **Tâches** ← Devrait apparaître
✅ **Emplois du temps** ← Devrait apparaître
✅ Personnel
✅ Finances
✅ Licences
✅ Support
✅ Paramètres

### 7️⃣ Une fois résolu, supprimez le bouton diagnostic (2 min)

Ouvrez `lib/DashboardManager.dart` et supprimez ces lignes (746-758) :

```dart
// SUPPRIMEZ CETTE SECTION ↓
// 🔍 BOUTON DIAGNOSTIC TEMPORAIRE - À SUPPRIMER APRÈS RÉSOLUTION DU PROBLÈME
IconButton(
  icon: const Icon(Icons.bug_report, color: Colors.red, size: 28),
  tooltip: '🔍 DIAGNOSTIC - Pourquoi mes pages ne s\'affichent pas ?',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DiagnosticCompletePage(),
      ),
    );
  },
),
// SUPPRIMEZ JUSQU'ICI ↑
```

Et supprimez l'import en haut du fichier (ligne 42) :

```dart
import 'diagnostic_complete.dart'; // 🔍 DIAGNOSTIC TEMPORAIRE ← SUPPRIMEZ CETTE LIGNE
```

---

## 📋 Checklist Firestore

Votre document utilisateur dans Firestore doit ressembler à ça :

```
Collection: users
Document ID: {votre-uid}
Champs:
  ✅ licenceType: "pro" (STRING, tout en minuscules)
  ✅ role: "manager" (STRING, tout en minuscules)
  ✅ licenceExpiryDate: Timestamp (2026-12-21...) OU absent
  ✅ name: "Votre Nom" (optionnel)
  ✅ email: "votre@email.com" (optionnel)
```

**Valeurs CORRECTES pour licenceType :**
- `"basic"` ✅
- `"starter"` ✅
- `"pro"` ✅ ← VOUS
- `"entreprise"` ✅

**Valeurs INCORRECTES (ne fonctionneront PAS) :**
- `"Pro"` ❌ (majuscule)
- `"PRO"` ❌ (tout en majuscule)
- `" pro"` ❌ (espace avant)
- `"pro "` ❌ (espace après)

**Valeurs CORRECTES pour role :**
- `"superadmin"` ✅
- `"manager"` ✅ ← VOUS
- `"receptionist"` ✅
- `"employee"` ✅
- `"kitchen"` ✅

---

## 🆘 Si le problème persiste

1. Partagez une capture d'écran du **diagnostic complet**
2. Partagez une capture d'écran de votre **document Firestore** (users/{uid})
3. Partagez les **logs de la console** au démarrage de l'app

Cherchez dans les logs :
```
[DASHBOARD] 📋 Pages disponibles: ...
[DASHBOARD] 👤 Rôle actuel: ...
```

---

## ⏱️ Temps total estimé : 10 minutes

✅ Lancer l'app : 1 min
✅ Ouvrir le diagnostic : 30 sec
✅ Identifier le problème : 2 min
✅ Corriger dans Firestore : 5 min
✅ Vérifier que ça marche : 10 sec
✅ Nettoyer le code : 2 min

**TOTAL : ~10 minutes**

---

**Date de création** : 2025-12-21
**Version Gesto** : 1.3.1

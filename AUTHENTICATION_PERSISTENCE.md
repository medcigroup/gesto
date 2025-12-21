# 🔐 Gestion de la Persistance d'Authentification

## ✅ Fonctionnalités Implémentées

### 1. **Persistance Locale (LOCAL)**
La session de l'utilisateur est maintenue même après fermeture du navigateur.

**Configuration** : [lib/main.dart](lib/main.dart#L28-L30)
```dart
await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
```

### 2. **Reconnexion Automatique**
Au chargement de l'application, si une session existe :
- L'utilisateur est automatiquement redirigé vers son dashboard
- Les employés sont vérifiés pour la validité de la licence du propriétaire
- Les sessions invalides sont automatiquement nettoyées

**Implémentation** : [lib/widgets/AuthStateWrapper.dart](lib/widgets/AuthStateWrapper.dart)

### 3. **Protection des Routes**
Les routes protégées vérifient l'authentification :
- Pages publiques : accessibles sans connexion
- Pages protégées : redirection automatique vers `/login` si non authentifié

**Configuration** : [lib/config/routes.dart](lib/config/routes.dart#L80-L95)

### 4. **Déconnexion Manuelle**
Service de déconnexion avec confirmation :
- Suppression de la session Firebase
- Redirection vers la page d'accueil
- Suppression de l'historique de navigation

**Service** : [lib/services/LogoutService.dart](lib/services/LogoutService.dart)

---

## 🚀 Utilisation

### Ajouter un bouton de déconnexion

```dart
import '../services/LogoutService.dart';

// Dans une AppBar
AppBar(
  actions: [
    LogoutService.logoutIconButton(context),
  ],
)

// Comme bouton
LogoutService.logoutButton(context)

// Dans un menu
LogoutService.logoutButton(context, isMenuItem: true)
```

### Déconnexion programmatique

```dart
import '../services/LogoutService.dart';

// Avec confirmation
await LogoutService.logout(context);

// Sans confirmation
await LogoutService.logout(context, showConfirmation: false);
```

---

## 📊 Flux d'Authentification

```
Utilisateur ouvre l'app
        ↓
Vérification session Firebase
        ↓
    ┌───────┴───────┐
    ↓               ↓
Connecté      Non connecté
    ↓               ↓
Vérifier type   Afficher page
utilisateur     demandée
    ↓
┌───────┴────────┐
↓                ↓
Admin/Manager   Employé
    ↓                ↓
Dashboard       Vérif licence
                propriétaire
                    ↓
                ┌───────┴────────┐
                ↓                ↓
            Valide          Expirée
                ↓                ↓
        Dashboard       Déconnexion
        Employé         + Message
```

---

## 🔒 Sécurité

### Niveaux de persistance Firebase

| Mode | Durée | Usage |
|------|-------|-------|
| `LOCAL` | Persiste après fermeture navigateur | ✅ **Utilisé** - Meilleure UX |
| `SESSION` | Jusqu'à fermeture onglet | ❌ Non utilisé |
| `NONE` | Jusqu'à rafraîchissement page | ❌ Non utilisé |

### Vérifications

- ✅ Validation du type d'utilisateur (admin/employé)
- ✅ Vérification de la licence pour les employés
- ✅ Nettoyage automatique des sessions invalides
- ✅ Protection CSRF via Firebase Auth
- ✅ Tokens JWT avec expiration automatique

---

## 🧪 Tests

### Tester la persistance

1. **Se connecter** → `/login`
2. **Fermer complètement** le navigateur
3. **Rouvrir** l'application
4. ✅ **Résultat** : Redirection automatique vers dashboard

### Tester la déconnexion

1. **Cliquer** sur déconnexion
2. **Confirmer** dans la boîte de dialogue
3. ✅ **Résultat** : Redirection vers `/home` + session supprimée

### Tester les routes protégées

1. **Se déconnecter**
2. **Accéder** à `/dashboard` directement
3. ✅ **Résultat** : Redirection vers `/login`

---

## 📱 Compatibilité

- ✅ **Web** (Chrome, Firefox, Safari, Edge)
- ✅ **Mobile** (iOS, Android)
- ✅ **Desktop** (Windows, macOS, Linux)

---

## 🐛 Résolution de problèmes

### L'utilisateur n'est pas redirigé automatiquement
- Vérifier que `Persistence.LOCAL` est configuré dans `main.dart`
- Vérifier la console pour les erreurs Firebase
- Nettoyer le cache du navigateur

### La déconnexion ne fonctionne pas
- Vérifier que `LogoutService` est correctement importé
- Vérifier les permissions Firebase Auth
- Vérifier la connexion internet

### Routes protégées accessibles sans connexion
- Vérifier que la route n'est pas dans `publicRoutes`
- Vérifier que `onGenerateRoute` vérifie l'authentification
- Redéployer l'application

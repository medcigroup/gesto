# Configuration Firebase Remote Config pour Gesto Mobile

Ce document explique comment configurer Firebase Remote Config pour gérer les liens de téléchargement de l'application mobile Gesto.

## 📋 Vue d'ensemble

Firebase Remote Config permet de mettre à jour les liens de téléchargement APK sans avoir à republier l'application web. Vous pouvez gérer deux versions :
- **Version Stable** : Version recommandée pour tous les utilisateurs
- **Version Beta** : Version avec les nouvelles fonctionnalités (optionnelle)

## 🔧 Configuration dans Firebase Console

### Étape 1 : Accéder à Remote Config

1. Ouvrez [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet : `agritechapp-b4910`
3. Dans le menu latéral, cliquez sur **Remote Config** (sous "Engagement")

### Étape 2 : Créer les paramètres

Créez les 8 paramètres suivants :

#### 1. `apk_stable_url`
- **Type** : String
- **Description** : URL de téléchargement de l'APK stable
- **Valeur par défaut** :
  ```
  https://firebasestorage.googleapis.com/v0/b/agritechapp-b4910.firebasestorage.app/o/Apk%2FGesto_1.0.5.apk?alt=media&token=17486240-7cd8-4a4d-931c-f399c4a4bb9a
  ```

#### 2. `apk_stable_version`
- **Type** : String
- **Description** : Numéro de version stable (ex: 1.0.5)
- **Valeur par défaut** : `1.0.5`

#### 3. `apk_stable_release_date`
- **Type** : String
- **Description** : Date de publication de la version stable (format: YYYY-MM-DD)
- **Valeur par défaut** : `2024-01-15`

#### 4. `apk_stable_changelog`
- **Type** : String (JSON)
- **Description** : Notes de version avec les nouveautés, corrections et améliorations
- **Format JSON** :
  ```json
  {
    "features": [
      "Gestion des commandes restaurant",
      "Gestion cuisine et bar en temps réel",
      "Inventaire du bar avec historique",
      "Planning personnel et badge QR code"
    ],
    "fixes": [
      "Correction du bug d'affichage des commandes",
      "Résolution du problème de synchronisation"
    ],
    "improvements": [
      "Performance améliorée de 30%",
      "Interface utilisateur optimisée"
    ]
  }
  ```
- **Valeur par défaut** :
  ```json
  {"features":["Gestion des commandes restaurant","Gestion cuisine et bar","Inventaire du bar","Planning personnel"],"fixes":["Corrections de bugs mineurs"]}
  ```

#### 5. `apk_beta_url`
- **Type** : String
- **Description** : URL de téléchargement de l'APK beta (laisser vide si pas de beta)
- **Valeur par défaut** : `` (vide)

#### 6. `apk_beta_version`
- **Type** : String
- **Description** : Numéro de version beta (ex: 1.1.0-beta.1)
- **Valeur par défaut** : `` (vide)

#### 7. `apk_beta_release_date`
- **Type** : String
- **Description** : Date de publication de la version beta (format: YYYY-MM-DD)
- **Valeur par défaut** : `` (vide)

#### 8. `apk_beta_changelog`
- **Type** : String (JSON)
- **Description** : Notes de version beta (même format que apk_stable_changelog)
- **Valeur par défaut** : `` (vide)

### Étape 3 : Publier les modifications

1. Cliquez sur **"Publier les modifications"** en haut de la page
2. Ajoutez un message de changement (ex: "Configuration initiale des versions APK")
3. Confirmez la publication

## 📱 Comment uploader un nouvel APK

### Sur Firebase Storage

1. Accédez à **Storage** dans Firebase Console
2. Naviguez vers le dossier `Apk/`
3. Cliquez sur **"Upload file"**
4. Sélectionnez votre fichier APK (ex: `Gesto_1.0.6.apk`)
5. Une fois uploadé, cliquez sur le fichier
6. Cliquez sur l'icône de lien pour obtenir l'URL de téléchargement
7. Copiez l'URL complète (avec le token)

### Mettre à jour Remote Config

1. Retournez dans **Remote Config**
2. Modifiez les paramètres appropriés :
   - Pour une mise à jour stable :
     - `apk_stable_url` : Nouvelle URL
     - `apk_stable_version` : Nouveau numéro (ex: 1.0.6)
     - `apk_stable_release_date` : Date du jour (ex: 2024-12-15)
     - `apk_stable_changelog` : Notes de version (voir format ci-dessous)

   - Pour une version beta :
     - `apk_beta_url` : URL de la beta
     - `apk_beta_version` : Numéro de version beta (ex: 1.1.0-beta.1)
     - `apk_beta_release_date` : Date du jour
     - `apk_beta_changelog` : Notes de version beta

3. Cliquez sur **"Publier les modifications"**

### Format du Changelog

Le changelog doit être au format JSON avec trois catégories optionnelles :

```json
{
  "features": [
    "Nouvelle fonctionnalité 1",
    "Nouvelle fonctionnalité 2"
  ],
  "fixes": [
    "Correction du bug X",
    "Résolution du problème Y"
  ],
  "improvements": [
    "Amélioration de la performance",
    "Optimisation de l'interface"
  ]
}
```

**Notes importantes :**
- Toutes les catégories sont optionnelles
- Les guillemets doubles sont obligatoires
- Pas de virgule après le dernier élément de chaque tableau
- Vous pouvez n'inclure que les catégories pertinentes

**Exemples :**

Version avec seulement des nouvelles fonctionnalités :
```json
{
  "features": [
    "Ajout de la synchronisation automatique",
    "Support du mode hors ligne"
  ]
}
```

Version avec corrections et améliorations :
```json
{
  "fixes": [
    "Correction du crash au démarrage",
    "Résolution du problème de login"
  ],
  "improvements": [
    "Réduction de 40% du temps de chargement",
    "Amélioration de l'ergonomie"
  ]
}
```

## 🔄 Fonctionnement dans l'application

### Chargement automatique
- Lorsqu'un utilisateur ouvre la page de téléchargement, les valeurs sont automatiquement récupérées depuis Firebase Remote Config
- Les valeurs sont mises en cache pendant 1 heure pour optimiser les performances

### Sélection de version
- Si une version beta est disponible (URL non vide), l'utilisateur voit un sélecteur de version
- Par défaut, la version stable est sélectionnée
- L'utilisateur peut basculer entre Stable et Beta

### Affichage des informations
- Numéro de version
- Date de publication
- Badge "Stable" ou "Beta"
- **Changelog détaillé** avec :
  - ⭐ Nouvelles fonctionnalités (icône étoile, couleur verte)
  - 🐛 Corrections de bugs (icône bug, couleur rouge)
  - 📈 Améliorations (icône tendance, couleur bleue)

## 🎯 Exemples de scénarios

### Scénario 1 : Mise à jour stable uniquement
```
apk_stable_url: https://...../Gesto_1.0.6.apk?alt=media&token=xxxxx
apk_stable_version: 1.0.6
apk_stable_release_date: 2024-12-15
apk_stable_changelog: {"features":["Support mode hors ligne"],"fixes":["Correction bug sync"]}
apk_beta_url: (vide)
apk_beta_version: (vide)
apk_beta_release_date: (vide)
apk_beta_changelog: (vide)
```
→ L'utilisateur voit uniquement la version stable avec son changelog, pas de sélecteur de version

### Scénario 2 : Version stable + Beta disponible
```
apk_stable_url: https://...../Gesto_1.0.5.apk?alt=media&token=xxxxx
apk_stable_version: 1.0.5
apk_stable_release_date: 2024-12-10
apk_stable_changelog: {"features":["Gestion commandes","Inventaire bar"]}
apk_beta_url: https://...../Gesto_1.1.0-beta.1.apk?alt=media&token=yyyyy
apk_beta_version: 1.1.0-beta.1
apk_beta_release_date: 2024-12-15
apk_beta_changelog: {"features":["Notifications push","Dark mode"],"improvements":["Performance x2"]}
```
→ L'utilisateur peut choisir entre stable (1.0.5) et beta (1.1.0-beta.1) avec leurs changelogs respectifs

### Scénario 3 : Promouvoir une beta en stable
1. La beta devient la nouvelle stable
2. Mettre à jour les paramètres :
```
apk_stable_url: (ancienne URL beta)
apk_stable_version: 1.1.0
apk_stable_release_date: 2024-12-20
apk_stable_changelog: (copier depuis apk_beta_changelog)
apk_beta_url: (vide ou nouvelle beta)
apk_beta_version: (vide ou nouvelle version)
apk_beta_release_date: (vide ou nouvelle date)
apk_beta_changelog: (vide ou nouveau changelog beta)
```

## 🛠️ Debugging

### Forcer le rechargement
Pour forcer le rechargement des valeurs Remote Config (utile pour le développement) :

```dart
final remoteConfig = RemoteConfigService();
await remoteConfig.forceRefresh();
```

### Vérifier les valeurs actuelles
Les valeurs sont affichées dans les logs lors du chargement de la page :
```
✅ Remote Config initialisé avec succès
```

### En cas d'erreur
Si Remote Config ne se charge pas :
1. Vérifiez que Firebase est correctement initialisé dans votre app
2. Vérifiez les règles de sécurité de Remote Config
3. Les valeurs par défaut (hardcodées dans le service) seront utilisées

## 📝 Bonnes pratiques

1. **Toujours tester les URLs** : Vérifiez que l'URL de téléchargement fonctionne avant de la publier
2. **Versioning cohérent** : Utilisez le format SemVer (ex: 1.2.3)
3. **Dates au format ISO** : Utilisez YYYY-MM-DD pour faciliter le tri
4. **Communication** : Informez les utilisateurs des nouveautés dans les notes de version
5. **Backup** : Gardez une copie des anciennes versions au cas où
6. **Tests beta** : Testez toujours une version beta avant de la promouvoir en stable

## 🔐 Sécurité

Les paramètres Remote Config sont publics et peuvent être lus par n'importe quelle application. C'est normal pour les URLs de téléchargement publiques. Ne stockez JAMAIS :
- ❌ Clés API privées
- ❌ Tokens d'authentification
- ❌ Informations sensibles

## 📞 Support

Pour toute question sur la configuration :
1. Consultez la [documentation Firebase Remote Config](https://firebase.google.com/docs/remote-config)
2. Vérifiez le fichier `lib/services/remote_config_service.dart` pour la logique de l'application

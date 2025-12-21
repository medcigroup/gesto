# 🏨 Pages Publiques d'Hôtel - Guide Complet

## 🎯 Vue d'ensemble

Chaque client Gesto peut désormais créer **sa propre page publique** avec une URL unique pour promouvoir son établissement en ligne.

**📦 Disponibilité :** Licence **STARTER** ou supérieure (PRO, ENTREPRISE)

### Exemples d'URLs
- `gestoapp.cloud/hotel/rayahotel`
- `gestoapp.cloud/hotel/palace-douala`
- `gestoapp.cloud/hotel/sunrise-beach-resort`

---

## ✨ Fonctionnalités

### Pour les Gérants d'Hôtel (STARTER+)
- ✅ Création de page publique personnalisée
- ✅ URL unique générée automatiquement
- ✅ Affichage des chambres disponibles
- ✅ Informations de contact
- ✅ Activation/désactivation de la visibilité
- ✅ Partage facile de l'URL

**⚠️ Prérequis :** Licence STARTER, PRO ou ENTREPRISE

### Pour les Visiteurs
- ✅ Voir les chambres disponibles
- ✅ Consulter les tarifs
- ✅ Contacter l'établissement
- ✅ Accès direct via URL
- ✅ Pas besoin de compte

---

## 🔧 Configuration Technique

### 1. Structure Firestore

#### Collection `hotels`
```javascript
{
  "userId": "abc123",              // ID du propriétaire
  "slug": "rayahotel",             // Identifiant unique URL
  "hotelName": "Raya Hotel",       // Nom de l'établissement
  "address": "Douala, Cameroun",   // Adresse
  "description": "...",             // Description
  "phone": "+237 XXX XXX XXX",     // Téléphone
  "email": "contact@hotel.com",    // Email
  "coverImage": "url...",          // Image de couverture
  "isPublic": true,                // Visibilité
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### 2. Routes Configurées

#### Route Dynamique
```dart
// Dans routes.dart
if (settings.name!.startsWith('/hotel/')) {
  final slug = settings.name!.replaceFirst('/hotel/', '');
  return MaterialPageRoute(
    builder: (_) => PublicHotelPage(hotelSlug: slug),
  );
}
```

#### Routes Ajoutées
- `/hotel/:slug` - Page publique de l'hôtel (dynamique)
- `/manage-public-page` - Gestion de la page publique (protégée)

---

## 📱rérequis
- ✅ Licence **STARTER** ou supérieure
- ✅ Compte actif sur Gesto
- ✅ Informations de base de l'établissement

### P Utilisation

### Pour Créer sa Page Publique

1. **Accéder aux Paramètres**
   ```
   Dashboard → Paramètres → Ma Page Publique
   ```

2. **Remplir les Informations**
   - Nom de l'hôtel (requis)
   - Adresse (requis)
   - Description
   - Téléphone
   - Email

3. **Activer la Visibilité**
   - Basculer "Page publique visible" à ON

4. **Enregistrer**
   - Cliquer sur "Enregistrer"
   - ✅ URL générée automatiquement

5. **Partager l'URL**
   - Copier l'URL affichée
   - Partager sur réseaux sociaux, WhatsApp, etc.

---

## 🔄 Génération du Slug

### Algorithme
```dart
"Raya Hotel"           → "rayahotel"
"Palace Douala"        → "palace-douala"
"Hôtel de l'Océan"     → "hotel-de-l-ocean"
"Sunrise Beach Resort" → "sunrise-beach-resort"
```

### Règles
1. Conversion en minuscules
2. Remplacement des espaces par tirets
3. Suppression des accents
4. Suppression des caractères spéciaux
5. Ajout d'un numéro si existe déjà (ex: `rayahotel-2`)

---

## 🎨 Design de la Page Publique

### Sections

1. **Hero Section**
   - Image de couverture (gradient si pas d'image)
   - Nom de l'hôtel en grand
   - Adresse avec icône

2. **À Propos**
   - Description de l'établissement
   - Coordonnées (téléphone, email)

3. **Chambres Disponibles**
   - Grille de chambres
   - Numéro de chambre
   - Type de chambre
   - Prix par nuit
   - Badge "Disponible"

4. **Section Contact**
   - Bouton "Réservez Maintenant"
   - Lien vers page de contact

5. **Footer**
   - Mention "Propulsé par Gesto"
   - Lien "Créer ma page hôtel"

---

## 🔒 Sécurité & Permissions

### Données Publiques
- ✅ Nom de l'hôtel
- ✅ Adresse
- ✅ Description
- ✅ Téléphone
- ✅ Email
- ✅ Chambres disponibles (`isAvailable: true`)
- ✅ Prix des chambres

### Données Privées (Non visibles)
- ❌ Réservations
- ❌ Clients
- ❌ Personnel
- ❌ Finances
- ❌ Chambres non disponibles

### Filtre Firestore
```dart
.where('isPublic', isEqualTo: true)  // Seuls les hôtels publics
.where('isAvailable', isEqualTo: true) // Seulement chambres dispo
```

---

## 📊 Service HotelSlugService

### Méthodes Disponibles

```dart
// Générer un slug
String slug = HotelSlugService.generateSlug("Raya Hotel");

// Vérifier disponibilité
bool available = await HotelSlugService.isSlugAvailable("rayahotel");

// Générer slug unique
String unique = await HotelSlugService.generateUniqueSlug("Raya Hotel");

// Créer/Mettre à jour
bool success = await HotelSlugService.createOrUpdateHotelDocument(
  userId: userId,
  hotelName: "Raya Hotel",
  address: "Douala",
  // ...
);

// Récupérer slug
String? slug = await HotelSlugService.getHotelSlug(userId);

// Générer URL complète
String url = HotelSlugService.getPublicUrl("rayahotel");
// → "https://gestoapp.cloud/hotel/rayahotel"
```

---

## 🧪 Tests

### Scénarios de Test

1. **Création de Page**
   ```
   1. Se connecter comme gérant
   2. Aller dans "Ma Page Publique"
   3. Remplir formulaire
   4. Enregistrer
   5. ✅ Vérifier que slug est généré
   ```

2. **Accès Public**
   ```
   1. Copier l'URL publique
   2. Ouvrir en navigation privée
   3. ✅ Page s'affiche sans authentification
   4. ✅ Chambres disponibles visibles
   ```

3. **Deep Linking**
   ```
   1. Ouvrir directement gestoapp.cloud/hotel/rayahotel
   2. ✅ Page de l'hôtel s'affiche
   3. Pas de redirection
   ```

4. **Visibilité**
   ```
   1. Désactiver "Page publique visible"
   2. Enregistrer
   3. Essayer d'accéder à l'URL
   4. ✅ "Hôtel non trouvé"
   ```

5. **Slug Unique**
   ```
   1. Créer "Raya Hotel" → rayahotel
   2. Créer un autre "Raya Hotel" → rayahotel-2
   3. ✅ Pas de conflit
   ```

---

## 🚀 Déploiement

### Étapes

1. **Build**
   ```powershell
   flutter build web --release
   ```

2. **Deploy Firebase**
   ```powershell
   firebase deploy --only hosting
   ```

3. **Vérifier**
   - Tester URL directe
   - Vérifier responsive
   - Tester sur mobile

---

## 📈 Améliorations Futures

### Fonctionnalités Prévues

- [ ] Upload d'image de couverture
- [ ] Galerie de photos de l'hôtel
- [ ] Formulaire de réservation intégré
- [ ] Avis clients
- [ ] Multi-langues
- [ ] SEO optimisé
- [ ] Analytics (visites, clics)
- [ ] QR Code généré automatiquement
- [ ] Partage sur réseaux sociaux
- [ ] Calendrier de disponibilité

---

## 💡 Cas d'Usage

### Exemples Concrets

1. **Hôtel Urbain**
   - URL: `gestoapp.cloud/hotel/central-hotel-yaounde`
   - Partage sur Facebook, Instagram
   - QR code sur cartes de visite

2. **Resort de Plage**
   - URL: `gestoapp.cloud/hotel/kribi-beach-resort`
   - Lien dans signature email
   - Publicité en ligne

3. **Auberge**
   - URL: `gestoapp.cloud/hotel/auberge-bamenda`
   - Référencement Google
   - Plateforme de réservation

---

## 🔍 SEO & Marketing

### Optimisations

1. **Meta Tags** (à ajouter)
   ```html
   <meta name="description" content="...">
   <meta property="og:title" content="Raya Hotel">
   <meta property="og:image" content="...">
   ```

2. **URL Propres**
   - ✅ Pas de `#`
   - ✅ Slug lisible
   - ✅ Deep linking

3. **Partage Social**
   - WhatsApp Business
   - Facebook Pages
   - Instagram Bio
   - Google My Business

---

## 📞 Support

Pour toute question ou assistance :
- Email: support@gestoapp.cloud
- Dans l'app: Aide & Documentation

---

## ✅ Résumé

- ✅ Pages publiques dynamiques créées
- ✅ URLs uniques par établissement
- ✅ Gestion facile depuis dashboard
- ✅ Partage simplifié
- ✅ Responsive & moderne
- ✅ Sécurisé (données filtrées)

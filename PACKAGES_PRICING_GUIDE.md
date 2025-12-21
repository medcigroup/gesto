# Guide de Tarification des Packages

## Vue d'ensemble

Le système de gestion des packages hôteliers permet maintenant de définir des tarifs flexibles pour les packages payants selon différentes périodes : heure, jour, semaine ou mois.

## Fonctionnalités

### 1. Structure de Prix

Chaque package payant peut avoir jusqu'à 4 types de tarifs :
- **Prix par heure** : Idéal pour les services temporaires (spa, salle de conférence, etc.)
- **Prix par jour** : Pour les services quotidiens (parking, petit-déjeuner, etc.)
- **Prix par semaine** : Pour les séjours de moyenne durée
- **Prix par mois** : Pour les clients long séjour

### 2. Modèle de Données

#### PackagePricing
```dart
class PackagePricing {
  final double? pricePerHour;   // Prix à l'heure
  final double? pricePerDay;    // Prix par jour
  final double? pricePerWeek;   // Prix par semaine
  final double? pricePerMonth;  // Prix par mois
}
```

#### HotelPackage
```dart
class HotelPackage {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isIncluded;        // true = gratuit, false = payant
  final String category;
  final PackagePricing pricing; // Nouveau champ de tarification
}
```

### 3. Interface Utilisateur

#### Création/Modification de Package

1. **Type de Package**
   - Sélectionnez "Gratuit" pour un package inclus
   - Sélectionnez "Payant" pour afficher la section de tarification

2. **Section de Tarification** (uniquement pour packages payants)
   - Apparaît automatiquement quand "Payant" est sélectionné
   - 4 champs de saisie pour les différentes périodes
   - Tous les champs sont optionnels (au moins un doit être rempli)
   - Format : nombre décimal avec symbole €

#### Affichage dans la Liste

Pour les packages payants avec tarifs définis, une étiquette orange affiche :
- Les prix disponibles (ex: "25.00€/j • 150.00€/sem")
- Format automatique selon les prix configurés

### 4. Exemples d'Utilisation

#### Exemple 1 : Parking
```
Nom: Parking privé sécurisé
Type: Payant
Prix par jour: 15.00€
Prix par semaine: 90.00€
Prix par mois: 300.00€
```

#### Exemple 2 : Salle de Conférence
```
Nom: Salle de conférence
Type: Payant
Prix par heure: 50.00€
Prix par jour: 350.00€
```

#### Exemple 3 : Spa & Bien-être
```
Nom: Accès spa illimité
Type: Payant
Prix par jour: 30.00€
Prix par semaine: 180.00€
```

### 5. Stockage Firestore

Structure dans la base de données :
```json
{
  "name": "Parking",
  "description": "Parking privé sécurisé",
  "icon": "parking",
  "isIncluded": false,
  "category": "services",
  "pricing": {
    "pricePerHour": null,
    "pricePerDay": 15.00,
    "pricePerWeek": 90.00,
    "pricePerMonth": 300.00
  },
  "userId": "hotel_user_id",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 6. Méthodes Utiles

#### hasAnyPrice()
Vérifie si au moins un prix est défini
```dart
if (package.pricing.hasAnyPrice()) {
  // Afficher les informations de prix
}
```

#### getPricingInfo()
Retourne une chaîne formatée avec tous les prix
```dart
String info = package.pricing.getPricingInfo();
// Résultat: "15.00€/j • 90.00€/sem • 300.00€/mois"
```

### 7. Validation

- Au moins un prix doit être défini pour un package payant
- Les prix acceptent les nombres décimaux (ex: 25.50)
- Les champs vides sont traités comme `null`
- La conversion se fait automatiquement lors de la sauvegarde

### 8. Fichiers Modifiés

1. **lib/components/checkin/options_package_section.dart**
   - Ajout de la classe `PackagePricing`
   - Mise à jour de la classe `HotelPackage`
   - Ajout des méthodes `hasAnyPrice()` et `getPricingInfo()`

2. **lib/config/HotelPackagesManagement.dart**
   - Ajout des contrôleurs de texte pour les 4 prix
   - Interface utilisateur pour la saisie des prix
   - Affichage des prix dans les cartes de packages
   - Sauvegarde et chargement des prix

### 9. Migration des Données Existantes

Les packages existants sans prix sont automatiquement compatibles :
- Le champ `pricing` est créé avec des valeurs `null`
- `PackagePricing()` crée une instance vide par défaut
- Aucune migration manuelle nécessaire

### 10. Bonnes Pratiques

1. **Cohérence des Prix**
   - Prix par semaine ≈ 7 × prix par jour (avec réduction)
   - Prix par mois ≈ 4 × prix par semaine (avec réduction)

2. **Catégories Recommandées**
   - Services horaires → Prix/heure + Prix/jour
   - Services quotidiens → Prix/jour + Prix/semaine + Prix/mois
   - Équipements → Prix/jour + Prix/semaine

3. **Affichage Client**
   - Toujours afficher le prix le plus avantageux selon la durée
   - Calculer automatiquement l'option la plus économique

## Support

Pour toute question ou problème, référez-vous aux fichiers :
- [options_package_section.dart](lib/components/checkin/options_package_section.dart)
- [HotelPackagesManagement.dart](lib/config/HotelPackagesManagement.dart)

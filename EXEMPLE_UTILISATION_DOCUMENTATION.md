# 📖 Exemple d'utilisation de la Documentation

## Comment accéder à la documentation dans GESTO

### Depuis n'importe quelle page

```dart
// Ajouter un bouton d'aide
IconButton(
  icon: Icon(Icons.help_outline),
  tooltip: 'Centre d\'aide',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HelpDocumentationPage(),
      ),
    );
  },
)
```

---

## 🎯 Exemple concret : Vendre une option à un client

### Scénario
Un client arrive à la réception et souhaite acheter un accès piscine pour 3 jours.

### Dans la documentation, on trouve :

#### 📍 Navigation
```
Centre d'aide
  → Aide (Fonctionnalités)
    → Boutique d'Options
      → 👤 Vendre à un Client Enregistré
```

#### 📝 Instructions affichées
```
Pour un client qui a déjà une réservation :

1. Depuis la fiche de réservation ou check-in,
   cliquez sur "Ajouter des options"

2. Les informations client (nom, email, téléphone, chambre)
   sont pré-remplies

3. Sélectionnez les options désirées dans le catalogue

4. Pour chaque option : choisissez la période
   (heure/jour/semaine/mois) et la quantité

5. Vérifiez le panier et le montant total

6. Cliquez sur "Confirmer l'achat"

7. Le ticket sera généré automatiquement
   au format 80x80mm
```

---

## 🎯 Exemple concret : Créer un ticket de support

### Scénario
Un utilisateur rencontre un bug lors de la création d'une réservation.

### Dans la documentation, on trouve :

#### 📍 Navigation
```
Centre d'aide
  → Aide (Fonctionnalités)
    → Support et Assistance
      → 🎫 Créer un Ticket de Support
```

#### 📝 Instructions affichées
```
Tous les utilisateurs peuvent créer des tickets de support :

1. Accédez à la page "Support" depuis le menu principal

2. Cliquez sur "Nouveau Ticket" ou "Créer un ticket"

3. Remplissez le formulaire avec les informations requises

4. Sujet : Titre court et descriptif du problème

5. Description : Expliquez le problème en détail

6. Catégorie : Bug, Fonctionnalité, Question, Feedback, Autre

7. Priorité : Basse, Moyenne, Haute, Urgente (selon la gravité)

8. Attachements : Joignez des captures d'écran si nécessaire

9. Cliquez sur "Envoyer" pour soumettre votre ticket
```

---

## 🔍 Utilisation de la recherche

### Exemple 1 : Rechercher "ticket"

**Résultats affichés :**
```
📍 Support et Assistance > Créer un Ticket de Support
   "Tous les utilisateurs peuvent créer des tickets..."

📍 Support et Assistance > Suivre vos Tickets
   "Consultez l'état d'avancement de vos demandes..."

📍 Support et Assistance > Statuts des Tickets
   "Comprendre les différents statuts : Ouvert, En cours..."
```

### Exemple 2 : Rechercher "paiement"

**Résultats affichés :**
```
📍 Boutique d'Options > Panier et Validation
   "Sélectionnez le mode de paiement (Espèces, Carte..."

📍 Boutique d'Options > Modes de Paiement
   "Plusieurs modes de paiement sont disponibles..."

📍 Paiements > Enregistrer un Paiement
   "Comment enregistrer un paiement client..."
```

---

## 💼 Exemple pour Managers

### Scénario
Un manager veut créer une nouvelle option "Massage relaxant 1h".

#### 📍 Navigation
```
Centre d'aide
  → Aide (Fonctionnalités)
    → Boutique d'Options
      → ⚙️ Configurer les Options Disponibles
```

#### 📝 Instructions affichées (Managers uniquement)
```
Seuls les managers peuvent créer et modifier les options :

1. Accédez à "Gestion des Packages"
   depuis le Dashboard Manager

2. Cliquez sur "Ajouter un nouveau package"

3. Remplissez : Nom, Description, Catégorie

4. Sélectionnez "Payant" (non inclus dans le séjour)

5. Définissez les prix : par heure, jour, semaine et/ou mois
   Exemple : 15000 FCFA/heure

6. Choisissez l'icône appropriée (💆 Bien-être)

7. Activez l'option pour qu'elle apparaisse dans la boutique

8. Sauvegardez - L'option est immédiatement disponible
```

---

## 🎨 Aperçu visuel de l'interface

### Layout de la page

```
┌─────────────────────────────────────────────────────────────┐
│  📚 Centre d'aide                              [Recherche] X │
├────────────────┬────────────────────────────────────────────┤
│                │  Aide (Fonctionnalités) > Boutique d'Options│
│  [🔍 Search]   │                                             │
│                │  ┌────────────────────────────────────────┐ │
│  ┌──────────┐  │  │  🏪 Boutique d'Options                 │ │
│  │   Aide   │  │  │                                        │ │
│  │   Doc    │  │  │  La Boutique d'Options permet de...   │ │
│  └──────────┘  │  └────────────────────────────────────────┘ │
│                │                                             │
│  • Dashboard   │  📋 Vue d'ensemble                          │
│  • Réservations│  Description du système...                  │
│  • Check-in    │                                             │
│  • Chambres    │  🏪 Accéder à la Boutique                   │
│  • Paiements   │  1. Depuis le Dashboard Manager...         │
│  • Finance     │  2. Lors d'un check-in...                  │
│  • Restaurant  │  3. Page publique...                       │
│  • Tâches      │                                             │
│  • Personnel   │  👤 Vendre à un Client Enregistré          │
│  • Paramètres  │  Pour un client avec réservation :         │
│▶ • Boutique ◀  │  ┌──────────────────────────────────────┐  │
│  • Support     │  │ MARCHE À SUIVRE :                     │  │
│                │  │                                        │  │
│                │  │ ① Depuis la fiche de réservation...   │  │
│                │  │ ② Les informations client sont...     │  │
│                │  │ ③ Sélectionnez les options...         │  │
│                │  └──────────────────────────────────────┘  │
│                │                                             │
│  300px         │           Contenu défilable                 │
└────────────────┴────────────────────────────────────────────┘
```

---

## 📱 Responsive sur Mobile

```
┌──────────────────────┐
│ ☰  Centre d'aide   X │
├──────────────────────┤
│  [🔍 Rechercher...] │
├──────────────────────┤
│  Aide > Boutique     │
├──────────────────────┤
│                      │
│  🏪 Boutique         │
│     d'Options        │
│                      │
│  📋 Vue d'ensemble   │
│  Description...      │
│                      │
│  🏪 Accéder          │
│  1. Dashboard...     │
│  2. Check-in...      │
│                      │
│  👤 Vendre Client    │
│  ┌────────────────┐  │
│  │ ÉTAPES :       │  │
│  │ ① Fiche...     │  │
│  │ ② Infos...     │  │
│  └────────────────┘  │
│                      │
│   [Scroll ↓]         │
└──────────────────────┘
```

---

## 🎯 Cas d'usage avancés

### 1. Utilisateur perdu

**Problème :** "Je ne sais pas comment ajouter une option"

**Solution :**
1. Clic sur icône d'aide (?)
2. Recherche "ajouter option"
3. Premier résultat : "Vendre à un Client Enregistré"
4. Suit les 7 étapes numérotées
5. Problème résolu ✅

---

### 2. Manager formation nouveau personnel

**Problème :** "Former un nouvel employé sur le système"

**Solution :**
1. Ouvrir le Centre d'aide
2. Naviguer section par section
3. Montrer chaque fonctionnalité documentée
4. Utiliser comme manuel de formation
5. Employé formé ✅

---

### 3. Bug rencontré

**Problème :** "Erreur lors de la génération d'un ticket"

**Solution :**
1. Aller dans "Support et Assistance"
2. Lire "Créer un Ticket de Support"
3. Choisir catégorie "🐛 Bug"
4. Remplir description détaillée
5. Joindre capture d'écran
6. Support notifié ✅

---

### 4. Question sur tarification

**Problème :** "Comment définir un prix à la semaine ?"

**Solution :**
1. Rechercher "tarification"
2. Trouver "⏰ Périodes de Tarification"
3. Lire les 6 étapes explicatives
4. Comprendre le système
5. Question résolue ✅

---

## 💡 Astuces d'utilisation

### Pour les utilisateurs

```
✅ Utilisez la recherche pour gagner du temps
✅ Marquez vos sections favorites (future feature)
✅ Consultez la FAQ avant de créer un ticket
✅ Suivez les étapes dans l'ordre
✅ Regardez les emojis pour repérage rapide
```

### Pour les managers

```
✅ Formez votre équipe avec cette documentation
✅ Référez-vous aux sections "Managers uniquement"
✅ Utilisez comme support de formation
✅ Consultez régulièrement les bonnes pratiques
✅ Contribuez à l'amélioration (via Support)
```

---

## 🔧 Intégration dans votre code

### Ajouter un lien d'aide contextuel

```dart
// Dans une page quelconque
AppBar(
  title: Text('Boutique d\'Options'),
  actions: [
    IconButton(
      icon: Icon(Icons.help_outline),
      tooltip: 'Aide sur cette page',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HelpDocumentationPage(),
          ),
        );
        // Note : Future feature = ouvrir directement
        // la section correspondante
      },
    ),
  ],
)
```

### Intégrer dans le menu principal

```dart
Drawer(
  child: ListView(
    children: [
      // ... autres items ...

      Divider(),

      ListTile(
        leading: Icon(Icons.library_books),
        title: Text('Centre d\'aide'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HelpDocumentationPage(),
            ),
          );
        },
      ),

      ListTile(
        leading: Icon(Icons.support_agent),
        title: Text('Support'),
        onTap: () {
          // Ouvrir directement la section Support
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HelpDocumentationPage(),
              // + paramètre pour ouvrir section Support
            ),
          );
        },
      ),
    ],
  ),
)
```

---

## 📊 Métriques d'utilisation (Future)

Possibilité de tracker :
- Sections les plus consultées
- Recherches fréquentes
- Temps passé sur chaque section
- Taux de résolution de problèmes
- Feedback utilisateur (utile/pas utile)

---

## 🎓 Prochaines étapes

1. ✅ Documentation créée
2. ⏳ Tester dans l'application
3. ⏳ Former les utilisateurs
4. ⏳ Collecter les feedbacks
5. ⏳ Améliorer le contenu
6. ⏳ Ajouter captures d'écran
7. ⏳ Créer vidéos tutoriels

---

**Date :** 21 décembre 2025
**Prêt à l'emploi :** ✅ OUI

import 'package:flutter/material.dart';

// --- VOS IMPORTS ---
// Assurez-vous que ces chemins correspondent à votre structure de projet
import 'package:gesto/Screens/manager/help/sections/help_sections_index.dart';
import 'help_models.dart';

class HelpDocumentationPage extends StatefulWidget {
  const HelpDocumentationPage({super.key});

  @override
  State<HelpDocumentationPage> createState() => _HelpDocumentationPageState();
}

// --- MODÈLE POUR LES RÉSULTATS DE RECHERCHE ---
class SearchResult {
  final String menuTitle;
  final String categoryTitle;
  final HelpSection section;
  // Index nécessaires pour la navigation au clic
  final int menuIndex;
  final int categoryIndex;

  SearchResult({
    required this.menuTitle,
    required this.categoryTitle,
    required this.section,
    required this.menuIndex,
    required this.categoryIndex,
  });
}

class _HelpDocumentationPageState extends State<HelpDocumentationPage> {
  // --- VARIABLES D'ÉTAT ---
  int _selectedMenuIndex = 0;
  int _selectedCategoryIndex = 0;
  late List<HelpMenu> _helpMenus;

  // Variables pour la recherche
  String _searchQuery = '';
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _contentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Chargement des données (fonction externe supposée existante dans vos imports)
    _helpMenus = getAllHelpMenus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE RECHERCHE ---

  void _onSearchChanged() {
    final newQuery = _searchController.text;
    if (newQuery != _searchQuery) {
      setState(() {
        _searchQuery = newQuery;
        if (_searchQuery.trim().isEmpty) {
          _isSearching = false;
          _searchResults = [];
        } else {
          _isSearching = true;
          _performSearch(newQuery);
        }
      });
    }
  }

  void _performSearch(String query) {
    if (query.length < 2) return;

    final lowerCaseQuery = query.toLowerCase();
    final List<SearchResult> results = [];

    // Double boucle avec index pour pouvoir naviguer plus tard
    _helpMenus.asMap().forEach((menuIdx, menu) {
      menu.categories.asMap().forEach((catIdx, category) {
        for (final section in category.sections) {
          final matchTitle = section.title.toLowerCase().contains(lowerCaseQuery);

          // Vérification null-safe pour le contenu
          final matchContent = section.content != null
              ? section.content!.toLowerCase().contains(lowerCaseQuery)
              : false;

          final matchSteps = section.steps.any((s) => s.toLowerCase().contains(lowerCaseQuery));

          if (matchTitle || matchContent || matchSteps) {
            results.add(SearchResult(
              menuTitle: menu.title,
              categoryTitle: category.title,
              section: section,
              menuIndex: menuIdx,    // On capture l'index du menu
              categoryIndex: catIdx, // On capture l'index de la catégorie
            ));
          }
        }
      });
    });

    setState(() {
      _searchResults = results;
    });
  }

  // --- LOGIQUE DE NAVIGATION ---

  // Change le menu actif via la barre latérale
  void _selectMenu(int index) {
    setState(() {
      _selectedMenuIndex = index;
      _selectedCategoryIndex = 0;
      _exitSearchMode();
    });
    // Remonter en haut de page lors du changement
    if (_contentScrollController.hasClients) {
      _contentScrollController.jumpTo(0);
    }
  }

  // Fonction appelée lors du clic sur un résultat de recherche
  void _navigateToResult(SearchResult result) {
    setState(() {
      _selectedMenuIndex = result.menuIndex;
      _selectedCategoryIndex = result.categoryIndex;
      _exitSearchMode();
    });

    // Remonter en haut de page pour lire le contenu
    if (_contentScrollController.hasClients) {
      _contentScrollController.jumpTo(0);
    }
  }

  void _exitSearchMode() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchResults = [];
    });
  }

  // --- CONSTRUCTION DE L'INTERFACE (BUILD) ---

  @override
  Widget build(BuildContext context) {
    // Gestion du thème (Dark/Light)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Palette de couleurs
    final sidebarColor = isDark ? const Color(0xFF1E1E24) : const Color(0xFFF7F9FC);
    final contentColor = isDark ? const Color(0xFF121212) : Colors.white;
    final primaryColor = const Color(0xFF3F51B5); // Indigo
    final textColor = isDark ? Colors.white : const Color(0xFF2D3748);
    final subTextColor = isDark ? Colors.grey[400] : const Color(0xFF718096);
    final borderColor = isDark ? Colors.white10 : Colors.grey[300]!;

    // Données actuelles
    final currentMenu = _helpMenus[_selectedMenuIndex];
    final HelpCategory? currentCategory = currentMenu.categories.isNotEmpty
        ? currentMenu.categories[_selectedCategoryIndex]
        : null;

    return Scaffold(
      backgroundColor: contentColor,
      body: Row(
        children: [
          // --------------------------
          // 1. BARRE LATÉRALE (SIDEBAR)
          // --------------------------
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: sidebarColor,
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: [
                // Titre Sidebar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                  child: Row(
                    children: [
                      Icon(Icons.library_books_rounded, color: primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Centre d\'aide',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Champ de recherche
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: TextStyle(color: subTextColor),
                      prefixIcon: Icon(Icons.search, color: subTextColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _exitSearchMode,
                      )
                          : null,
                      filled: true,
                      fillColor: isDark ? Colors.black12 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor.withOpacity(0.5), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Liste de navigation
                Expanded(
                  child: _isSearching
                      ? _buildSearchStatus(textColor, subTextColor ?? Colors.grey)
                      : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      // Sélecteur de Menu (Onglets horizontaux)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: _helpMenus.asMap().entries.map((entry) {
                            final isSelected = _selectedMenuIndex == entry.key;
                            return GestureDetector(
                              onTap: () => _selectMenu(entry.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? primaryColor.withOpacity(0.3) : borderColor,
                                  ),
                                ),
                                child: Text(
                                  entry.value.title,
                                  style: TextStyle(
                                    color: isSelected ? primaryColor : subTextColor,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Liste des Catégories (Verticale)
                      if (currentMenu.categories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("Aucune catégorie", style: TextStyle(color: subTextColor)),
                        )
                      else
                        ...currentMenu.categories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          final isSelected = _selectedCategoryIndex == index;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryIndex = index;
                                  });
                                  if (_contentScrollController.hasClients) {
                                    _contentScrollController.jumpTo(0);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? (isDark ? Colors.white10 : Colors.white) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: isSelected && !isDark
                                        ? [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2))
                                    ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        category.icon,
                                        size: 20,
                                        color: isSelected ? primaryColor : subTextColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          category.title,
                                          style: TextStyle(
                                            color: isSelected ? textColor : subTextColor,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                                        )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --------------------------
          // 2. CONTENU PRINCIPAL
          // --------------------------
          Expanded(
            child: Column(
              children: [
                // Top Bar
                // Code Corrigé pour le contenu de la Row de la Top Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- ÉLÉMENT DE GAUCHE : Breadcrumbs ou Statut de Recherche ---
                      if (!_isSearching && currentCategory != null)
                        Row(
                          // Fil d'Ariane
                          children: [
                            Text(currentMenu.title,
                                style: TextStyle(color: subTextColor, fontSize: 13)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.chevron_right, size: 16, color: subTextColor),
                            ),
                            Text(currentCategory.title,
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        )
                      else if (_isSearching)
                        Text("Recherche en cours",
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold))
                      else
                        const SizedBox.shrink(), // Le else est maintenant attaché au dernier if

                      // --- ÉLÉMENT DE DROITE : Bouton Fermer ---
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: "Fermer l'aide",
                        color: subTextColor,
                      ),
                    ],
                  ),
                ),

                // Zone de scroll
                Expanded(
                  child: SingleChildScrollView(
                    controller: _contentScrollController,
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800), // Max width pour la lisibilité
                        child: _isSearching
                            ? _buildSearchResultsView(textColor, subTextColor ?? Colors.grey, primaryColor, borderColor)
                            : _buildCategoryContent(
                          currentCategory,
                          textColor,
                          subTextColor ?? Colors.grey,
                          primaryColor,
                          isDark,
                          borderColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS D'AFFICHAGE ---

  // Affichage simple du nombre de résultats dans la sidebar
  Widget _buildSearchStatus(Color textColor, Color subTextColor) {
    if (_searchQuery.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "Tapez au moins 2 caractères...",
            textAlign: TextAlign.center,
            style: TextStyle(color: subTextColor, fontSize: 13),
          ),
        ),
      );
    }
    return Center(
      child: Text(
        "${_searchResults.length} résultat(s)",
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Affichage des résultats de recherche (Cliquables)
  Widget _buildSearchResultsView(
      Color textColor, Color subTextColor, Color primaryColor, Color borderColor) {
    if (_searchQuery.isEmpty) return const SizedBox.shrink();

    if (_searchResults.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: subTextColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "Aucun résultat pour \"$_searchQuery\"",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            "Vérifiez l'orthographe ou essayez un autre terme.",
            style: TextStyle(color: subTextColor),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Meilleurs résultats pour \"$_searchQuery\"",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 32),

        ..._searchResults.map((result) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Material(
              color: Colors.transparent, // Important pour voir l'effet de clic
              child: InkWell(
                onTap: () => _navigateToResult(result), // <-- ACTION DE NAVIGATION ICI
                borderRadius: BorderRadius.circular(12),
                hoverColor: primaryColor.withOpacity(0.04),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${result.menuTitle} > ${result.categoryTitle}",
                              style: TextStyle(
                                  fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(Icons.arrow_forward, size: 16, color: subTextColor),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.section.title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.section.content ?? '', // Utiliser la chaîne vide si null
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subTextColor, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Affichage du contenu normal d'une catégorie
  Widget _buildCategoryContent(HelpCategory? category, Color textColor, Color subTextColor,
      Color primaryColor, bool isDark, Color borderColor) {
    if (category == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la catégorie
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(category.icon, size: 32, color: primaryColor),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Guide détaillé et instructions",
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),

        // Contenu des sections
        if (category.sections.isEmpty)
          Center(child: Text("Contenu à venir...", style: TextStyle(color: subTextColor)))
        else
          ...category.sections
              .map((section) =>
              _buildSectionDetail(section, textColor, subTextColor, primaryColor, isDark, borderColor))
              .toList(),
      ],
    );
  }

  // Détail d'une section spécifique
  Widget _buildSectionDetail(HelpSection section, Color textColor, Color subTextColor,
      Color primaryColor, bool isDark, Color borderColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre H2
          Text(
            section.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),

          // Si la section a un customWidget, on l'affiche
          if (section.customWidget != null)
            section.customWidget!
          else ...[
            // Sinon, on affiche le contenu texte et les étapes
            // Paragraphe principal (peut être nul)
            if (section.content != null && section.content!.isNotEmpty)
              Text(
                section.content!,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  height: 1.6,
                ),
              ),

            // Étapes (Steps) si elles existent
            if (section.steps.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MARCHE À SUIVRE :",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: subTextColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...section.steps.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${entry.key + 1}",
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ]
          ]
        ],
      ),
    );
  }
}
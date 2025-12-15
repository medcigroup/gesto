import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../config/Schedule_model_service.dart';
import '../../config/getConnectedUserAdminId.dart';
import '../../widgets/schedule_widget.dart';

// ============================================================================
// PAGE MODERNISÉE DE GESTION DES EMPLOIS DU TEMPS
// ============================================================================

class ModernScheduleManagementPage extends StatefulWidget {
  const ModernScheduleManagementPage({Key? key}) : super(key: key);

  @override
  _ModernScheduleManagementPageState createState() =>
      _ModernScheduleManagementPageState();
}

class _ModernScheduleManagementPageState
    extends State<ModernScheduleManagementPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  DateTime _selectedDate = DateTime.now();
  String? _selectedEmployeeId;
  ViewMode _viewMode = ViewMode.week;
  String? idadmin;
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Cache pour les employés
  List<Employee> _cachedEmployees = [];
  bool _employeesLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupAnimations();
    _initializeFrenchLocale();
    _setupKeyboardShortcuts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
  }

  void _setupKeyboardShortcuts() {
    // Raccourcis clavier pour navigation web
    RawKeyboard.instance.addListener(_handleKeyPress);
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Ctrl/Cmd + N : Nouveau créneau
      if ((event.isControlPressed || event.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyN) {
        _showAddScheduleDialog();
      }
      // Flèche gauche : Semaine précédente
      else if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
          event.isAltPressed) {
        _navigatePrevious();
      }
      // Flèche droite : Semaine suivante
      else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
          event.isAltPressed) {
        _navigateNext();
      }
    }
  }

  Future<void> _initializeFrenchLocale() async {
    await initializeDateFormatting('fr_FR', null);
    Intl.defaultLocale = 'fr_FR';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    RawKeyboard.instance.removeListener(_handleKeyPress);
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
        _errorMessage = null;
      });

      idadmin = await getConnectedUserAdminId();

      if (idadmin == null || idadmin!.isEmpty) {
        throw Exception('ID administrateur non valide');
      }

      await _loadEmployeesCache();

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _employeesLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadEmployeesCache() async {
    if (idadmin == null) return;

    try {
      _cachedEmployees = await EmployeeService.loadEmployees(idadmin!);
    } catch (e) {
      _cachedEmployees = [];
    }
  }

  void _navigatePrevious() {
    setState(() {
      if (_viewMode == ViewMode.week) {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      } else if (_viewMode == ViewMode.month) {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      } else {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      }
    });
  }

  void _navigateNext() {
    setState(() {
      if (_viewMode == ViewMode.week) {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      } else if (_viewMode == ViewMode.month) {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      } else {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : const Color(0xFFF5F7FA),
      body: _buildBody(isDark),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isInitializing) {
      return _buildLoadingScreen(isDark);
    }

    if (_hasError || idadmin == null) {
      return _buildErrorScreen(isDark);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildModernAppBar(isDark),
          Expanded(
            child: Row(
              children: [
                // Sidebar pour grand écran
                if (MediaQuery.of(context).size.width > 1024)
                  _buildSidebar(isDark),
                // Contenu principal
                Expanded(
                  child: Column(
                    children: [
                      _buildTabBar(isDark),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPlanningView(isDark),
                            _buildEmployeeView(isDark),
                            _buildStatisticsView(isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement des données...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erreur d\'initialisation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _initializeData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo et titre
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.tealAccent, Colors.cyanAccent]
                    : [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des Plannings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Organisez vos équipes efficacement',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Barre de recherche
          if (MediaQuery.of(context).size.width > 768)
            Container(
              width: 300,
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A3E)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: isDark ? Colors.white60 : Colors.black54,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher un employé...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 16),

          // Bouton mode d'affichage
          _buildViewModeButton(isDark),

          const SizedBox(width: 12),

          // Bouton ajouter
          ElevatedButton.icon(
            onPressed: _showAddScheduleDialog,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Nouveau'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),

          const SizedBox(width: 12),

          // Menu options
          _buildOptionsMenu(isDark),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A3E)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildViewModeToggle(
            icon: Icons.view_day,
            mode: ViewMode.day,
            isDark: isDark,
          ),
          _buildViewModeToggle(
            icon: Icons.view_week,
            mode: ViewMode.week,
            isDark: isDark,
          ),
          _buildViewModeToggle(
            icon: Icons.calendar_month,
            mode: ViewMode.month,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle({
    required IconData icon,
    required ViewMode mode,
    required bool isDark,
  }) {
    final isSelected = _viewMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.tealAccent : const Color(0xFF3F51B5))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected
              ? (isDark ? Colors.black : Colors.white)
              : (isDark ? Colors.white60 : Colors.black54),
        ),
      ),
    );
  }

  Widget _buildOptionsMenu(bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 50),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.file_download),
              SizedBox(width: 12),
              Text('Exporter'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'print',
          child: Row(
            children: [
              Icon(Icons.print),
              SizedBox(width: 12),
              Text('Imprimer'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings),
              SizedBox(width: 12),
              Text('Paramètres'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calendrier miniature
          _buildMiniCalendar(isDark),
          const Divider(height: 1),

          // Liste des employés rapide
          Expanded(
            child: _buildQuickEmployeeList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendrier',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Aperçu du mois actuel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2A3E)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMMM yyyy', 'fr_FR').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMiniCalendarGrid(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCalendarGrid(bool isDark) {
    DateTime firstDayOfMonth =
    DateTime(_selectedDate.year, _selectedDate.month, 1);
    int daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    int firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        // En-têtes des jours
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
              .map((day) => SizedBox(
            width: 28,
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Grille des jours
        ...List.generate((daysInMonth + firstWeekday - 1) ~/ 7 + 1, (week) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (day) {
                int dayNumber = week * 7 + day - firstWeekday + 2;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox(width: 28, height: 28);
                }

                DateTime currentDay =
                DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
                bool isToday = _isToday(currentDay);
                bool isSelected = _isSameDay(currentDay, _selectedDate);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = currentDay;
                    });
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.tealAccent : const Color(0xFF3F51B5))
                          : isToday
                          ? (isDark
                          ? Colors.tealAccent.withOpacity(0.2)
                          : const Color(0xFF3F51B5).withOpacity(0.1))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickEmployeeList(bool isDark) {
    final filteredEmployees = _cachedEmployees.where((employee) {
      if (_searchQuery.isEmpty) return true;
      return employee.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Équipe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${filteredEmployees.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: filteredEmployees.length,
            itemBuilder: (context, index) {
              final employee = filteredEmployees[index];
              final isSelected = _selectedEmployeeId == employee.id;

              return _buildQuickEmployeeCard(employee, isSelected, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickEmployeeCard(
      Employee employee, bool isSelected, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedEmployeeId = isSelected ? null : employee.id;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                  ? Colors.tealAccent.withOpacity(0.1)
                  : const Color(0xFF3F51B5).withOpacity(0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                color: isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
                width: 1,
              )
                  : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
                  backgroundImage: employee.photoUrl != null
                      ? NetworkImage(employee.photoUrl!)
                      : null,
                  child: employee.photoUrl == null
                      ? Text(
                    employee.name.isNotEmpty
                        ? employee.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        ScheduleUtils.getRoleDisplayName(employee.role),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.tealAccent, Colors.cyanAccent]
                : [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: isDark ? Colors.black : Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_view_week, size: 20),
                SizedBox(width: 8),
                Text('Planning', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Tab(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 20),
                SizedBox(width: 8),
                Text('Employés', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Tab(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 20),
                SizedBox(width: 8),
                Text('Statistiques', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningView(bool isDark) {
    return Column(
      children: [
        _buildModernDateNavigation(isDark),
        if (_cachedEmployees.isNotEmpty) _buildModernEmployeeFilter(isDark),
        Expanded(
          child: _buildScheduleContent(isDark),
        ),
      ],
    );
  }

  Widget _buildModernDateNavigation(bool isDark) {
    String periodText = '';
    if (_viewMode == ViewMode.week) {
      DateTime startOfWeek =
      _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      periodText =
      '${DateFormat('dd MMM', 'fr_FR').format(startOfWeek)} - ${DateFormat('dd MMM', 'fr_FR').format(endOfWeek)}';
    } else if (_viewMode == ViewMode.month) {
      periodText = DateFormat('MMMM yyyy', 'fr_FR').format(_selectedDate);
    } else {
      periodText = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
            const Color(0xFF1E1E2E),
            const Color(0xFF2A2A3E),
          ]
              : [
            Colors.white,
            Colors.grey.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton précédent
          _buildNavigationButton(
            icon: Icons.chevron_left,
            onPressed: _navigatePrevious,
            isDark: isDark,
          ),
          const SizedBox(width: 16),

          // Informations de date
          Expanded(
            child: Column(
              children: [
                Text(
                  periodText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_viewMode == ViewMode.week)
                  Text(
                    'Semaine ${ScheduleUtils.getWeekNumber(_selectedDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Bouton suivant
          _buildNavigationButton(
            icon: Icons.chevron_right,
            onPressed: _navigateNext,
            isDark: isDark,
          ),

          const SizedBox(width: 16),

          // Bouton aujourd'hui
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
              });
            },
            icon: const Icon(Icons.today, size: 18),
            label: const Text('Aujourd\'hui'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: isDark
                  ? Colors.tealAccent.withOpacity(0.1)
                  : const Color(0xFF3F51B5).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A3E)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: isDark ? Colors.white70 : Colors.black87,
        iconSize: 24,
      ),
    );
  }

  Widget _buildModernEmployeeFilter(bool isDark) {
    final filteredEmployees = _cachedEmployees.where((employee) {
      if (_searchQuery.isEmpty) return true;
      return employee.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredEmployees.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildModernFilterChip(
              label: 'Tous',
              count: _cachedEmployees.length,
              isSelected: _selectedEmployeeId == null,
              onTap: () {
                setState(() {
                  _selectedEmployeeId = null;
                });
              },
              isDark: isDark,
            );
          }

          final employee = filteredEmployees[index - 1];
          return _buildModernFilterChip(
            label: employee.name,
            photoUrl: employee.photoUrl,
            isSelected: _selectedEmployeeId == employee.id,
            onTap: () {
              setState(() {
                _selectedEmployeeId = employee.id;
              });
            },
            isDark: isDark,
          );
        },
      ),
    );
  }

  Widget _buildModernFilterChip({
    required String label,
    String? photoUrl,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                colors: isDark
                    ? [Colors.tealAccent, Colors.cyanAccent]
                    : [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
              )
                  : null,
              color: !isSelected
                  ? (isDark
                  ? const Color(0xFF1E1E2E)
                  : Colors.grey.withOpacity(0.1))
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? null
                  : Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: (isDark ? Colors.tealAccent : const Color(0xFF3F51B5))
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (photoUrl != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(photoUrl),
                  )
                else if (count != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : (isDark
                          ? Colors.tealAccent.withOpacity(0.1)
                          : const Color(0xFF3F51B5).withOpacity(0.1)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people,
                      size: 16,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.tealAccent : const Color(0xFF3F51B5)),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : (isDark
                          ? Colors.tealAccent.withOpacity(0.1)
                          : const Color(0xFF3F51B5).withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? Colors.tealAccent : const Color(0xFF3F51B5)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleContent(bool isDark) {
    // Choisir le stream approprié selon le mode d'affichage
    Stream<List<Schedule>> scheduleStream;

    switch (_viewMode) {
      case ViewMode.week:
        scheduleStream = ScheduleService.getSchedulesForWeek(
          _selectedDate,
          employeeId: _selectedEmployeeId,
        );
        break;
      case ViewMode.month:
        scheduleStream = ScheduleService.getSchedulesForMonth(
          _selectedDate,
          employeeId: _selectedEmployeeId,
        );
        break;
      case ViewMode.day:
        scheduleStream = ScheduleService.getSchedulesForDay(
          _selectedDate,
          employeeId: _selectedEmployeeId,
        );
        break;
    }

    return StreamBuilder<List<Schedule>>(
      stream: scheduleStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ Erreur stream: ${snapshot.error}');
          return _buildModernErrorWidget(
              'Erreur lors du chargement des créneaux', isDark);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildModernEmptyState(isDark);
        }

        final schedules = snapshot.data!;
        print('✅ ${schedules.length} créneaux chargés pour le mode $_viewMode');

        switch (_viewMode) {
          case ViewMode.week:
            return _buildModernWeekView(schedules, isDark);
          case ViewMode.month:
            return _buildModernMonthView(schedules, isDark);
          case ViewMode.day:
            return _buildModernDayView(schedules, isDark);
        }
      },
    );
  }

  Widget _buildModernWeekView(List<Schedule> schedules, bool isDark) {
    DateTime startOfWeek =
    _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    List<DateTime> weekDays =
    List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-têtes des jours améliorés
          _buildModernWeekHeader(weekDays, isDark),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: _buildModernTimeGrid(weekDays, schedules, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernWeekHeader(List<DateTime> weekDays, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        children: [
          // Colonne des heures
          SizedBox(
            width: 80,
            child: Text(
              'Heures',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // En-têtes des jours
          ...weekDays.map((day) {
            bool isToday = _isToday(day);
            return Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isToday
                      ? LinearGradient(
                    colors: isDark
                        ? [
                      Colors.tealAccent.withOpacity(0.2),
                      Colors.cyanAccent.withOpacity(0.1)
                    ]
                        : [
                      const Color(0xFF3F51B5).withOpacity(0.2),
                      const Color(0xFF5C6BC0).withOpacity(0.1)
                    ],
                  )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('E', 'fr_FR').format(day).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? (isDark ? Colors.tealAccent : const Color(0xFF3F51B5))
                            : (isDark ? Colors.white60 : Colors.black54),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: isToday
                            ? LinearGradient(
                          colors: isDark
                              ? [Colors.tealAccent, Colors.cyanAccent]
                              : [
                            const Color(0xFF3F51B5),
                            const Color(0xFF5C6BC0)
                          ],
                        )
                            : null,
                        color: !isToday
                            ? (isDark
                            ? const Color(0xFF2A2A3E)
                            : Colors.grey.withOpacity(0.1))
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModernTimeGrid(
      List<DateTime> weekDays, List<Schedule> schedules, bool isDark) {
    List<int> hours = List.generate(24, (index) => index);

    return Column(
      children: hours.map((hour) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              // Colonne des heures avec style moderne
              SizedBox(
                width: 80,
                child: Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 2,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                              Colors.tealAccent.withOpacity(0.3),
                              Colors.transparent
                            ]
                                : [
                              const Color(0xFF3F51B5).withOpacity(0.3),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Colonnes des jours
              ...weekDays.map((day) {
                final daySchedules =
                _getSchedulesForDayAndHour(schedules, day, hour);

                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isToday(day)
                          ? (isDark
                          ? Colors.tealAccent.withOpacity(0.02)
                          : const Color(0xFF3F51B5).withOpacity(0.02))
                          : null,
                      border: Border(
                        left: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: daySchedules.isNotEmpty
                        ? _buildModernScheduleStack(daySchedules, isDark)
                        : Container(),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModernScheduleStack(List<Schedule> schedules, bool isDark) {
    return Stack(
      children: schedules.asMap().entries.map((entry) {
        final index = entry.key;
        final schedule = entry.value;

        return Positioned(
          left: index * 3.0,
          right: 0,
          top: index * 3.0,
          bottom: 0,
          child: _buildModernScheduleCard(schedule, isDark),
        );
      }).toList(),
    );
  }

  Widget _buildModernScheduleCard(Schedule schedule, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _showScheduleDetails(schedule),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  schedule.color.withOpacity(0.9),
                  schedule.color.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: schedule.spansMultipleDays
                  ? Border.all(
                color: Colors.orange,
                width: 2,
              )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: schedule.color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        schedule.employeeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (schedule.spansMultipleDays)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 10,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${DateFormat('HH:mm', 'fr_FR').format(schedule.startTime)} - ${DateFormat('HH:mm', 'fr_FR').format(schedule.endTime)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernMonthView(List<Schedule> schedules, bool isDark) {
    // Grouper les créneaux par jour
    final schedulesByDay = ScheduleUtils.groupSchedulesByDay(schedules);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-têtes des jours de la semaine
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Row(
              children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                  .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          // Grille du calendrier
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: _buildMonthCalendarGrid(schedulesByDay, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendarGrid(
      Map<String, List<Schedule>> schedulesByDay, bool isDark) {
    DateTime firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    DateTime lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    int daysInMonth = lastDayOfMonth.day;
    int firstWeekday = firstDayOfMonth.weekday;

    // Calculer le nombre de semaines à afficher
    int totalCells = daysInMonth + firstWeekday - 1;
    int numberOfWeeks = (totalCells / 7).ceil();

    return Column(
      children: List.generate(numberOfWeeks, (weekIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (dayIndex) {
              int dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 2;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 100));
              }

              DateTime currentDay =
              DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
              String dayKey = DateFormat('yyyy-MM-dd').format(currentDay);
              List<Schedule> daySchedules = schedulesByDay[dayKey] ?? [];

              return Expanded(
                child: _buildMonthDayCell(currentDay, daySchedules, isDark),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildMonthDayCell(
      DateTime day, List<Schedule> schedules, bool isDark) {
    bool isToday = _isToday(day);
    bool hasSchedules = schedules.isNotEmpty;

    double totalHours = schedules.fold(
        0.0, (sum, schedule) => sum + schedule.durationInHours);

    return GestureDetector(
      onTap: () {
        if (hasSchedules) {
          _showDaySchedulesDialog(day, schedules);
        }
      },
      child: Container(
        height: 100,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: isToday
              ? LinearGradient(
            colors: isDark
                ? [
              Colors.tealAccent.withOpacity(0.3),
              Colors.cyanAccent.withOpacity(0.1)
            ]
                : [
              const Color(0xFF3F51B5).withOpacity(0.3),
              const Color(0xFF5C6BC0).withOpacity(0.1)
            ],
          )
              : null,
          color: !isToday
              ? (hasSchedules
              ? (isDark
              ? Colors.tealAccent.withOpacity(0.05)
              : Colors.green.withOpacity(0.05))
              : (isDark
              ? const Color(0xFF2A2A3E)
              : Colors.grey.withOpacity(0.05)))
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? (isDark ? Colors.tealAccent : const Color(0xFF3F51B5))
                : (hasSchedules
                ? (isDark
                ? Colors.tealAccent.withOpacity(0.3)
                : Colors.green.withOpacity(0.3))
                : Colors.transparent),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du jour
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                      color: isToday
                          ? (isDark ? Colors.tealAccent : const Color(0xFF3F51B5))
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  if (hasSchedules)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.tealAccent.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${schedules.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.tealAccent : Colors.green[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Créneaux (afficher les 2 premiers)
            if (hasSchedules)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...schedules.take(1).map((schedule) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: schedule.color.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${DateFormat('HH:mm').format(schedule.startTime)} ${schedule.employeeName}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                      if (schedules.length > 2)
                        Text(
                          '+${schedules.length - 2} autre${schedules.length - 2 > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.free_breakfast,
                    size: 20,
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
              ),
            // Total d'heures en bas
            if (hasSchedules)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.tealAccent.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 10,
                      color: isDark ? Colors.tealAccent : Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${totalHours.toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.tealAccent : Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDaySchedulesDialog(DateTime day, List<Schedule> schedules) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Colors.tealAccent, Colors.cyanAccent]
                              : [
                            const Color(0xFF3F51B5),
                            const Color(0xFF5C6BC0)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE', 'fr_FR').format(day),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMMM yyyy', 'fr_FR').format(day),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Badge du nombre de créneaux
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                        Colors.tealAccent.withOpacity(0.2),
                        Colors.cyanAccent.withOpacity(0.1)
                      ]
                          : [
                        const Color(0xFF3F51B5).withOpacity(0.2),
                        const Color(0xFF5C6BC0).withOpacity(0.1)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${schedules.length} créneau${schedules.length > 1 ? 'x' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Liste des créneaux
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              _showScheduleDetails(schedule);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    schedule.color.withOpacity(0.9),
                                    schedule.color.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: schedule.color.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          schedule.employeeName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              ScheduleUtils.formatTimeRange(
                                                  schedule.startTime,
                                                  schedule.endTime),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.work,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              ScheduleUtils.getShiftDisplayName(
                                                  schedule.shift),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${schedule.durationInHours.toStringAsFixed(1)}h',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernDayView(List<Schedule> schedules, bool isDark) {
    List<int> hours = List.generate(24, (index) => index);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête du jour
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1E2E), const Color(0xFF2A2A3E)]
                    : [Colors.white, Colors.grey.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [Colors.tealAccent, Colors.cyanAccent]
                          : [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE', 'fr_FR').format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.tealAccent.withOpacity(0.2)
                        : const Color(0xFF3F51B5).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${schedules.length} créneau${schedules.length > 1 ? 'x' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Timeline des heures
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: hours.map((hour) {
                  final hourSchedules = schedules.where((schedule) {
                    final scheduleHour = schedule.startTime.hour;
                    return scheduleHour == hour;
                  }).toList();

                  return Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Colonne des heures
                        SizedBox(
                          width: 80,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Text(
                                  '${hour.toString().padLeft(2, '0')}:00',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  height: 2,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [
                                        Colors.tealAccent.withOpacity(0.3),
                                        Colors.transparent
                                      ]
                                          : [
                                        const Color(0xFF3F51B5).withOpacity(0.3),
                                        Colors.transparent
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Créneaux
                        Expanded(
                          child: hourSchedules.isEmpty
                              ? Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.1),
                                ),
                              ),
                            ),
                          )
                              : Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: hourSchedules.map((schedule) {
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showScheduleDetails(schedule),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                schedule.color.withOpacity(0.9),
                                                schedule.color.withOpacity(0.7),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: schedule.color.withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 3,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                  BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      schedule.employeeName,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.access_time,
                                                          size: 12,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          ScheduleUtils.formatTimeRange(
                                                              schedule.startTime,
                                                              schedule.endTime),
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius:
                                                  BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${schedule.durationInHours.toStringAsFixed(1)}h',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeView(bool isDark) {
    if (!_employeesLoaded) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
          ),
        ),
      );
    }

    if (_cachedEmployees.isEmpty) {
      return _buildModernEmptyEmployeeState(isDark);
    }

    final filteredEmployees = _cachedEmployees.where((employee) {
      if (_searchQuery.isEmpty) return true;
      return employee.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200
            ? 4
            : MediaQuery.of(context).size.width > 800
            ? 3
            : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: filteredEmployees.length,
      itemBuilder: (context, index) {
        return _buildModernEmployeeCard(filteredEmployees[index], isDark);
      },
    );
  }

  Widget _buildModernEmployeeCard(Employee employee, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
            const Color(0xFF1E1E2E),
            const Color(0xFF2A2A3E),
          ]
              : [
            Colors.white,
            Colors.grey.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEmployeeScheduleDialog(employee),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: isDark
                          ? Colors.tealAccent.withOpacity(0.2)
                          : const Color(0xFF3F51B5).withOpacity(0.1),
                      backgroundImage: employee.photoUrl != null
                          ? NetworkImage(employee.photoUrl!)
                          : null,
                      child: employee.photoUrl == null
                          ? Text(
                        employee.name.isNotEmpty
                            ? employee.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: isDark
                              ? Colors.tealAccent
                              : const Color(0xFF3F51B5),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [Colors.tealAccent, Colors.cyanAccent]
                                : [
                              const Color(0xFF3F51B5),
                              const Color(0xFF5C6BC0)
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  employee.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.tealAccent.withOpacity(0.1)
                        : const Color(0xFF3F51B5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ScheduleUtils.getRoleDisplayName(employee.role),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsView(bool isDark) {
    return StreamBuilder<List<Schedule>>(
      stream: ScheduleService.getSchedulesForWeek(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildModernErrorWidget(
              'Erreur lors du chargement des statistiques', isDark);
        }

        final schedules = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Statistiques principales en grille
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount:
                MediaQuery.of(context).size.width > 800 ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildModernStatCard(
                    title: 'Heures planifiées',
                    value:
                    '${ScheduleUtils.calculateTotalHours(schedules).toStringAsFixed(1)}h',
                    icon: Icons.access_time,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    isDark: isDark,
                  ),
                  _buildModernStatCard(
                    title: 'Employés actifs',
                    value:
                    '${ScheduleUtils.getUniqueEmployees(schedules).length}',
                    icon: Icons.people,
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    isDark: isDark,
                  ),
                  _buildModernStatCard(
                    title: 'Créneaux',
                    value: '${schedules.length}',
                    icon: Icons.event,
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    isDark: isDark,
                  ),
                  _buildModernStatCard(
                    title: 'Multi-jours',
                    value: '${schedules.where((s) => s.spansMultipleDays).length}',
                    icon: Icons.schedule,
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                    ),
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Répartition par employé
              _buildEmployeeStatsSection(schedules, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeStatsSection(List<Schedule> schedules, bool isDark) {
    Map<String, double> employeeHours = {};

    for (final schedule in schedules) {
      employeeHours[schedule.employeeName] =
          (employeeHours[schedule.employeeName] ?? 0) +
              schedule.durationInHours;
    }

    final sortedEntries = employeeHours.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.tealAccent, Colors.cyanAccent]
                        : [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Répartition par employé',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...sortedEntries.map((entry) {
            final maxHours = sortedEntries.first.value;
            final percentage = (entry.value / maxHours * 100).clamp(0, 100);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? const Color(0xFF2A2A3E)
                          : Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModernEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                  Colors.tealAccent.withOpacity(0.1),
                  Colors.cyanAccent.withOpacity(0.05)
                ]
                    : [
                  const Color(0xFF3F51B5).withOpacity(0.1),
                  const Color(0xFF5C6BC0).withOpacity(0.05)
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule,
              size: 80,
              color: isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun planning pour cette période',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Commencez par créer votre premier créneau',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddScheduleDialog,
            icon: const Icon(Icons.add),
            label: const Text('Créer un créneau'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEmptyEmployeeState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                  Colors.tealAccent.withOpacity(0.1),
                  Colors.cyanAccent.withOpacity(0.05)
                ]
                    : [
                  const Color(0xFF3F51B5).withOpacity(0.1),
                  const Color(0xFF5C6BC0).withOpacity(0.05)
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 80,
              color: isDark ? Colors.tealAccent : const Color(0xFF3F51B5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun employé trouvé',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ajoutez des employés pour commencer',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernErrorWidget(String message, bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddScheduleDialog,
      icon: const Icon(Icons.add),
      label: const Text('Nouveau créneau'),
      elevation: 4,
    );
  }

  // Méthodes utilitaires
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  List<Schedule> _getSchedulesForDayAndHour(
      List<Schedule> schedules, DateTime day, int hour) {
    return schedules.where((schedule) {
      final scheduleStart = schedule.startTime;
      final scheduleEnd = schedule.endTime;

      final cellStart = DateTime(day.year, day.month, day.day, hour, 0);
      final cellEnd = DateTime(day.year, day.month, day.day, hour + 1, 0);

      return scheduleStart.isBefore(cellEnd) && scheduleEnd.isAfter(cellStart);
    }).toList();
  }

  // Méthodes pour les dialogues (utilisation des widgets existants)
  void _showAddScheduleDialog() {
    if (idadmin == null) {
      _showErrorSnackBar('Erreur: ID administrateur non trouvé');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScheduleDialog(
        employees: _cachedEmployees,
        onSave: (schedule) async {
          try {
            await ScheduleService.addSchedule(schedule);
            if (mounted) {
              Navigator.of(context).pop();
              _showSuccessSnackBar('Créneau ajouté avec succès');
            }
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar('Erreur lors de l\'ajout: $e');
            }
          }
        },
        onSaveMultipleDays: (schedule, weekDays, numberOfWeeks) async {
          try {
            final startOfWeek = _selectedDate
                .subtract(Duration(days: _selectedDate.weekday - 1));

            await ScheduleService.addScheduleForMultipleDays(
                schedule, weekDays, startOfWeek, numberOfWeeks);

            if (mounted) {
              Navigator.of(context).pop();
              _showSuccessSnackBar(
                  'Créneaux ajoutés pour ${weekDays.length} jour(s) sur $numberOfWeeks semaine(s)');
            }
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar('Erreur lors de l\'ajout: $e');
            }
          }
        },
      ),
    );
  }

  void _showScheduleDetails(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => ScheduleDetailsDialog(
        schedule: schedule,
        onEdit: () {
          Navigator.of(context).pop();
          _showEditScheduleDialog(schedule);
        },
        onDelete: () async {
          try {
            await ScheduleService.deleteSchedule(schedule.id);
            if (mounted) {
              _showSuccessSnackBar('Créneau supprimé avec succès');
            }
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar('Erreur lors de la suppression: $e');
            }
          }
        },
      ),
    );
  }

  void _showEditScheduleDialog(Schedule schedule) {
    if (idadmin == null) {
      _showErrorSnackBar('Erreur: ID administrateur non trouvé');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScheduleDialog(
        schedule: schedule,
        employees: _cachedEmployees,
        onSave: (updatedSchedule) async {
          try {
            await ScheduleService.updateSchedule(updatedSchedule);
            if (mounted) {
              Navigator.of(context).pop();
              _showSuccessSnackBar('Créneau modifié avec succès');
            }
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar('Erreur lors de la modification: $e');
            }
          }
        },
      ),
    );
  }

  void _showEmployeeScheduleDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => EmployeeScheduleDialog(employee: employee),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Enum pour les modes d'affichage
enum ViewMode { day, week, month }
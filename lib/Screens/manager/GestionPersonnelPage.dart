import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gesto/config/user_model.dart';
import '../../config/LicenseService.dart';
import '../../widgets/side_menu.dart';


class GestionPersonnelPage extends StatefulWidget {
  const GestionPersonnelPage({Key? key}) : super(key: key);

  @override
  _GestionPersonnelPageState createState() => _GestionPersonnelPageState();
}

class _GestionPersonnelPageState extends State<GestionPersonnelPage> {
  String _selectedDepartement = 'Tous';
  bool _isLoading = false;
  List<UserModelPersonnel> _personnelList = [];
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  // Controllers pour le bottom sheet
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  String _selectedPoste = 'Réceptionniste';
  String _nouveauDepartement = 'Accueil';

  // Liste des postes disponibles
  final List<String> _postes = [
    'Réceptionniste',
    'Chef',
    'Agent d\'entretien',
    'Serveur',
    'Manager',
    'Responsable maintenance',
    'Concierge',
    'Responsable accueil',
    'Femme de chambre',
    'Valet'
  ];

  @override
  void initState() {
    super.initState();
    _loadPersonnel();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonnel() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer l'utilisateur connecté
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Utilisateur non connecté');
        return;
      }

      // Récupérer le code entreprise depuis Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        _showErrorSnackBar('Profil utilisateur introuvable');
        return;
      }

      final entrepriseCode = userDoc.data()?['entrepriseCode'] as String?;
      if (entrepriseCode?.isEmpty ?? true) {
        _showErrorSnackBar('Code entreprise non configuré');
        return;
      }

      // Récupération du personnel filtré
      List<UserModelPersonnel> personnel;
      if (_selectedDepartement == 'Tous') {
        personnel = await _authService.getAllStaff(entrepriseCode!);
      } else {
        personnel = await _authService.getStaffByDepartment(
          _selectedDepartement,
          entrepriseCode!,
        );
      }

      // Filtrage supplémentaire par recherche
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        personnel = personnel.where((user) =>
        user.nom.toLowerCase().contains(searchTerm) ||
            user.prenom.toLowerCase().contains(searchTerm) ||
            user.email.toLowerCase().contains(searchTerm) ||
            user.poste.toLowerCase().contains(searchTerm)).toList();
      }

      setState(() {
        _personnelList = personnel;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Erreur de chargement: ${e.toString()}");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showAddEmployeeBottomSheet() async {
    // Vérifier si l'utilisateur peut créer un nouvel employé selon sa licence
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('Utilisateur non connecté');
      return;
    }

    final licenceInfo = await LicenseService.canCreateEmployee(currentUser.uid);

    if (!licenceInfo['canCreate']) {
      // Afficher le dialogue d'information sur la limite de licence
      LicenseService.showLicenceInfoDialog(context, licenceInfo);
      return;
    }

    // Réinitialiser les contrôleurs
    _emailController.clear();
    _passwordController.clear();
    _nomController.clear();
    _prenomController.clear();
    _selectedPoste = 'Réceptionniste';
    _nouveauDepartement = 'Accueil';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetContent(),
    );
  }

  Widget _buildBottomSheetContent() {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Barre de drag
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_add, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Ajouter un employé',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(thickness: 1, color: theme.colorScheme.onSurface.withOpacity(0.1)),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Information personnelles',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Informations de base
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nomController,
                              decoration: InputDecoration(
                                labelText: 'Nom',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _prenomController,
                              decoration: InputDecoration(
                                labelText: 'Prénom',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Email et Mot de passe
                      Text(
                        'Informations de connexion',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Informations professionnelles
                      Text(
                        'Informations professionnelles',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPoste,
                        decoration: InputDecoration(
                          labelText: 'Poste',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.work_outline),
                        ),
                        items: _postes
                            .map((poste) => DropdownMenuItem(
                          value: poste,
                          child: Text(poste),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPoste = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _nouveauDepartement,
                        decoration: InputDecoration(
                          labelText: 'Département',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.business_outlined),
                        ),
                        items: ['Accueil','Cuisine', 'Service', 'Chambres', 'Maintenance']
                            .map((dept) => DropdownMenuItem(
                          value: dept,
                          child: Text(dept),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _nouveauDepartement = value);
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _handleAddEmployee(
                            _emailController.text,
                            _passwordController.text,
                            _nomController.text,
                            _prenomController.text,
                            _selectedPoste,
                            _nouveauDepartement,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                              : const Text('AJOUTER L\'EMPLOYÉ'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _handleAddEmployee(
      String email,
      String password,
      String nom,
      String prenom,
      String poste,
      String departement,
      ) async {
    // Validation des champs
    if (email.isEmpty || password.isEmpty || nom.isEmpty || prenom.isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs obligatoires');
      return false;
    }

    setState(() => _isLoading = true);

    try {
      // Récupérer l'UID de l'utilisateur connecté
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Utilisateur non authentifié');
        return false;
      }

      // Vérifier à nouveau les limites de licence
      final licenceInfo = await LicenseService.canCreateEmployee(currentUser.uid);
      if (!licenceInfo['canCreate']) {
        _showErrorSnackBar(licenceInfo['message']);
        LicenseService.showLicenceInfoDialog(context, licenceInfo);
        return false;
      }

      // Accéder au document de l'utilisateur dans Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        _showErrorSnackBar('Profil utilisateur introuvable');
        return false;
      }

      // Récupérer le code entreprise
      final entrepriseCode = userDoc.data()?['entrepriseCode'] as String?;
      if (entrepriseCode == null || entrepriseCode.isEmpty) {
        _showErrorSnackBar('Code entreprise non configuré');
        return false;
      }

      // Créer le nouvel employé avec le code
      final newEmployee = UserModelPersonnel(
        id: '',
        email: email,
        nom: nom,
        prenom: prenom,
        poste: poste,
        departement: departement,
        dateEmbauche: DateTime.now(),
        statut: 'actif',
        competences: [],
        permissions: [],
        entrepriseCode: entrepriseCode, // Code récupéré de Firestore
        idadmin: currentUser.uid,
      );

      await _authService.createStaffAccount(email, password, newEmployee);
      _showSuccessSnackBar('Employé ajouté avec succès');
      _loadPersonnel();
      Navigator.of(context).pop(); // Fermer le bottom sheet
      return true;
    } catch (e) {
      _showErrorSnackBar('Erreur de création: ${e.toString()}');
      return false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _editEmployee(UserModelPersonnel employee) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _EmployeeEditDialog(
        employee: employee,
        authService: _authService,
        theme: Theme.of(context),
      ),
    );

    if (result == true) {
      _showSuccessSnackBar('Modifications enregistrées');
      _loadPersonnel();
    }
  }

  void _toggleEmployeeStatus(UserModelPersonnel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la modification'),
        content: Text(
            'Voulez-vous vraiment ${employee.statut == 'actif' ? 'désactiver' : 'activer'} ce compte ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        setState(() => _isLoading = true);
        final updatedEmployee = employee.copyWith(
          statut: employee.statut == 'actif' ? 'inactif' : 'actif',
        );
        await _authService.updateStaffInfo(updatedEmployee);
        _loadPersonnel();
      } catch (e) {
        _showErrorSnackBar('Erreur de mise à jour: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.people_alt_outlined, size: 28),
            const SizedBox(width: 12),
            Text(
              'Gestion du Personnel',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white38,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPersonnel,
            tooltip: 'Actualiser',
          ),
          // Afficher une icône d'information sur la licence
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () async {
              final currentUser = _authService.currentUser;
              if (currentUser != null) {
                final licenceInfo = await LicenseService.canCreateEmployee(currentUser.uid);
                LicenseService.showLicenceInfoDialog(context, licenceInfo);
              } else {
                _showErrorSnackBar('Utilisateur non connecté');
              }
            },
            tooltip: 'Infos licence',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEmployeeBottomSheet,
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter un employé'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
              colorScheme.surface,
              colorScheme.surfaceVariant,
              colorScheme.surface,
            ]
                : [
              colorScheme.primaryContainer.withOpacity(0.2),
              colorScheme.background,
              colorScheme.primaryContainer.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchAndFilterBar(theme),
              const SizedBox(height: 16),
              Expanded(
                child: _buildPersonnelTable(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(ThemeData theme) {
    final departments = ['Tous les départements', 'Accueil','Cuisine', 'Service', 'Chambres', 'Maintenance'];
    final String displayValue = _selectedDepartement == 'Tous'
        ? 'Tous les départements'
        : _selectedDepartement;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SearchBar(
              controller: _searchController,
              hintText: 'Rechercher un employé...',
              leading: Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
              trailing: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _loadPersonnel();
                  },
                )
              ],
              onChanged: (value) => _loadPersonnel(),
              elevation: MaterialStateProperty.all(0),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Filtrer par département :',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: DropdownMenu<String>(
                    initialSelection: displayValue,
                    onSelected: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDepartement = value == 'Tous les départements' ? 'Tous' : value;
                        });
                        _loadPersonnel();
                      }
                    },
                    dropdownMenuEntries: departments.map((dept) =>
                        DropdownMenuEntry<String>(value: dept, label: dept)
                    ).toList(),
                    textStyle: theme.textTheme.bodyMedium,
                    menuStyle: MenuStyle(
                      backgroundColor: MaterialStatePropertyAll(theme.colorScheme.surface),
                      elevation: const MaterialStatePropertyAll(4),
                      shape: MaterialStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonnelTable(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_personnelList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun personnel trouvé',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des employés ou modifiez vos filtres',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PaginatedDataTable(
            header: Text(
              'Liste du personnel (${_personnelList.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            rowsPerPage: 8,
            columnSpacing: 16,
            horizontalMargin: 10,
            showCheckboxColumn: false,
            columns: [
              DataColumn(
                label: Text('NOM', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('PRÉNOM', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('POSTE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('DÉPARTEMENT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('STATUT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(
                label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            source: _EmployeeDataSource(
              context: context,
              employees: _personnelList,
              onEdit: _editEmployee,
              onToggleStatus: _toggleEmployeeStatus,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmployeeDataSource extends DataTableSource {
  final BuildContext context;
  final List<UserModelPersonnel> employees;
  final Function(UserModelPersonnel) onEdit;
  final Function(UserModelPersonnel) onToggleStatus;

  _EmployeeDataSource({
    required this.context,
    required this.employees,
    required this.onEdit,
    required this.onToggleStatus,
  });

  @override
  DataRow getRow(int index) {
    final employee = employees[index];
    final theme = Theme.of(context);

    return DataRow(
      cells: [
        DataCell(Text(employee.nom)),
        DataCell(Text(employee.prenom)),
        DataCell(Text(employee.poste)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getDepartmentColor(employee.departement).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              employee.departement,
              style: TextStyle(
                color: _getDepartmentColor(employee.departement),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: employee.statut == 'actif'
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              employee.statut == 'actif' ? 'Actif' : 'Inactif',
              style: TextStyle(
                color: employee.statut == 'actif' ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => onEdit(employee),
                tooltip: 'Modifier',
                color: theme.colorScheme.primary,
              ),
              IconButton(
                icon: Icon(
                  employee.statut == 'actif'
                      ? Icons.block_outlined
                      : Icons.check_circle_outline,
                  size: 20,
                ),
                onPressed: () => onToggleStatus(employee),
                tooltip: employee.statut == 'actif' ? 'Désactiver' : 'Activer',
                color: employee.statut == 'actif' ? Colors.red : Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => employees.length;

  @override
  int get selectedRowCount => 0;

  Color _getDepartmentColor(String department) {
    switch (department) {
      case 'Accueil':
        return Colors.blue;
      case 'Cuisine':
        return Colors.pink;
      case 'Service':
        return Colors.orange;
      case 'Chambres':
        return Colors.purple;
      case 'Maintenance':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class _EmployeeEditDialog extends StatefulWidget {
  final UserModelPersonnel employee;
  final AuthService authService;
  final ThemeData theme;

  const _EmployeeEditDialog({
    required this.employee,
    required this.authService,
    required this.theme,
  });

  @override
  State<_EmployeeEditDialog> createState() => __EmployeeEditDialogState();
}

class __EmployeeEditDialogState extends State<_EmployeeEditDialog> {
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late String _poste;
  late String _departement;
  bool _isSaving = false;

  // Liste des postes disponibles
  final List<String> _postes = [
    'Réceptionniste',
    'Chef',
    'Agent d\'entretien',
    'Serveur',
    'Manager',
    'Responsable maintenance',
    'Concierge',
    'Responsable accueil',
    'Femme de chambre',
    'Valet'
  ];

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.employee.nom);
    _prenomController = TextEditingController(text: widget.employee.prenom);
    _poste = widget.employee.poste;
    _departement = widget.employee.departement;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.theme.colorScheme;

    return AlertDialog(
      title: Text(
        'Modifier employé',
        style: widget.theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomController,
              decoration: InputDecoration(
                labelText: 'Nom',
                prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prenomController,
              decoration: InputDecoration(
                labelText: 'Prénom',
                prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _poste,
              decoration: InputDecoration(
                labelText: 'Poste',
                prefixIcon: Icon(Icons.work_outline, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              dropdownColor: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              items: _postes
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _poste = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _departement,
              decoration: InputDecoration(
                labelText: 'Département',
                prefixIcon: Icon(Icons.business_center_outlined, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              dropdownColor: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              items: ['Accueil', 'Service', 'Chambres', 'Maintenance']
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _departement = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Annuler',
            style: TextStyle(color: colorScheme.secondary),
          ),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveChanges,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            disabledBackgroundColor: colorScheme.primary.withOpacity(0.6),
          ),
          child: _isSaving
              ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.onPrimary,
            ),
          )
              : Text('Enregistrer'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 4,
    );
  }

  Future<void> _saveChanges() async {
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedEmployee = widget.employee.copyWith(
        nom: _nomController.text,
        prenom: _prenomController.text,
        poste: _poste,
        departement: _departement,
      );
      await widget.authService.updateStaffInfo(updatedEmployee);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de mise à jour: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
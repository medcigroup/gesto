import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gesto/config/user_model.dart';
import '../widgets/AddEmployeeTab.dart';
import '../widgets/PersonnelListTab.dart';
import '../widgets/side_menu.dart';

class GestionPersonnelPage extends StatefulWidget {
  const GestionPersonnelPage({Key? key}) : super(key: key);

  @override
  _GestionPersonnelPageState createState() => _GestionPersonnelPageState();
}

class _GestionPersonnelPageState extends State<GestionPersonnelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDepartement = 'Tous';
  bool _isLoading = false;
  List<UserModelPersonnel> _personnelList = [];
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPersonnel();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurple,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'Liste'),
            Tab(icon: Icon(Icons.person_add_alt_1_rounded), text: 'Ajouter'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPersonnel,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const SideMenu(),
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildListTabContent(theme),
            _buildAddTabContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildListTabContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchField(theme),
          const SizedBox(height: 16),
          _buildDepartmentFilter(theme),
          const SizedBox(height: 16),
          Expanded(
            child: PersonnelListTab(
              isLoading: _isLoading,
              personnelList: _personnelList,
              searchController: _searchController,
              selectedDepartement: _selectedDepartement,
              onDepartementChanged: (newValue) {
                if (newValue != null) {
                  setState(() => _selectedDepartement = newValue);
                  _loadPersonnel();
                }
              },
              onSearch: (value) => _loadPersonnel(),
              onRefresh: _loadPersonnel,
              onEditEmployee: _editEmployee,
              onToggleStatus: _toggleEmployeeStatus,
              showSuccessMessage: _showSuccessSnackBar,
              showErrorMessage: _showErrorSnackBar,
              onDeleteEmployee: (UserModelPersonnel ) {  },
              // Pass the box decoration directly without named parameter
              // This assumes PersonnelListTab accepts a BoxDecoration as a positional parameter

            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return SearchBar(
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
      elevation: MaterialStateProperty.all(2.0),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDepartmentFilter(ThemeData theme) {
    final departments = ['Tous les départements', 'Accueil', 'Service', 'Chambres', 'Maintenance'];
    final String displayValue = _selectedDepartement == 'Tous'
        ? 'Tous les départements'
        : _selectedDepartement;

    return Row(
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
    );
  }

  Widget _buildAddTabContent(ThemeData theme) {
    // Create the decoration objects outside of the AddEmployeeTab call
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    final submitButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                AddEmployeeTab(
                  isLoading: _isLoading,
                  onAddEmployee: _handleAddEmployee,
                  submitButtonStyle: submitButtonStyle,

                  // Pass the decorations as positional parameters or correctly named parameters
                  // based on how AddEmployeeTab is defined


                ),
              ],
            ),
          ),
        ],
      ),
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
    setState(() => _isLoading = true);

    try {
      // Récupérer l'UID de l'utilisateur connecté
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Utilisateur non authentifié');
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
      );

      await _authService.createStaffAccount(email, password, newEmployee);
      _showSuccessSnackBar('Employé ajouté avec succès');
      _loadPersonnel();
      _tabController.animateTo(0);
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
  late TextEditingController _posteController;
  late String _departement;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.employee.nom);
    _prenomController = TextEditingController(text: widget.employee.prenom);
    _posteController = TextEditingController(text: widget.employee.poste);
    _departement = widget.employee.departement;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _posteController.dispose();
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
            TextFormField(
              controller: _posteController,
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
        _prenomController.text.isEmpty ||
        _posteController.text.isEmpty) {
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
        poste: _posteController.text,
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
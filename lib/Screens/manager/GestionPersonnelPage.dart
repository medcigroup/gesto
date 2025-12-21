import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gesto/config/user_model.dart';
import 'package:provider/provider.dart';
import '../../config/LicenseService.dart';
import '../../LicenseFeatures.dart';


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

  // Liste complète des postes
  final List<String> _tousLesPostes = [
    'Réceptionniste',
    'Chef',
    'Agent d\'entretien',
    'Serveur',
    'Manager',
    'Responsable maintenance',
    'Concierge',
    'Responsable accueil',
    'Personnel de chambre',
    'Caissier',
    'Barman'
  ];

  // Postes nécessitant un plan Pro ou supérieur
  final List<String> _postesProOnly = [
    'Caissier',
    'Barman',
    'Serveur',
    'Chef'
  ];

  // Liste filtrée des postes selon la licence
  List<String> get _postes {
    final licenseManager = Provider.of<LicenseManager>(context, listen: false);
    final licenseType = licenseManager.currentLicenseType;
    
    // Si plan Pro ou Entreprise, tous les postes sont disponibles
    if (licenseType == LicenseType.pro || licenseType == LicenseType.entreprise) {
      return _tousLesPostes;
    }
    
    // Sinon (Basic ou Starter), exclure les postes Pro
    return _tousLesPostes.where((poste) => !_postesProOnly.contains(poste)).toList();
  }

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
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Barre de drag
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajouter un employé',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Remplissez les informations ci-dessous',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outline.withAlpha(30)),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withAlpha(60),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Informations personnelles',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 24),
                      // Email et Mot de passe
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withAlpha(60),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.secondary.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Informations de connexion',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 24),
                      // Informations professionnelles
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer.withAlpha(60),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.tertiary.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.work_outline_rounded,
                              color: colorScheme.tertiary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Informations professionnelles',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      // Message informatif si certains postes sont bloqués
                      if (_postes.length < _tousLesPostes.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Les postes de restaurant (Chef, Serveur, Caissier, Barman) nécessitent un plan Pro ou supérieur.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                        items: ['Accueil','Cuisine', 'Service', 'Chambres', 'Maintenance', 'Restaurant']
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
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: _isLoading
                                ? [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainerHighest]
                                : [colorScheme.primary, colorScheme.primary.withAlpha(200)],
                          ),
                          boxShadow: _isLoading
                              ? null
                              : [
                                  BoxShadow(
                                    color: colorScheme.primary.withAlpha(60),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
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
                            backgroundColor: Colors.transparent,
                            foregroundColor: colorScheme.onPrimary,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: colorScheme.onPrimary,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Création en cours...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.person_add_rounded, size: 22),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Ajouter l\'employé',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: employee.statut == 'actif'
                    ? Colors.red.withAlpha(40)
                    : Colors.green.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                employee.statut == 'actif'
                    ? Icons.block_rounded
                    : Icons.check_circle_rounded,
                color: employee.statut == 'actif'
                    ? Colors.red.shade700
                    : Colors.green.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Confirmer l\'action'),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment ${employee.statut == 'actif' ? 'désactiver' : 'activer'} le compte de ${employee.prenom} ${employee.nom} ?',
          style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: employee.statut == 'actif'
                  ? Colors.red.shade700
                  : Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              employee.statut == 'actif' ? 'Désactiver' : 'Activer',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.surface,
        elevation: 8,
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.people_alt_rounded,
                size: 24,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Gestion du Personnel',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
            onPressed: _loadPersonnel,
            tooltip: 'Actualiser',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: colorScheme.primary),
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
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEmployeeBottomSheet,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.3),
              colorScheme.surface,
            ]
                : [
              colorScheme.primaryContainer.withOpacity(0.1),
              colorScheme.surface,
              colorScheme.secondaryContainer.withOpacity(0.05),
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
    final departments = ['Tous les départements', 'Accueil','Cuisine', 'Service', 'Chambres', 'Maintenance','Restaurant'];
    final String displayValue = _selectedDepartement == 'Tous'
        ? 'Tous les départements'
        : _selectedDepartement;
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      shadowColor: colorScheme.shadow.withAlpha(25),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withAlpha(30),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recherche et Filtres',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(60),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withAlpha(40),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _loadPersonnel(),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, prénom, email ou poste...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              _loadPersonnel();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.business_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Département :',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
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
                          DropdownMenuEntry<String>(
                            value: dept,
                            label: dept,
                            leadingIcon: Icon(
                              Icons.label_rounded,
                              size: 18,
                              color: _getDepartmentColor(dept == 'Tous les départements' ? 'Tous' : dept),
                            ),
                          )
                      ).toList(),
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      menuStyle: MenuStyle(
                        backgroundColor: WidgetStatePropertyAll(colorScheme.surface),
                        elevation: const WidgetStatePropertyAll(8),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colorScheme.outline),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      case 'Restaurant':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPersonnelTable(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Chargement du personnel...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_personnelList.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surfaceContainerLowest,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withAlpha(30),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(80),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline_rounded,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucun personnel trouvé',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez des employés ou modifiez vos filtres',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _showAddEmployeeBottomSheet,
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('Ajouter un employé'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withAlpha(30),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.badge_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Liste du personnel',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_personnelList.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outline.withAlpha(30)),
            Expanded(
              child: SingleChildScrollView(
                child: PaginatedDataTable(
                  rowsPerPage: 8,
                  columnSpacing: 24,
                  horizontalMargin: 20,
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStateProperty.all(
                    colorScheme.surfaceContainerHighest.withAlpha(60),
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        'NOM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'PRÉNOM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'POSTE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'DÉPARTEMENT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'STATUT',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'ACTIONS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
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
          ],
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
    final colorScheme = theme.colorScheme;

    return DataRow(
      cells: [
        DataCell(
          Text(
            employee.nom,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        DataCell(
          Text(
            employee.prenom,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              Icon(
                Icons.work_outline_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                employee.poste,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getDepartmentColor(employee.departement).withAlpha(40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getDepartmentColor(employee.departement).withAlpha(100),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business_rounded,
                  size: 14,
                  color: _getDepartmentColor(employee.departement),
                ),
                const SizedBox(width: 6),
                Text(
                  employee.departement,
                  style: TextStyle(
                    color: _getDepartmentColor(employee.departement),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: employee.statut == 'actif'
                  ? Colors.green.withAlpha(40)
                  : Colors.red.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: employee.statut == 'actif'
                    ? Colors.green.withAlpha(100)
                    : Colors.red.withAlpha(100),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  employee.statut == 'actif'
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 14,
                  color: employee.statut == 'actif' ? Colors.green.shade700 : Colors.red.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  employee.statut == 'actif' ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    color: employee.statut == 'actif' ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  onPressed: () => onEdit(employee),
                  tooltip: 'Modifier',
                  color: colorScheme.primary,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: employee.statut == 'actif'
                      ? Colors.red.withAlpha(40)
                      : Colors.green.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    employee.statut == 'actif'
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    size: 18,
                  ),
                  onPressed: () => onToggleStatus(employee),
                  tooltip: employee.statut == 'actif' ? 'Désactiver' : 'Activer',
                  color: employee.statut == 'actif' ? Colors.red.shade700 : Colors.green.shade700,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
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
        return Colors.blue.shade700;
      case 'Cuisine':
        return Colors.pink.shade700;
      case 'Service':
        return Colors.orange.shade700;
      case 'Chambres':
        return Colors.purple.shade700;
      case 'Maintenance':
        return Colors.teal.shade700;
      case 'Restaurant':
        return Colors.deepOrange.shade700;
      default:
        return Colors.grey.shade700;
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

  // Liste complète des postes
  final List<String> _tousLesPostes = [
    'Réceptionniste',
    'Chef',
    'Agent d\'entretien',
    'Serveur',
    'Manager',
    'Responsable maintenance',
    'Concierge',
    'Responsable accueil',
    'Personnel de chambre',
    'Caissier',
    'Barman'
  ];

  // Postes nécessitant un plan Pro ou supérieur
  final List<String> _postesProOnly = [
    'Caissier',
    'Barman',
    'Serveur',
    'Chef'
  ];

  // Liste filtrée des postes selon la licence
  List<String> get _postes {
    final licenseManager = Provider.of<LicenseManager>(context, listen: false);
    final licenseType = licenseManager.currentLicenseType;
    
    // Si plan Pro ou Entreprise, tous les postes sont disponibles
    if (licenseType == LicenseType.pro || licenseType == LicenseType.entreprise) {
      return _tousLesPostes;
    }
    
    // Sinon (Basic ou Starter), exclure les postes Pro
    return _tousLesPostes.where((poste) => !_postesProOnly.contains(poste)).toList();
  }

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
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.edit_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Modifier l\'employé',
            style: widget.theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
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
            // Message informatif si certains postes sont bloqués
            if (_postes.length < _tousLesPostes.length)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Les postes de restaurant nécessitent un plan Pro ou supérieur.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
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
              items: ['Accueil','Cuisine', 'Service', 'Chambres', 'Maintenance', 'Restaurant']
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
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Annuler',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveChanges,
          icon: _isSaving
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.save_rounded, size: 20),
          label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            disabledBackgroundColor: colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 8,
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
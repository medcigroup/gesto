import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/getConnectedUserAdminId.dart';
import '../components/checkin/options_package_section.dart';


class HotelPackagesManagement extends StatefulWidget {
  @override
  _HotelPackagesManagementState createState() => _HotelPackagesManagementState();
}

class _HotelPackagesManagementState extends State<HotelPackagesManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HotelPackage> _packages = [];
  bool _isLoading = true;
  String? _userId;
  String _selectedCategory = 'all';

  // Liste des catégories disponibles
  final List<Map<String, dynamic>> _categories = [
    {'key': 'all', 'name': 'Toutes', 'icon': Icons.grid_view, 'color': Colors.grey},
    {'key': 'breakfast', 'name': 'Restauration', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'key': 'amenities', 'name': 'Équipements', 'icon': Icons.pool, 'color': Colors.blue},
    {'key': 'services', 'name': 'Services', 'icon': Icons.room_service, 'color': Colors.green},
    {'key': 'transport', 'name': 'Transport', 'icon': Icons.airport_shuttle, 'color': Colors.purple},
    {'key': 'wellness', 'name': 'Bien-être', 'icon': Icons.spa, 'color': Colors.pink},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      _userId = await getConnectedUserAdminId();
      await _loadPackages();
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage('Erreur lors de l\'initialisation');
      }
    }
  }

  Future<void> _loadPackages() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final packages = await PackageService.getAllHotelPackages(_userId!);
      if (mounted) {
        setState(() {
          _packages = packages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage('Erreur lors du chargement des packages');
      }
    }
  }

  List<HotelPackage> get _filteredPackages {
    if (_selectedCategory == 'all') {
      return _packages;
    }
    return _packages.where((package) => package.category == _selectedCategory).toList();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPackageDialog({HotelPackage? package}) {
    showDialog(
      context: context,
      builder: (context) => PackageFormDialog(
        package: package,
        userId: _userId!,
        onSaved: () {
          _loadPackages();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _deletePackage(HotelPackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmer la suppression'),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le package "${package.name}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await PackageService.deletePackage(package.id);
                Navigator.of(context).pop();
                _showSuccessMessage('Package supprimé avec succès');
                _loadPackages();
              } catch (e) {
                Navigator.of(context).pop();
                _showErrorMessage('Erreur lors de la suppression');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: Text('Gestion des Options & Packages'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: Icon(Icons.view_list),
              text: 'Mes Packages',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Statistiques',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Liste des Packages
          _buildPackagesTab(),
          // Onglet Statistiques
          _buildStatsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPackageDialog(),
        backgroundColor: Theme.of(context).primaryColor,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Nouveau Package', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildPackagesTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Chargement des packages...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filtres par catégorie
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category['key'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category['key'];
                  });
                },
                child: Container(
                  width: 80,
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? category['color'] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? category['color'] : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'],
                        color: isSelected ? Colors.white : category['color'],
                        size: 28,
                      ),
                      SizedBox(height: 8),
                      Text(
                        category['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Liste des packages
        Expanded(
          child: _filteredPackages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _filteredPackages.length,
            itemBuilder: (context, index) {
              final package = _filteredPackages[index];
              return _buildPackageCard(package);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard(HotelPackage package) {
    final categoryData = _categories.firstWhere(
          (cat) => cat['key'] == package.category,
      orElse: () => _categories.last,
    );

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPackageDialog(package: package),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryData['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      categoryData['icon'],
                      color: categoryData['color'],
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                package.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: package.isIncluded ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                package.isIncluded ? 'GRATUIT' : 'PAYANT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          categoryData['name'],
                          style: TextStyle(
                            color: categoryData['color'],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showPackageDialog(package: package);
                      } else if (value == 'delete') {
                        _deletePackage(package);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (package.description.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  package.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 20),
          Text(
            _selectedCategory == 'all'
                ? 'Aucun package créé'
                : 'Aucun package dans cette catégorie',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Créez votre premier package pour offrir plus de services à vos clients',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _showPackageDialog(),
            icon: Icon(Icons.add),
            label: Text('Créer un package'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final totalPackages = _packages.length;
    final freePackages = _packages.where((p) => p.isIncluded).length;
    final paidPackages = _packages.where((p) => !p.isIncluded).length;

    // Statistiques par catégorie
    Map<String, int> categoryStats = {};
    for (var package in _packages) {
      categoryStats[package.category] = (categoryStats[package.category] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vue d\'ensemble',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // Cartes de statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Packages',
                  totalPackages.toString(),
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Gratuits',
                  freePackages.toString(),
                  Icons.card_giftcard,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Payants',
                  paidPackages.toString(),
                  Icons.monetization_on,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Catégories',
                  categoryStats.length.toString(),
                  Icons.category,
                  Colors.purple,
                ),
              ),
            ],
          ),

          SizedBox(height: 30),
          Text(
            'Répartition par catégorie',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          // Statistiques par catégorie
          ...categoryStats.entries.map((entry) {
            final categoryData = _categories.firstWhere(
                  (cat) => cat['key'] == entry.key,
              orElse: () => {'name': entry.key, 'icon': Icons.help, 'color': Colors.grey},
            );

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    categoryData['icon'],
                    color: categoryData['color'],
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryData['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: categoryData['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.value} package${entry.value > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: categoryData['color'],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog pour créer/modifier un package
class PackageFormDialog extends StatefulWidget {
  final HotelPackage? package;
  final String userId;
  final VoidCallback onSaved;

  const PackageFormDialog({
    Key? key,
    this.package,
    required this.userId,
    required this.onSaved,
  }) : super(key: key);

  @override
  _PackageFormDialogState createState() => _PackageFormDialogState();
}

class _PackageFormDialogState extends State<PackageFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _selectedCategory = 'amenities';
  String _selectedIcon = 'check_circle';
  bool _isIncluded = true;
  bool _isLoading = false;

  // Liste des icônes disponibles
  final Map<String, IconData> _availableIcons = {
    'restaurant': Icons.restaurant,
    'pool': Icons.pool,
    'wifi': Icons.wifi,
    'parking': Icons.local_parking,
    'gym': Icons.fitness_center,
    'spa': Icons.spa,
    'coffee': Icons.local_cafe,
    'breakfast': Icons.free_breakfast,
    'room_service': Icons.room_service,
    'laundry': Icons.local_laundry_service,
    'concierge': Icons.support_agent,
    'airport': Icons.airport_shuttle,
    'pet': Icons.pets,
    'business': Icons.business_center,
    'check_circle': Icons.check_circle,
  };

  final List<Map<String, dynamic>> _categories = [
    {'key': 'breakfast', 'name': 'Restauration'},
    {'key': 'amenities', 'name': 'Équipements'},
    {'key': 'services', 'name': 'Services'},
    {'key': 'transport', 'name': 'Transport'},
    {'key': 'wellness', 'name': 'Bien-être'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.package?.name ?? '');
    _descriptionController = TextEditingController(text: widget.package?.description ?? '');
    if (widget.package != null) {
      _selectedCategory = widget.package!.category;
      _selectedIcon = widget.package!.icon;
      _isIncluded = widget.package!.isIncluded;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final package = HotelPackage(
        id: widget.package?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        icon: _selectedIcon,
        isIncluded: _isIncluded,
        category: _selectedCategory,
      );

      if (widget.package != null) {
        await PackageService.updatePackage(widget.package!.id, package);
      } else {
        await PackageService.addPackage(widget.userId, package);
      }

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.package != null ? Icons.edit : Icons.add,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.package != null ? 'Modifier le package' : 'Nouveau package',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Formulaire
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du package
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nom du package*',
                          hintText: 'Ex: Petit-déjeuner continental',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Décrivez le package...',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 3,
                      ),

                      SizedBox(height: 20),

                      // Catégorie
                      Text(
                        'Catégorie*',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['key'],
                            child: Text(cat['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),

                      SizedBox(height: 20),

                      // Icône
                      Text(
                        'Icône',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: GridView.builder(
                          padding: EdgeInsets.all(8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _availableIcons.length,
                          itemBuilder: (context, index) {
                            final entry = _availableIcons.entries.elementAt(index);
                            final isSelected = _selectedIcon == entry.key;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIcon = entry.key;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                                  ),
                                ),
                                child: Icon(
                                  entry.value,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 20),

                      // Type (Gratuit/Payant)
                      Text(
                        'Type*',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isIncluded = true),
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _isIncluded ? Colors.green.shade50 : Colors.grey.shade100,
                                  border: Border.all(
                                    color: _isIncluded ? Colors.green : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.card_giftcard,
                                      color: _isIncluded ? Colors.green : Colors.grey.shade600,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Gratuit',
                                      style: TextStyle(
                                        color: _isIncluded ? Colors.green : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isIncluded = false),
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: !_isIncluded ? Colors.orange.shade50 : Colors.grey.shade100,
                                  border: Border.all(
                                    color: !_isIncluded ? Colors.orange : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.monetization_on,
                                      color: !_isIncluded ? Colors.orange : Colors.grey.shade600,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Payant',
                                      style: TextStyle(
                                        color: !_isIncluded ? Colors.orange : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Boutons
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text('Annuler'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePackage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(widget.package != null ? 'Modifier' : 'Créer'),
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
}
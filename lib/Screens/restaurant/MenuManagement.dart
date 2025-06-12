import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/getConnectedUserAdminId.dart';
import '../../config/restaurant_models.dart';

class MenuManagement extends StatefulWidget {
  @override
  _MenuManagementState createState() => _MenuManagementState();
}

class _MenuManagementState extends State<MenuManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _userId;
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tous';

  // Catégories du menu
  final List<Map<String, dynamic>> _categories = [
    {'key': 'Tous', 'name': 'Tous', 'icon': Icons.restaurant_menu, 'color': Colors.grey},
    {'key': 'Entrées', 'name': 'Entrées', 'icon': Icons.local_dining, 'color': Colors.green},
    {'key': 'Plats principaux', 'name': 'Plats principaux', 'icon': Icons.dinner_dining, 'color': Colors.red},
    {'key': 'Desserts', 'name': 'Desserts', 'icon': Icons.cake, 'color': Colors.pink},
    {'key': 'Boissons', 'name': 'Boissons', 'icon': Icons.local_drink, 'color': Colors.blue},
    {'key': 'Vins', 'name': 'Vins', 'icon': Icons.wine_bar, 'color': Colors.purple},
    {'key': 'Cocktails', 'name': 'Cocktails', 'icon': Icons.local_bar, 'color': Colors.orange},
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
      await _loadMenuItems();
    } catch (e) {
      print('❌ Erreur initialisation menu: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMenuItems() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final items = await RestaurantService.getMenuItems(_userId!);
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement menu: $e');
      setState(() => _isLoading = false);
      _showErrorMessage('Erreur lors du chargement du menu');
    }
  }

  List<MenuItem> get _filteredMenuItems {
    if (_selectedCategory == 'Tous') {
      return _menuItems;
    }
    return _menuItems.where((item) => item.category == _selectedCategory).toList();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        title: Text('Gestion du Menu'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistiques'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMenuItems,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTab(),
          _buildStatsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMenuItemDialog(),
        backgroundColor: Colors.deepOrange,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Nouvel Article', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildMenuTab() {
    return Column(
      children: [
        _buildCategoriesFilter(),
        _buildMenuStats(),
        Expanded(child: _buildMenuList()),
      ],
    );
  }

  Widget _buildCategoriesFilter() {
    return Container(
      height: 120,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Catégories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
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
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: category['color'].withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'],
                          color: isSelected ? Colors.white : category['color'],
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          category['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontSize: 10,
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
        ],
      ),
    );
  }

  Widget _buildMenuStats() {
    final filteredItems = _filteredMenuItems;
    final availableCount = filteredItems.where((item) => item.isAvailable).length;
    final unavailableCount = filteredItems.where((item) => !item.isAvailable).length;
    final avgPrice = filteredItems.isNotEmpty
        ? filteredItems.map((item) => item.price).reduce((a, b) => a + b) / filteredItems.length
        : 0.0;

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(child: _buildStatChip('Articles', filteredItems.length.toString(), Colors.blue)),
          SizedBox(width: 8),
          Expanded(child: _buildStatChip('Disponibles', availableCount.toString(), Colors.green)),
          SizedBox(width: 8),
          Expanded(child: _buildStatChip('Indisponibles', unavailableCount.toString(), Colors.red)),
          SizedBox(width: 8),
          Expanded(child: _buildStatChip('Prix moy.', '${avgPrice.toStringAsFixed(0)} F', Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    final filteredItems = _filteredMenuItems;

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _selectedCategory == 'Tous'
                  ? 'Aucun article dans le menu'
                  : 'Aucun article dans cette catégorie',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Ajoutez votre premier article',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildMenuItemCard(item);
      },
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final categoryData = _categories.firstWhere(
          (cat) => cat['key'] == item.category,
      orElse: () => _categories.first,
    );

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMenuItemDialog(item: item),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Image ou icône
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: categoryData['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(item.imageUrl!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                    ? Icon(categoryData['icon'], color: categoryData['color'], size: 24)
                    : null,
              ),

              SizedBox(width: 16),

              // Informations de l'article
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isAvailable ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.isAvailable ? 'Disponible' : 'Indisponible',
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
                      item.category,
                      style: TextStyle(
                        color: categoryData['color'],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (item.description.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.price.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '~${item.preparationTime} min',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menu d'actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showMenuItemDialog(item: item);
                      break;
                    case 'toggle':
                      _toggleItemAvailability(item);
                      break;
                    case 'delete':
                      _confirmDeleteItem(item);
                      break;
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
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          item.isAvailable ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                          color: item.isAvailable ? Colors.orange : Colors.green,
                        ),
                        SizedBox(width: 8),
                        Text(item.isAvailable ? 'Rendre indisponible' : 'Rendre disponible'),
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
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    // Statistiques par catégorie
    Map<String, int> categoryStats = {};
    Map<String, double> categoryRevenue = {};

    for (var item in _menuItems) {
      categoryStats[item.category] = (categoryStats[item.category] ?? 0) + 1;
      categoryRevenue[item.category] = (categoryRevenue[item.category] ?? 0) + item.price;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques du Menu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // Vue d'ensemble
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Articles',
                  _menuItems.length.toString(),
                  Icons.restaurant_menu,
                  Colors.blue,
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

          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Disponibles',
                  _menuItems.where((item) => item.isAvailable).length.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Indisponibles',
                  _menuItems.where((item) => !item.isAvailable).length.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),

          SizedBox(height: 30),

          Text(
            'Répartition par catégorie',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryData['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Prix moyen: ${(categoryRevenue[entry.key]! / entry.value).toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: categoryData['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.value} article${entry.value > 1 ? 's' : ''}',
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

  void _showMenuItemDialog({MenuItem? item}) {
    showDialog(
      context: context,
      builder: (context) => MenuItemFormDialog(
        item: item,
        userId: _userId!,
        onSaved: _loadMenuItems,
      ),
    );
  }

  Future<void> _toggleItemAvailability(MenuItem item) async {
    try {
      await RestaurantService.toggleMenuItemAvailability(item.id, !item.isAvailable);
      _showSuccessMessage('Disponibilité mise à jour');
      _loadMenuItems();
    } catch (e) {
      _showErrorMessage('Erreur lors de la mise à jour');
    }
  }

  void _confirmDeleteItem(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${item.name}" du menu ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('restaurant_menu')
                    .doc(item.id)
                    .delete();
                Navigator.pop(context);
                _showSuccessMessage('Article supprimé');
                _loadMenuItems();
              } catch (e) {
                Navigator.pop(context);
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
}

// Dialog pour créer/modifier un article du menu
class MenuItemFormDialog extends StatefulWidget {
  final MenuItem? item;
  final String userId;
  final VoidCallback onSaved;

  const MenuItemFormDialog({
    Key? key,
    this.item,
    required this.userId,
    required this.onSaved,
  }) : super(key: key);

  @override
  _MenuItemFormDialogState createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends State<MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _preparationTimeController;
  late TextEditingController _imageUrlController;

  String _selectedCategory = 'Entrées';
  bool _isAvailable = true;
  List<String> _selectedAllergens = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Entrées', 'Plats principaux', 'Desserts', 'Boissons', 'Vins', 'Cocktails'
  ];

  final List<String> _allergens = [
    'Gluten', 'Lactose', 'Œufs', 'Poisson', 'Crustacés', 'Arachides',
    'Fruits à coque', 'Soja', 'Céleri', 'Moutarde', 'Sésame', 'Sulfites'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(text: widget.item?.price.toString() ?? '');
    _preparationTimeController = TextEditingController(text: widget.item?.preparationTime.toString() ?? '15');
    _imageUrlController = TextEditingController(text: widget.item?.imageUrl ?? '');

    if (widget.item != null) {
      _selectedCategory = widget.item!.category;
      _isAvailable = widget.item!.isAvailable;
      _selectedAllergens = List.from(widget.item!.allergens);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _preparationTimeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final item = MenuItem(
        id: widget.item?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        isAvailable: _isAvailable,
        allergens: _selectedAllergens,
        preparationTime: int.parse(_preparationTimeController.text),
        userId: widget.userId,
      );

      if (widget.item != null) {
        await RestaurantService.updateMenuItem(widget.item!.id, item);
      } else {
        await RestaurantService.addMenuItem(item);
      }

      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.item != null ? Icons.edit : Icons.add,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item != null ? 'Modifier l\'article' : 'Nouvel article',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
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
                      // Nom
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nom de l\'article*',
                          prefixIcon: Icon(Icons.restaurant_menu),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 3,
                      ),

                      SizedBox(height: 16),

                      // Prix et catégorie
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Prix (FCFA)*',
                                prefixIcon: Icon(Icons.attach_money),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Le prix est requis';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Prix invalide';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Catégorie',
                                prefixIcon: Icon(Icons.category),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(value: category, child: Text(category));
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCategory = value!);
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Temps de préparation
                      TextFormField(
                        controller: _preparationTimeController,
                        decoration: InputDecoration(
                          labelText: 'Temps de préparation (minutes)',
                          prefixIcon: Icon(Icons.timer),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le temps de préparation est requis';
                          }
                          final time = int.tryParse(value);
                          if (time == null || time <= 0) {
                            return 'Temps invalide';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // URL de l'image
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          labelText: 'URL de l\'image (optionnel)',
                          prefixIcon: Icon(Icons.image),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Disponibilité
                      Row(
                        children: [
                          Text(
                            'Disponibilité:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 16),
                          Switch(
                            value: _isAvailable,
                            onChanged: (value) {
                              setState(() => _isAvailable = value);
                            },
                            activeColor: Colors.green,
                          ),
                          Text(
                            _isAvailable ? 'Disponible' : 'Indisponible',
                            style: TextStyle(
                              color: _isAvailable ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Allergènes
                      Text(
                        'Allergènes:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _allergens.map((allergen) {
                          final isSelected = _selectedAllergens.contains(allergen);
                          return FilterChip(
                            label: Text(allergen),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAllergens.add(allergen);
                                } else {
                                  _selectedAllergens.remove(allergen);
                                }
                              });
                            },
                            selectedColor: Colors.orange.withOpacity(0.3),
                            checkmarkColor: Colors.orange,
                          );
                        }).toList(),
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
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveMenuItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : Text(widget.item != null ? 'Modifier' : 'Créer'),
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
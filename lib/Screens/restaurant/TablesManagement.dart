import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/getConnectedUserAdminId.dart';
import '../../config/restaurant_models.dart';

class TablesManagement extends StatefulWidget {
  @override
  _TablesManagementState createState() => _TablesManagementState();
}

class _TablesManagementState extends State<TablesManagement> with TickerProviderStateMixin {
  String? _userId;
  List<RestaurantTable> _tables = [];
  bool _isLoading = true;
  String _selectedLocation = 'Tous';
  String _selectedStatus = 'Tous';
  late AnimationController _animationController;

  // Filtres avec icônes
  final List<Map<String, dynamic>> _locations = [
    {'value': 'Tous', 'icon': Icons.all_inclusive},
    {'value': 'Intérieur', 'icon': Icons.home_outlined},
    {'value': 'Terrasse', 'icon': Icons.deck_outlined},
    {'value': 'VIP', 'icon': Icons.star_border},
    {'value': 'Bar', 'icon': Icons.local_bar_outlined},
    {'value': 'Jardin', 'icon': Icons.nature_outlined},
  ];

  final List<Map<String, dynamic>> _statuses = [
    {'value': 'Tous', 'icon': Icons.all_inclusive},
    {'value': 'libre', 'icon': Icons.check_circle_outline},
    {'value': 'occupée', 'icon': Icons.people},
    {'value': 'réservée', 'icon': Icons.bookmark_border},
    {'value': 'maintenance', 'icon': Icons.build_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      _userId = await getConnectedUserAdminId();
      await _loadTables();
      _animationController.forward();
    } catch (e) {
      print('❌ Erreur initialisation tables: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTables() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final tables = await RestaurantService.getTables(_userId!);
      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement tables: $e');
      setState(() => _isLoading = false);
      _showErrorMessage('Erreur lors du chargement des tables');
    }
  }

  List<RestaurantTable> get _filteredTables {
    return _tables.where((table) {
      final locationMatch = _selectedLocation == 'Tous' || table.location == _selectedLocation;
      final statusMatch = _selectedStatus == 'Tous' || table.status == _selectedStatus;
      return locationMatch && statusMatch;
    }).toList();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepOrange.shade600, Colors.deepOrange.shade400],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: Text(
          'Gestion des Tables',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, size: 24),
              onPressed: _loadTables,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Chargement des tables...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      )
          : AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _animationController,
            child: Column(
              children: [
                _buildFiltersSection(),
                _buildStatsSection(),
                Expanded(child: _buildTablesGrid()),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepOrange.shade600, Colors.deepOrange.shade400],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showTableDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: Colors.deepOrange, size: 20),
              SizedBox(width: 8),
              Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildModernDropdown('Emplacement', _selectedLocation, _locations, (value) {
                setState(() => _selectedLocation = value!);
              })),
              SizedBox(width: 16),
              Expanded(child: _buildModernDropdown('Statut', _selectedStatus, _statuses, (value) {
                setState(() => _selectedStatus = value!);
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown(String label, String value, List<Map<String, dynamic>> items, Function(String?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          prefixIcon: Icon(_getIconForValue(value, items), color: Colors.deepOrange, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: Colors.white,
        items: items.map<DropdownMenuItem<String>>((item) {
          return DropdownMenuItem<String>(
            value: item['value'],
            child: Row(
              children: [
                Icon(item['icon'], size: 18, color: Colors.grey.shade600),
                SizedBox(width: 8),
                Text(
                  item['value'] == 'Tous' ? item['value'] : _getStatusDisplayName(item['value']),
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  IconData _getIconForValue(String value, List<Map<String, dynamic>> items) {
    final item = items.firstWhere((item) => item['value'] == value, orElse: () => items.first);
    return item['icon'];
  }

  Widget _buildStatsSection() {
    final filteredTables = _filteredTables;
    final freeCount = filteredTables.where((t) => t.status == 'libre').length;
    final occupiedCount = filteredTables.where((t) => t.status == 'occupée').length;
    final reservedCount = filteredTables.where((t) => t.status == 'réservée').length;
    final maintenanceCount = filteredTables.where((t) => t.status == 'maintenance').length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatChip('Libres', freeCount, Colors.green.shade600, Icons.check_circle)),
          SizedBox(width: 12),
          Expanded(child: _buildStatChip('Occupées', occupiedCount, Colors.red.shade600, Icons.people)),
          SizedBox(width: 12),
          Expanded(child: _buildStatChip('Réservées', reservedCount, Colors.orange.shade600, Icons.bookmark)),
          SizedBox(width: 12),
          Expanded(child: _buildStatChip('Maintenance', maintenanceCount, Colors.grey.shade600, Icons.build)),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTablesGrid() {
    final filteredTables = _filteredTables;

    if (filteredTables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.table_restaurant_rounded, size: 48, color: Colors.grey.shade400),
            ),
            SizedBox(height: 24),
            Text(
              'Aucune table trouvée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Ajoutez votre première table avec le bouton +',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6, // 6 tables par ligne
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75, // Ratio ajusté pour plus de compacité
        ),
        itemCount: filteredTables.length,
        itemBuilder: (context, index) {
          final table = filteredTables[index];
          return _buildTableCard(table, index);
        },
      ),
    );
  }

  Widget _buildTableCard(RestaurantTable table, int index) {
    final statusData = _getStatusData(table.status);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: statusData['color'].withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: statusData['color'].withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showTableActionsDialog(table),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Numéro de table avec fond coloré
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [statusData['color'], statusData['color'].withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              table.tableNumber,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 8),

                        // Badge de statut plus petit
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusData['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusData['color'].withOpacity(0.3)),
                          ),
                          child: Text(
                            statusData['text'],
                            style: TextStyle(
                              color: statusData['color'],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        SizedBox(height: 8),

                        // Informations compactes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.people_outline, size: 14, color: Colors.grey.shade600),
                                SizedBox(height: 2),
                                Text(
                                  '${table.capacity}',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.grey.shade300,
                            ),
                            Column(
                              children: [
                                Icon(_getLocationIcon(table.location), size: 14, color: Colors.grey.shade600),
                                SizedBox(height: 2),
                                Text(
                                  _getLocationShortName(table.location),
                                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Informations de réservation si applicable
                        if (table.status == 'réservée' && table.reservedFor != null) ...[
                          SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              table.reservedFor!,
                              style: TextStyle(
                                fontSize: 8,
                                fontStyle: FontStyle.italic,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getLocationIcon(String location) {
    switch (location) {
      case 'Intérieur': return Icons.home_outlined;
      case 'Terrasse': return Icons.deck_outlined;
      case 'VIP': return Icons.star_border;
      case 'Bar': return Icons.local_bar_outlined;
      case 'Jardin': return Icons.nature_outlined;
      default: return Icons.location_on_outlined;
    }
  }

  String _getLocationShortName(String location) {
    switch (location) {
      case 'Intérieur': return 'Int.';
      case 'Terrasse': return 'Terr.';
      case 'VIP': return 'VIP';
      case 'Bar': return 'Bar';
      case 'Jardin': return 'Jard.';
      default: return location.substring(0, 3);
    }
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'libre':
        return {'color': Colors.green.shade600, 'text': 'Libre'};
      case 'occupée':
        return {'color': Colors.red.shade600, 'text': 'Occupée'};
      case 'réservée':
        return {'color': Colors.orange.shade600, 'text': 'Réservée'};
      case 'maintenance':
        return {'color': Colors.grey.shade600, 'text': 'Maintenance'};
      default:
        return {'color': Colors.grey.shade600, 'text': 'Inconnu'};
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'libre': return 'Libre';
      case 'occupée': return 'Occupée';
      case 'réservée': return 'Réservée';
      case 'maintenance': return 'Maintenance';
      default: return status;
    }
  }

  void _showTableActionsDialog(RestaurantTable table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.table_restaurant, color: Colors.deepOrange),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Table ${table.tableNumber}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${table.capacity} places • ${table.location}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 24),

            _buildActionTile(Icons.edit_rounded, 'Modifier la table', Colors.blue, () {
              Navigator.pop(context);
              _showTableDialog(table: table);
            }),

            _buildActionTile(Icons.flag_rounded, 'Changer le statut', Colors.orange, () {
              Navigator.pop(context);
              _showStatusChangeDialog(table);
            }),

            if (table.status == 'libre')
              _buildActionTile(Icons.restaurant_rounded, 'Prendre commande', Colors.green, () {
                Navigator.pop(context);
                _navigateToOrderTaking(table);
              }),

            _buildActionTile(Icons.delete_rounded, 'Supprimer la table', Colors.red, () {
              Navigator.pop(context);
              _confirmDeleteTable(table);
            }),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showTableDialog({RestaurantTable? table}) {
    showDialog(
      context: context,
      builder: (context) => TableFormDialog(
        table: table,
        userId: _userId!,
        onSaved: _loadTables,
      ),
    );
  }

  void _showStatusChangeDialog(RestaurantTable table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.flag_rounded, color: Colors.deepOrange),
            SizedBox(width: 12),
            Text('Changer le statut'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Table ${table.tableNumber}'),
            SizedBox(height: 16),
            ..._statuses.skip(1).map((statusItem) {
              final status = statusItem['value'];
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: table.status == status ? Colors.deepOrange.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(statusItem['icon'], color: _getStatusData(status)['color']),
                  title: Text(_getStatusDisplayName(status)),
                  trailing: Radio<String>(
                    value: status,
                    groupValue: table.status,
                    activeColor: Colors.deepOrange,
                    onChanged: (value) async {
                      if (value != null) {
                        try {
                          await RestaurantService.updateTableStatus(table.id, value);
                          Navigator.pop(context);
                          _showSuccessMessage('Statut mis à jour');
                          _loadTables();
                        } catch (e) {
                          _showErrorMessage('Erreur lors de la mise à jour');
                        }
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTable(RestaurantTable table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Confirmer la suppression'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer la table ${table.tableNumber} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('restaurant_tables')
                    .doc(table.id)
                    .delete();
                Navigator.pop(context);
                _showSuccessMessage('Table supprimée');
                _loadTables();
              } catch (e) {
                Navigator.pop(context);
                _showErrorMessage('Erreur lors de la suppression');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _navigateToOrderTaking(RestaurantTable table) {
    // Navigation vers la prise de commande
    print('Navigation vers prise de commande pour table ${table.tableNumber}');
  }
}

// Dialog pour créer/modifier une table (version modernisée)
class TableFormDialog extends StatefulWidget {
  final RestaurantTable? table;
  final String userId;
  final VoidCallback onSaved;

  const TableFormDialog({
    Key? key,
    this.table,
    required this.userId,
    required this.onSaved,
  }) : super(key: key);

  @override
  _TableFormDialogState createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<TableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tableNumberController;
  late TextEditingController _capacityController;
  String _selectedLocation = 'Intérieur';
  String _selectedStatus = 'libre';
  bool _isLoading = false;

  final List<String> _locations = ['Intérieur', 'Terrasse', 'VIP', 'Bar', 'Jardin'];
  final List<String> _statuses = ['libre', 'occupée', 'réservée', 'maintenance'];

  @override
  void initState() {
    super.initState();
    _tableNumberController = TextEditingController(text: widget.table?.tableNumber ?? '');
    _capacityController = TextEditingController(text: widget.table?.capacity.toString() ?? '2');
    if (widget.table != null) {
      _selectedLocation = widget.table!.location;
      _selectedStatus = widget.table!.status;
    }
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final table = RestaurantTable(
        id: widget.table?.id ?? '',
        tableNumber: _tableNumberController.text,
        capacity: int.parse(_capacityController.text),
        location: _selectedLocation,
        status: _selectedStatus,
        userId: widget.userId,
      );

      if (widget.table != null) {
        await RestaurantService.updateTable(widget.table!.id, table);
      } else {
        await RestaurantService.addTable(table);
      }

      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête modernisé
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.deepOrange.shade600, Colors.deepOrange.shade400],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.table != null ? Icons.edit_rounded : Icons.add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.table != null ? 'Modifier la table' : 'Nouvelle table',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.table != null ? 'Mettre à jour les informations' : 'Ajouter une nouvelle table',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            // Formulaire modernisé
            Padding(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildModernTextField(
                      controller: _tableNumberController,
                      label: 'Numéro de table',
                      icon: Icons.table_restaurant_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le numéro de table est requis';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _capacityController,
                      label: 'Capacité (nombre de places)',
                      icon: Icons.people_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La capacité est requise';
                        }
                        final capacity = int.tryParse(value);
                        if (capacity == null || capacity < 1) {
                          return 'Veuillez entrer une capacité valide';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildModernDropdownField(
                      label: 'Emplacement',
                      value: _selectedLocation,
                      icon: Icons.location_on_rounded,
                      items: _locations,
                      onChanged: (value) {
                        setState(() => _selectedLocation = value!);
                      },
                    ),
                    SizedBox(height: 16),
                    _buildModernDropdownField(
                      label: 'Statut initial',
                      value: _selectedStatus,
                      icon: Icons.flag_rounded,
                      items: _statuses,
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                      },
                      displayName: _getStatusDisplayName,
                    ),
                  ],
                ),
              ),
            ),

            // Boutons modernisés
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text('Annuler', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.deepOrange.shade600, Colors.deepOrange.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : Text(
                          widget.table != null ? 'Modifier' : 'Créer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: Colors.deepOrange, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildModernDropdownField({
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    String Function(String)? displayName,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: Colors.deepOrange, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        dropdownColor: Colors.white,
        items: items.map<DropdownMenuItem<String>>((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(displayName != null ? displayName(item) : item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'libre': return 'Libre';
      case 'occupée': return 'Occupée';
      case 'réservée': return 'Réservée';
      case 'maintenance': return 'Maintenance';
      default: return status;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/getConnectedUserAdminId.dart';
import '../../config/restaurant_models.dart';

class TableReservations extends StatefulWidget {
  @override
  _TableReservationsState createState() => _TableReservationsState();
}

class _TableReservationsState extends State<TableReservations> {
  String? _userId;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<TableReservation> _reservations = [];
  List<RestaurantTable> _tables = [];
  String _filterStatus = 'all'; // all, confirmée, en_attente, annulée

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _userId = await getConnectedUserAdminId();
      await Future.wait([
        _loadReservations(),
        _loadTables(),
      ]);
    } catch (e) {
      print('❌ Erreur initialisation réservations: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReservations() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final reservations = await RestaurantService.getReservations(_userId!, _selectedDate);
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement réservations: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTables() async {
    if (_userId == null) return;

    try {
      final tables = await RestaurantService.getTables(_userId!);
      setState(() => _tables = tables);
    } catch (e) {
      print('❌ Erreur chargement tables: $e');
    }
  }

  List<TableReservation> get _filteredReservations {
    if (_filterStatus == 'all') {
      return _reservations;
    }
    return _reservations.where((r) => r.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: Text('Réservations de Tables'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildStatusFilter(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredReservations.isEmpty
                ? _buildEmptyState()
                : _buildReservationsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReservationDialog,
        backgroundColor: Colors.teal,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Nouvelle Réservation', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Colors.teal),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(Duration(days: 1));
              });
              _loadReservations();
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, color: Colors.teal, size: 20),
                    SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Colors.teal),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(Duration(days: 1));
              });
              _loadReservations();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tous', 'all', Colors.grey),
            SizedBox(width: 8),
            _buildFilterChip('Confirmées', 'confirmée', Colors.green),
            SizedBox(width: 8),
            _buildFilterChip('En attente', 'en_attente', Colors.orange),
            SizedBox(width: 8),
            _buildFilterChip('Annulées', 'annulée', Colors.red),
            SizedBox(width: 8),
            _buildFilterChip('Terminées', 'terminée', Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String status, Color color) {
    final isSelected = _filterStatus == status;
    final count = status == 'all'
        ? _reservations.length
        : _reservations.where((r) => r.status == status).length;

    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucune réservation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          SizedBox(height: 8),
          Text(
            'pour ${DateFormat('d MMMM yyyy', 'fr_FR').format(_selectedDate)}',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddReservationDialog,
            icon: Icon(Icons.add),
            label: Text('Créer une réservation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredReservations.length,
      itemBuilder: (context, index) {
        final reservation = _filteredReservations[index];
        return _buildReservationCard(reservation);
      },
    );
  }

  Widget _buildReservationCard(TableReservation reservation) {
    Color statusColor;
    IconData statusIcon;

    switch (reservation.status) {
      case 'confirmée':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'en_attente':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'annulée':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'terminée':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showReservationDetails(reservation),
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
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.table_restaurant, color: Colors.teal, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table ${reservation.tableNumber}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${reservation.numberOfGuests} personne${reservation.numberOfGuests > 1 ? 's' : ''}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        SizedBox(width: 4),
                        Text(
                          reservation.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: Colors.grey.shade600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reservation.customerName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (reservation.customerType == 'hotel_guest')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hotel, size: 14, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Ch. ${reservation.roomNumber}',
                            style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone, size: 18, color: Colors.grey.shade600),
                  SizedBox(width: 8),
                  Text(
                    reservation.customerPhone,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                  SizedBox(width: 8),
                  Text(
                    '${reservation.reservationTime.hour.toString().padLeft(2, '0')}:${reservation.reservationTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ],
              ),
              if (reservation.specialRequests != null && reservation.specialRequests!.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sticky_note_2, size: 16, color: Colors.amber.shade700),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reservation.specialRequests!,
                          style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (reservation.status == 'en_attente' || reservation.status == 'confirmée') ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    if (reservation.status == 'en_attente')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmReservation(reservation),
                          icon: Icon(Icons.check, size: 18),
                          label: Text('Confirmer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (reservation.status == 'en_attente') SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelReservation(reservation),
                        icon: Icon(Icons.close, size: 18),
                        label: Text('Annuler'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.teal),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadReservations();
    }
  }

  Future<void> _showAddReservationDialog() async {
    final formKey = GlobalKey<FormState>();
    String? selectedTableId;
    String customerName = '';
    String customerPhone = '';
    String? customerEmail;
    String customerType = 'external';
    String? roomNumber;
    int numberOfGuests = 2;
    TimeOfDay selectedTime = TimeOfDay.now();
    String? specialRequests;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Nouvelle Réservation'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Table',
                      prefixIcon: Icon(Icons.table_restaurant),
                      border: OutlineInputBorder(),
                    ),
                    value: selectedTableId,
                    items: _tables.map((table) {
                      return DropdownMenuItem(
                        value: table.id,
                        child: Text('Table ${table.tableNumber} (${table.capacity} places) - ${table.location}'),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => selectedTableId = value),
                    validator: (value) => value == null ? 'Sélectionnez une table' : null,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Type de client',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    value: customerType,
                    items: [
                      DropdownMenuItem(value: 'external', child: Text('Client externe')),
                      DropdownMenuItem(value: 'hotel_guest', child: Text('Client hôtel')),
                    ],
                    onChanged: (value) => setDialogState(() => customerType = value!),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Nom du client',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Nom requis' : null,
                    onSaved: (value) => customerName = value!,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty ?? true ? 'Téléphone requis' : null,
                    onSaved: (value) => customerPhone = value!,
                  ),
                  if (customerType == 'hotel_guest') ...[
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Numéro de chambre',
                        prefixIcon: Icon(Icons.hotel),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Numéro de chambre requis' : null,
                      onSaved: (value) => roomNumber = value,
                    ),
                  ],
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email (optionnel)',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (value) => customerEmail = value?.isNotEmpty == true ? value : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Nombre de personnes',
                      prefixIcon: Icon(Icons.groups),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: '2',
                    validator: (value) {
                      final num = int.tryParse(value ?? '');
                      if (num == null || num < 1) return 'Nombre invalide';
                      return null;
                    },
                    onSaved: (value) => numberOfGuests = int.parse(value!),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.access_time),
                    title: Text('Heure'),
                    subtitle: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                    trailing: Icon(Icons.edit),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(primary: Colors.teal),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setDialogState(() => selectedTime = time);
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Demandes spéciales (optionnel)',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onSaved: (value) => specialRequests = value?.isNotEmpty == true ? value : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  try {
                    final selectedTable = _tables.firstWhere((t) => t.id == selectedTableId);

                    final reservation = TableReservation(
                      id: '',
                      tableId: selectedTableId!,
                      tableNumber: selectedTable.tableNumber,
                      customerName: customerName,
                      customerPhone: customerPhone,
                      customerEmail: customerEmail,
                      customerType: customerType,
                      roomNumber: roomNumber,
                      reservationDate: _selectedDate,
                      reservationTime: selectedTime,
                      numberOfGuests: numberOfGuests,
                      status: 'en_attente',
                      specialRequests: specialRequests,
                      createdAt: DateTime.now(),
                      userId: _userId!,
                    );

                    await RestaurantService.addReservation(reservation);
                    await _loadReservations();

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Réservation créée avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReservationDetails(TableReservation reservation) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de la réservation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Table', 'Table ${reservation.tableNumber}', Icons.table_restaurant),
              _buildDetailRow('Client', reservation.customerName, Icons.person),
              _buildDetailRow('Téléphone', reservation.customerPhone, Icons.phone),
              if (reservation.customerEmail != null)
                _buildDetailRow('Email', reservation.customerEmail!, Icons.email),
              if (reservation.roomNumber != null)
                _buildDetailRow('Chambre', reservation.roomNumber!, Icons.hotel),
              _buildDetailRow('Personnes', '${reservation.numberOfGuests}', Icons.groups),
              _buildDetailRow(
                'Heure',
                '${reservation.reservationTime.hour.toString().padLeft(2, '0')}:${reservation.reservationTime.minute.toString().padLeft(2, '0')}',
                Icons.access_time,
              ),
              _buildDetailRow('Statut', reservation.status.toUpperCase(), Icons.info),
              if (reservation.specialRequests != null)
                _buildDetailRow('Demandes', reservation.specialRequests!, Icons.note),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReservation(TableReservation reservation) async {
    try {
      await RestaurantService.updateReservationStatus(reservation.id, 'confirmée');
      await _loadReservations();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Réservation confirmée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelReservation(TableReservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler la réservation'),
        content: Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await RestaurantService.updateReservationStatus(reservation.id, 'annulée');
        await _loadReservations();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Réservation annulée'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
import 'package:flutter/material.dart';
import '../config/HotelSettingsService.dart';
import '../widgets/side_menu.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCurrency = 'FCFA';
  final _checkInTimeController = TextEditingController();
  final _checkOutTimeController = TextEditingController();
  final _roomTypesController = TextEditingController();
  // Nouveaux contrôleurs pour les champs ajoutés
  final _hotelNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  // Contrôleur pour le pourcentage d'acompte
  final _depositPercentageController = TextEditingController();
  final _settingsService = HotelSettingsService();

  List<String> _roomTypes = [];
  bool _isLoading = true;

  // Liste des devises disponibles (pour le moment, uniquement FCFA)
  final List<String> _availableCurrencies = ['FCFA'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _settingsService.getHotelSettings();
      setState(() {
        _selectedCurrency = settings['currency'] ?? 'FCFA';
        _checkInTimeController.text = settings['checkInTime'] ?? '';
        _checkOutTimeController.text = settings['checkOutTime'] ?? '';
        // Chargement des nouveaux champs
        _hotelNameController.text = settings['hotelName'] ?? '';
        _addressController.text = settings['address'] ?? '';
        _phoneNumberController.text = settings['phoneNumber'] ?? '';
        _emailController.text = settings['email'] ?? '';
        // Chargement du pourcentage d'acompte
        _depositPercentageController.text = settings['depositPercentage']?.toString() ?? '30';
        _roomTypes = List<String>.from(settings['roomTypes'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des paramètres: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _settingsService.saveHotelSettings(
          currency: _selectedCurrency,
          checkInTime: _checkInTimeController.text,
          checkOutTime: _checkOutTimeController.text,
          // Nouveaux paramètres
          hotelName: _hotelNameController.text,
          address: _addressController.text,
          phoneNumber: _phoneNumberController.text,
          email: _emailController.text,
          roomTypes: _roomTypes,
          // Ajout du pourcentage d'acompte
          depositPercentage: int.tryParse(_depositPercentageController.text) ?? 30,
        );
        setState(() {
          _isLoading = false;
        });
        _showSuccessSnackBar('Paramètres enregistrés avec succès');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Erreur lors de l\'enregistrement des paramètres: $e');
      }
    }
  }

  void _addRoomType() {
    if (_roomTypesController.text.isNotEmpty) {
      setState(() {
        _roomTypes.add(_roomTypesController.text);
        _roomTypesController.clear();
      });
    }
  }

  void _removeRoomType(int index) {
    setState(() {
      _roomTypes.removeAt(index);
    });
  }

  void _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTimeOfDay(controller.text) ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  TimeOfDay? _parseTimeOfDay(String time) {
    if (time.isEmpty) return null;
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres de l\'hôtel'),
        elevation: 0,
      ),
      drawer: const SideMenu(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).primaryColor.withOpacity(0.05), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Nouvelle carte pour les informations de l'établissement
                Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations de l\'établissement',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _hotelNameController,
                          decoration: InputDecoration(
                            labelText: 'Nom de l\'établissement',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Adresse',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                          maxLines: 2,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneNumberController,
                          decoration: InputDecoration(
                            labelText: 'Numéro de téléphone',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) return 'Champ requis';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations générales',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        // Sélection de devise (dropdown)
                        DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          items: _availableCurrencies.map((currency) {
                            return DropdownMenuItem<String>(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCurrency = value!;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Devise',
                            prefixIcon: Icon(Icons.currency_exchange),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _checkInTimeController,
                          decoration: InputDecoration(
                            labelText: 'Heure d\'arrivée',
                            prefixIcon: Icon(Icons.login),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.access_time),
                              onPressed: () => _selectTime(context, _checkInTimeController),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          readOnly: true,
                          onTap: () => _selectTime(context, _checkInTimeController),
                          validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _checkOutTimeController,
                          decoration: InputDecoration(
                            labelText: 'Heure de départ',
                            prefixIcon: Icon(Icons.logout),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.access_time),
                              onPressed: () => _selectTime(context, _checkOutTimeController),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          readOnly: true,
                          onTap: () => _selectTime(context, _checkOutTimeController),
                          validator: (value) => value!.isEmpty ? 'Champ requis' : null,
                        ),
                        SizedBox(height: 16),
                        // Nouveau champ pour le pourcentage d'acompte
                        TextFormField(
                          controller: _depositPercentageController,
                          decoration: InputDecoration(
                            labelText: 'Pourcentage d\'acompte requis',
                            prefixIcon: Icon(Icons.percent),
                            suffixText: '%',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Champ requis';
                            final percentage = int.tryParse(value);
                            if (percentage == null) return 'Veuillez entrer un nombre';
                            if (percentage < 0 || percentage > 100) return 'Le pourcentage doit être entre 0 et 100';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Types de chambre',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _roomTypesController,
                                decoration: InputDecoration(
                                  labelText: 'Nouveau type de chambre',
                                  prefixIcon: Icon(Icons.hotel),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addRoomType,
                              child: Icon(Icons.add),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        _roomTypes.isEmpty
                            ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'Aucun type de chambre défini',
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          ),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _roomTypes.length,
                          itemBuilder: (context, index) {
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              color: Theme.of(context).primaryColor.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: Icon(Icons.king_bed),
                                title: Text(_roomTypes[index]),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeRoomType(index),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text('ENREGISTRER LES PARAMÈTRES', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _saveSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Libération des ressources des contrôleurs
    _checkInTimeController.dispose();
    _checkOutTimeController.dispose();
    _roomTypesController.dispose();
    _hotelNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _depositPercentageController.dispose(); // Libération du contrôleur d'acompte
    super.dispose();
  }
}
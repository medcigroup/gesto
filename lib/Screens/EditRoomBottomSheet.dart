import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/room_models.dart';

class EditRoomBottomSheet extends StatefulWidget {
  final Room room;
  final Function onRoomEdited;

  const EditRoomBottomSheet({
    Key? key,
    required this.room,
    required this.onRoomEdited,
  }) : super(key: key);

  @override
  _EditRoomBottomSheetState createState() => _EditRoomBottomSheetState();
}

class _EditRoomBottomSheetState extends State<EditRoomBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numberController;
  late TextEditingController _priceController;
  late TextEditingController _capacityController;
  late TextEditingController _floorController;
  late TextEditingController _imageController;

  String _selectedType = 'simple';
  String _selectedStatus = 'disponible';
  List<String> _selectedAmenities = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les valeurs existantes de la chambre
    _numberController = TextEditingController(text: widget.room.number);
    _priceController = TextEditingController(text: widget.room.price.toString());
    _capacityController = TextEditingController(text: widget.room.capacity.toString());
    _floorController = TextEditingController(text: widget.room.floor.toString());
    _imageController = TextEditingController(text: widget.room.image);

    _selectedType = widget.room.type;
    _selectedStatus = widget.room.status;
    _selectedAmenities = List<String>.from(widget.room.amenities);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _floorController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _updateRoom() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Mettre à jour la chambre dans Firestore
        await FirebaseFirestore.instance.collection('rooms').doc(widget.room.id).update({
          'number': _numberController.text,
          'type': _selectedType,
          'status': _selectedStatus,
          'price': double.parse(_priceController.text),
          'capacity': int.parse(_capacityController.text),
          'floor': int.parse(_floorController.text),
          'amenities': _selectedAmenities,
          'image': _imageController.text,
        });

        // Notifier que la mise à jour est terminée
        widget.onRoomEdited();

        // Fermer le bottom sheet
        Navigator.pop(context);

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chambre mise à jour avec succès')),
        );
      } catch (e) {
        print('Erreur lors de la mise à jour de la chambre: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour de la chambre')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modifier la chambre',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Numéro de chambre
              TextFormField(
                controller: _numberController,
                decoration: InputDecoration(
                  labelText: 'Numéro de chambre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un numéro de chambre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Type de chambre
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Type de chambre',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'simple', child: Text('Simple')),
                  DropdownMenuItem(value: 'double', child: Text('Double')),
                  DropdownMenuItem(value: 'suite', child: Text('Suite')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Statut de la chambre
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Statut de la chambre',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
                  DropdownMenuItem(value: 'occupée', child: Text('Occupée')),
                  DropdownMenuItem(value: 'réservée', child: Text('Réservée')),
                  DropdownMenuItem(value: 'maintenance', child: Text('En maintenance')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Prix
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Prix par nuit (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Capacité
              TextFormField(
                controller: _capacityController,
                decoration: InputDecoration(
                  labelText: 'Capacité (personnes)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une capacité';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre entier';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Étage
              TextFormField(
                controller: _floorController,
                decoration: InputDecoration(
                  labelText: 'Étage',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un étage';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre entier';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // URL de l'image
              TextFormField(
                controller: _imageController,
                decoration: InputDecoration(
                  labelText: 'URL de l\'image',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une URL d\'image';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Commodités
              Text(
                'Commodités:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildAmenityChip('WIFI', LucideIcons.wifi),
                  _buildAmenityChip('Petit-dejeuner', Icons.free_breakfast_outlined),
                  _buildAmenityChip('TV', LucideIcons.tv),
                  _buildAmenityChip('Climatisation', LucideIcons.thermometer),
                  _buildAmenityChip('Minibar', Icons.wine_bar),
                  _buildAmenityChip('Coffre-fort', LucideIcons.lock),
                  _buildAmenityChip('Vue sur mer', LucideIcons.mountain),
                  _buildAmenityChip('Piscine', Icons.pool),
                  _buildAmenityChip('Jaccuzy', Icons.bathtub),
                ],
              ),

              SizedBox(height: 30),

              // Bouton de mise à jour
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Mettre à jour la chambre', style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityChip(String amenity, IconData icon) {
    final isSelected = _selectedAmenities.contains(amenity);

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
          SizedBox(width: 8),
          Text(amenity),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedAmenities.add(amenity);
          } else {
            _selectedAmenities.remove(amenity);
          }
        });
      },
      selectedColor: Colors.green,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }
}
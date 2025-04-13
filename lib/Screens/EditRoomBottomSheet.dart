import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

import '../config/HotelSettingsService.dart';
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
  late TextEditingController _priceHourController;
  late TextEditingController _capacityController;
  late TextEditingController _floorController;

  String _selectedType = 'simple';
  String _selectedStatus = 'disponible';
  List<String> _selectedAmenities = [];

  // Définir la liste exacte des commodités disponibles comme dans votre base de données
  final List<Map<String, dynamic>> _availableAmenities = [
    {'name': 'WIFI', 'icon': LucideIcons.wifi},
    {'name': 'TV', 'icon': LucideIcons.tv},
    {'name': 'Climatisation', 'icon': LucideIcons.thermometer},
    {'name': 'Balcon', 'icon': LucideIcons.tent},
    {'name': 'Service en chambre', 'icon': LucideIcons.bellRing},
    {'name': 'Petit-dejeuner', 'icon': Icons.free_breakfast_outlined},
    {'name': 'Parking', 'icon': LucideIcons.car},
    {'name': 'Piscine', 'icon': Icons.pool},
    {'name': 'Jaccuzy', 'icon': Icons.bathtub},
    {'name': 'Minibar', 'icon': Icons.wine_bar},
    {'name': 'Coffre-fort', 'icon': LucideIcons.lock},
    {'name': 'Cuisine', 'icon': Icons.kitchen_outlined},
    {'name': 'Frigo', 'icon': LucideIcons.refrigerator},
    {'name': 'Vue sur mer', 'icon': LucideIcons.mountain},
    {'name': 'Salle de bain privée', 'icon': Icons.shower},
  ];

  // Variables pour l'image
  String _imageUrl = '';
  String _imagePath = '';
  Map<String, dynamic>? _imageMetadata;
  bool _imageChanged = false;
  File? _imageFile;
  Uint8List? _webImage;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;

  // Nouveau paramètre booléen pour le passage
  bool _passage = false;

  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Debug: afficher les commodités de la chambre
    print('Commodités chargées depuis la chambre: ${widget.room.amenities}');

    // Initialiser le passage avec la valeur existante ou false par défaut
    _passage = widget.room.passage;

    // Initialiser les contrôleurs avec les valeurs existantes de la chambre
    _numberController = TextEditingController(text: widget.room.number);
    _priceController = TextEditingController(text: widget.room.price.toString());
    _priceHourController = TextEditingController(text: widget.room.priceHour.toString());
    _capacityController = TextEditingController(text: widget.room.capacity.toString());
    _floorController = TextEditingController(text: widget.room.floor.toString());

    _selectedType = widget.room.type;
    _selectedStatus = widget.room.status;

    // Initialiser la liste des commodités avec celles existantes
    _selectedAmenities = List<String>.from(widget.room.amenities);

    // Initialiser les informations d'image
    _imageUrl = widget.room.imageUrl;
    _imagePath = widget.room.image;
    _imageMetadata = widget.room.imageMetadata;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _priceController.dispose();
    _priceHourController.dispose();
    _capacityController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  // Sélection d'image depuis la galerie
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      if (kIsWeb) {
        // Pour le web, on récupère les bytes de l'image
        _webImage = await pickedFile.readAsBytes();
        setState(() {
          _imageChanged = true;
        });
      } else {
        // Pour mobile, on utilise le fichier
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageChanged = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection d\'image: $e')),
      );
      print('Erreur lors de la sélection d\'image: $e');
    }
  }

  // Téléchargement de l'image vers Firebase Storage
  Future<bool> _uploadImage() async {
    if ((_imageFile == null && _webImage == null) || _isUploadingImage) {
      return true; // Pas d'image à télécharger ou téléchargement en cours
    }

    setState(() {
      _isUploadingImage = true;
      _uploadProgress = 0.0;
    });

    try {
      // Créer une référence unique pour l'image
      final String fileName = 'room_${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}${kIsWeb ? '.jpg' : path.extension(_imageFile!.path)}';
      final String filePath = 'users/${widget.room.userId}/rooms/$fileName';

      // Référence Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(filePath);

      // Télécharger l'image
      UploadTask uploadTask;

      if (kIsWeb) {
        // Pour le web
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'roomId': widget.room.id,
            'uploadedFrom': 'web',
          },
        );
        uploadTask = storageRef.putData(_webImage!, metadata);
      } else {
        // Pour mobile
        final metadata = SettableMetadata(
          contentType: 'image/${path.extension(_imageFile!.path).replaceFirst('.', '')}',
          customMetadata: {
            'roomId': widget.room.id,
            'uploadedFrom': 'mobile',
          },
        );
        uploadTask = storageRef.putFile(_imageFile!, metadata);
      }

      // Écouter la progression
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      // Attendre la fin du téléchargement
      await uploadTask;

      // Récupérer l'URL de téléchargement
      final String downloadUrl = await storageRef.getDownloadURL();

      // Créer les métadonnées d'image
      _imageMetadata = {
        'url': downloadUrl,
        'path': filePath,
        'isDefault': false,
        'fileName': fileName,
        'uploadedAt': DateTime.now().toIso8601String(),
        'size': kIsWeb ? _webImage!.length : await _imageFile!.length(),
      };

      // Mettre à jour les variables
      _imageUrl = downloadUrl;
      _imagePath = filePath;

      setState(() {
        _isUploadingImage = false;
      });

      return true;
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement de l\'image: $e')),
      );
      print('Erreur de téléchargement d\'image: $e');
      return false;
    }
  }

  Future<void> _updateRoom() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Si une nouvelle image a été sélectionnée, la télécharger d'abord
        bool imageUploadSuccess = true;
        if (_imageChanged) {
          imageUploadSuccess = await _uploadImage();
        }

        if (!imageUploadSuccess) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Débogage des commodités avant sauvegarde
        print('Commodités à sauvegarder: $_selectedAmenities');

        // Préparer les données de la chambre mise à jour
        Map<String, dynamic> roomData = {
          'number': _numberController.text,
          'type': _selectedType,
          'status': _selectedStatus,
          'price': double.parse(_priceController.text),
          'pricehour': int.parse(_priceHourController.text),
          'passage': _passage,
          'capacity': int.parse(_capacityController.text),
          'floor': int.parse(_floorController.text),
          'amenities': _selectedAmenities,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Si l'image a été modifiée, inclure les nouvelles données d'image
        if (_imageChanged) {
          roomData['image'] = _imageMetadata;
          roomData['imageUrl'] = _imageUrl;
        }

        // Mettre à jour la chambre dans Firestore
        await FirebaseFirestore.instance.collection('rooms').doc(widget.room.id).update(roomData);

        // Fermer le bottom sheet
        Navigator.pop(context);

        // Notifier que la mise à jour est terminée pour actualiser la liste
        widget.onRoomEdited();

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chambre mise à jour avec succès')),
        );
      } catch (e) {
        print('Erreur lors de la mise à jour de la chambre: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour de la chambre: $e')),
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

              // Section d'image
              Text(
                'Image de la chambre',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              _buildImageSection(),
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
              FutureBuilder<Map<String, dynamic>>(
                future: HotelSettingsService().getHotelSettings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Erreur: ${snapshot.error}');
                  } else {
                    final roomTypes = List<String>.from(snapshot.data?['roomTypes'] ?? []);

                    // Vérifier si _selectedType est initialisé avec une valeur qui existe
                    if (_selectedType != null && !roomTypes.contains(_selectedType)) {
                      _selectedType = (roomTypes.isNotEmpty ? roomTypes.first : null)!; // Réinitialiser _selectedType à la première valeur ou null
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Type de chambre',
                        border: OutlineInputBorder(),
                      ),
                      items: roomTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    );
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

              // Prix par nuit
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Prix par nuit (FCFA)',
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

              // Option de passage
              SwitchListTile(
                title: Text('Disponible en passage'),
                subtitle: Text('La chambre peut être réservée à l\'heure'),
                value: _passage,
                onChanged: (value) {
                  setState(() {
                    _passage = value;
                  });
                },
                activeColor: Colors.green,
              ),
              SizedBox(height: 16),

              // Prix par heure (seulement visible si passage est activé)
              if (_passage)
                TextFormField(
                  controller: _priceHourController,
                  decoration: InputDecoration(
                    labelText: 'Prix par heure (FCFA)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_passage && (value == null || value.isEmpty)) {
                      return 'Veuillez entrer un prix par heure';
                    }
                    if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                      return 'Veuillez entrer un nombre entier';
                    }
                    return null;
                  },
                ),
              if (_passage) SizedBox(height: 16),

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
              SizedBox(height: 20),

              // Commodités
              Text(
                'Commodités:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // Affichage des commodités
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableAmenities.map((amenity) {
                  return _buildAmenityChip(amenity['name'], amenity['icon']);
                }).toList(),
              ),

              SizedBox(height: 30),

              // Bouton de mise à jour
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _isUploadingImage ? null : _updateRoom,
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

  Widget _buildImageSection() {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: _buildImagePreview(),
        ),

        // Barre de progression pour le téléchargement d'image
        if (_isUploadingImage)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: [
                LinearProgressIndicator(value: _uploadProgress),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Téléchargement: ${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                ),
              ],
            ),
          ),

        // Bouton pour sélectionner une image
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: ElevatedButton.icon(
            onPressed: _isUploadingImage || _isLoading ? null : _pickImage,
            icon: Icon(Icons.photo_library),
            label: Text('Choisir une image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    // Si une nouvelle image est sélectionnée
    if (_webImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _webImage!,
          fit: BoxFit.cover,
        ),
      );
    } else if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
        ),
      );
    }

    // Si la chambre a déjà une image
    if (_imageUrl.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorImage();
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Image actuelle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Si aucune image n'est disponible
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 50,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Aucune image sélectionnée',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'Cliquez sur "Choisir une image" pour ajouter une image',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Widget pour afficher une erreur d'image
  Widget _buildErrorImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.red[400],
          ),
          const SizedBox(height: 8),
          const Text(
            'Impossible de charger l\'image',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Widget pour construire une puce de commodité avec vérification exacte
  Widget _buildAmenityChip(String amenity, IconData icon) {
    // Vérification exacte des commodités (correspondance stricte dans la liste)
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
            // Ajouter la commodité avec le nom exact tel qu'affiché
            if (!_selectedAmenities.contains(amenity)) {
              _selectedAmenities.add(amenity);
            }
          } else {
            // Supprimer la commodité avec une correspondance exacte
            _selectedAmenities.remove(amenity);
          }
        });

        // Débogage
        print('Commodité $amenity est maintenant ${selected ? 'sélectionnée' : 'désélectionnée'}');
        print('Liste des commodités: $_selectedAmenities');
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
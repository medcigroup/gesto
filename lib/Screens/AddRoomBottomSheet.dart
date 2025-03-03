import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/room_models.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class AddRoomBottomSheet extends StatefulWidget {
  final Function onRoomAdded;

  const AddRoomBottomSheet({Key? key, required this.onRoomAdded}) : super(key: key);

  @override
  _AddRoomBottomSheetState createState() => _AddRoomBottomSheetState();
}

class _AddRoomBottomSheetState extends State<AddRoomBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  String _type = 'simple';
  String _status = 'disponible';
  List<String> _amenities = [];
  bool _isLoading = false;

  // Variables pour gérer l'image sur différentes plateformes
  File? _imageFile;
  Uint8List? _webImage;
  String? _fileName;
  final ImagePicker _picker = ImagePicker();

  List<String> availableAmenities = [
    'WIFI', 'TV', 'Climatisation', 'Minibar', 'Coffre-fort',
    'Baignoire', 'Vue sur mer', 'Balcon', 'Service en chambre','Petit-dejeuner','Parking','Piscine','Jacuzzi',
  ];

  @override
  void dispose() {
    _numberController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _floorController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_amenities.contains(amenity)) {
        _amenities.remove(amenity);
      } else {
        _amenities.add(amenity);
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _fileName = path.basename(pickedFile.path);
        _imageController.text = _fileName!;

        if (kIsWeb) {
          // Pour le web, nous utilisons Uint8List pour stocker les données de l'image
          pickedFile.readAsBytes().then((value) {
            setState(() {
              _webImage = value;
            });
          });
        } else {
          // Pour les appareils mobiles, nous utilisons File
          _imageFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<String?> _uploadImage(String roomId) async {
    if (kIsWeb && _webImage == null) return null;
    if (!kIsWeb && _imageFile == null) return null;

    try {
      // Créer une référence pour l'image dans Firebase Storage
      final String fileName = '$roomId${_fileName != null ? path.extension(_fileName!) : '.jpg'}';
      final storageRef = FirebaseStorage.instance.ref().child('rooms').child(fileName);

      // Télécharger l'image
      UploadTask uploadTask;

      if (kIsWeb) {
        // Pour le web
        uploadTask = storageRef.putData(_webImage!);
      } else {
        // Pour les appareils mobiles
        uploadTask = storageRef.putFile(_imageFile!);
      }

      final snapshot = await uploadTask.whenComplete(() {});

      // Récupérer l'URL de l'image
      final imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement de l\'image: $e')),
      );
      return null;
    }
  }

  Future<void> _saveRoom() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Générer un nouvel ID pour la chambre
        final roomId = Uuid().v4();

        // Télécharger l'image si elle existe
        String? imageUrl;
        String imageName;

        if ((kIsWeb && _webImage != null) || (!kIsWeb && _imageFile != null)) {
          imageUrl = await _uploadImage(roomId);
          imageName = '$roomId${_fileName != null ? path.extension(_fileName!) : '.jpg'}';
        } else {
          imageName = 'default_room.jpg';
        }

        // Créer un nouvel objet chambre selon votre modèle mis à jour
        final room = Room(
          id: roomId,
          number: _numberController.text,
          type: _type,
          status: _status,
          price: double.parse(_priceController.text),
          capacity: int.parse(_capacityController.text),
          amenities: _amenities,
          floor: int.parse(_floorController.text),
          image: imageName,
          imageUrl: imageUrl ?? '',
          description: '',
        );

        // Enregistrer dans Firestore
        await FirebaseFirestore.instance.collection('rooms').doc(room.id).set({
          'id': room.id,
          'number': room.number,
          'type': room.type,
          'status': room.status,
          'price': room.price,
          'capacity': room.capacity,
          'amenities': room.amenities,
          'floor': room.floor,
          'image': room.image,
          'imageUrl': room.imageUrl,
          'description': room.description,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Informer le parent qu'une chambre a été ajoutée
        widget.onRoomAdded();

        // Fermer le bottom sheet
        Navigator.pop(context);

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chambre ajoutée avec succès')),
        );
      } catch (e) {
        // Afficher une erreur en cas d'échec
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout de la chambre: $e')),
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
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ajouter une nouvelle chambre',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x),
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
                prefixIcon: Icon(LucideIcons.tag),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un numéro de chambre';
                }
                return null;
              },
            ),
            SizedBox(height: 15),

            // Étage
            TextFormField(
              controller: _floorController,
              decoration: InputDecoration(
                labelText: 'Étage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.arrowUp),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer l\'étage';
                }
                if (int.tryParse(value) == null) {
                  return 'Veuillez entrer un nombre entier';
                }
                return null;
              },
            ),
            SizedBox(height: 15),

            // Type de chambre
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(
                labelText: 'Type de chambre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.bed),
              ),
              items: [
                DropdownMenuItem(value: 'simple', child: Text('Simple')),
                DropdownMenuItem(value: 'double', child: Text('Double')),
                DropdownMenuItem(value: 'suite', child: Text('Suite')),
              ],
              onChanged: (value) {
                setState(() {
                  _type = value!;
                });
              },
            ),
            SizedBox(height: 15),

            // Statut
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.info),
              ),
              items: [
                DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
                DropdownMenuItem(value: 'occupée', child: Text('Occupée')),
                DropdownMenuItem(value: 'réservée', child: Text('Réservée')),
                DropdownMenuItem(value: 'maintenance', child: Text('En maintenance')),
              ],
              onChanged: (value) {
                setState(() {
                  _status = value!;
                });
              },
            ),
            SizedBox(height: 15),

            // Prix
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Prix par nuit (FCFA)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.dollarSign),
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
            SizedBox(height: 15),

            // Capacité
            TextFormField(
              controller: _capacityController,
              decoration: InputDecoration(
                labelText: 'Capacité (personnes)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.users),
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
            SizedBox(height: 15),

            // Sélection d'image
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _imageController,
                    decoration: InputDecoration(
                      labelText: 'Image de la chambre',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.image),
                      hintText: 'Sélectionnez une image...',
                      enabled: false,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(LucideIcons.upload),
                  label: Text('Parcourir'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Aperçu de l'image sélectionnée
            if (kIsWeb && _webImage != null)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Image.memory(
                  _webImage!,
                  fit: BoxFit.cover,
                ),
              )
            else if (!kIsWeb && _imageFile != null)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 15),

            // Commodités
            Text(
              'Commodités',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: availableAmenities.map((amenity) {
                final isSelected = _amenities.contains(amenity);
                return FilterChip(
                  label: Text(amenity),
                  selected: isSelected,
                  onSelected: (_) => _toggleAmenity(amenity),
                  backgroundColor: Colors.grey[200],
                  selectedColor: Colors.green[100],
                  checkmarkColor: Colors.green,
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // Bouton de sauvegarde
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _isLoading ? null : _saveRoom,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                'Enregistrer la chambre',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
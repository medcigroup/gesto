import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/HotelSettingsService.dart';
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
  final TextEditingController _priceHourController = TextEditingController(); // Nouveau controller pour le prix horaire

  String _type = 'simple';
  String _status = 'disponible';
  List<String> _amenities = [];
  bool _isLoading = false;
  bool _passage = false; // Nouveau paramètre pour le passage

  // Variables pour gérer l'image sur différentes plateformes
  File? _imageFile;
  Uint8List? _webImage;
  String? _fileName;
  final ImagePicker _picker = ImagePicker();

  List<String> availableAmenities = [
    'WIFI', 'TV', 'Climatisation','Cuisine','Frigo','Minibar','Petit-dejeuner', 'Coffre-fort',
    'Baignoire', 'Vue sur mer', 'Balcon', 'Service en chambre','Parking','Piscine','Jacuzzi',
  ];

  @override
  void dispose() {
    _numberController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _floorController.dispose();
    _imageController.dispose();
    _priceHourController.dispose(); // Libérer le nouveau controller
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

  Future<Map<String, dynamic>?> _uploadImage(String roomId) async {
    // Vérifier si une image a été sélectionnée
    if ((kIsWeb && _webImage == null) || (!kIsWeb && _imageFile == null)) {
      return _getDefaultImageData();
    }

    try {
      // Créer un nom de fichier unique basé sur l'ID de la chambre et un timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileExtension = _fileName != null ? path.extension(_fileName!) : '.jpg';
      final String fileName = 'room_${roomId}_$timestamp$fileExtension';

      // Référence pour l'image dans Firebase Storage
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('rooms')
          .child(fileName);

      // Vérifier la taille du fichier (max 5MB)
      int fileSize = 0;
      if (kIsWeb) {
        fileSize = _webImage!.length;
      } else {
        fileSize = await _imageFile!.length();
      }

      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('La taille de l\'image ne doit pas dépasser 5MB');
      }

      // Télécharger l'image avec les métadonnées
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'roomId': roomId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'fileName': _fileName ?? 'unknown',
        },
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = storageRef.putData(_webImage!, metadata);
      } else {
        uploadTask = storageRef.putFile(_imageFile!, metadata);
      }

      // Écouter la progression du téléchargement
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        // Mise à jour de l'UI
        setState(() {
          _uploadProgress = progress;
        });
      });

      // Attendre que le téléchargement soit terminé
      final snapshot = await uploadTask.whenComplete(() {
        // Réinitialiser la progression
        setState(() {
          _uploadProgress = 0;
        });
      });

      // Récupérer l'URL de l'image
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Retourner les données de l'image
      return {
        'url': imageUrl,
        'path': snapshot.ref.fullPath,
        'fileName': fileName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'isDefault': false,
      };
    } catch (e) {
      // Gestion des erreurs
      String errorMessage = 'Erreur lors du téléchargement de l\'image';

      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permissions insuffisantes pour télécharger l\'image';
      } else if (e.toString().contains('unauthorized')) {
        errorMessage = 'Vous devez être connecté pour télécharger une image';
      } else if (e.toString().contains('QUOTA_EXCEEDED')) {
        errorMessage = 'Quota de stockage dépassé';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );

      print('Error uploading image: $e');

      // En cas d'erreur, retourner les données de l'image par défaut
      return _getDefaultImageData();
    }
  }

// Ajouter cette méthode pour obtenir les données de l'image par défaut
  Future<Map<String, dynamic>> _getDefaultImageData() async {
    try {
      // URL de l'image par défaut
      const String defaultImagePath = 'defaults/default_room.jpg';
      String defaultImageUrl;

      try {
        // Essayer d'obtenir l'URL de l'image par défaut à partir de Firebase Storage
        defaultImageUrl = await FirebaseStorage.instance
            .ref()
            .child(defaultImagePath)
            .getDownloadURL();
      } catch (e) {
        // Si l'image n'existe pas dans Firebase Storage, utiliser une URL par défaut
        defaultImageUrl = 'https://firebasestorage.googleapis.com/v0/b/[YOUR-PROJECT-ID].appspot.com/o/defaults%2Fdefault_room.jpg?alt=media';
      }

      return {
        'url': defaultImageUrl,
        'path': defaultImagePath,
        'fileName': 'default_room.jpg',
        'uploadedAt': FieldValue.serverTimestamp(),
        'isDefault': true,
      };
    } catch (e) {
      print('Error getting default image: $e');
      // URL de secours absolue en cas d'erreur
      return {
        'url': 'https://firebasestorage.googleapis.com/v0/b/[YOUR-PROJECT-ID].appspot.com/o/defaults%2Fdefault_room.jpg?alt=media',
        'path': 'defaults/default_room.jpg',
        'fileName': 'default_room.jpg',
        'uploadedAt': FieldValue.serverTimestamp(),
        'isDefault': true,
      };
    }
  }

  // Ajoutez cette variable d'état à votre classe
  double _uploadProgress = 0;

  Future<void> _saveRoom() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Récupérer l'ID de l'utilisateur actuel
        String? userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Utilisateur non authentifié.')),
          );
          return;
        }

        // Générer un nouvel ID pour la chambre
        final roomId = Uuid().v4();

        // Télécharger l'image ou obtenir l'image par défaut
        final imageData = await _uploadImage(roomId);

        if (imageData == null) {
          throw Exception("Impossible de récupérer les données de l'image");
        }

        final String imageUrl = imageData['url'];
        final String imagePath = imageData['path'];
        final bool isDefaultImage = imageData['isDefault'];

        // Créer un nouvel objet chambre
        final room = Room(
          id: roomId,
          number: _numberController.text,
          type: _type,
          status: _status,
          price: double.parse(_priceController.text),
          capacity: int.parse(_capacityController.text),
          amenities: _amenities,
          floor: int.parse(_floorController.text),
          image: imagePath,
          imageUrl: imageUrl,
          description: '',
          userId: userId,
          passage: _passage,
          priceHour: _passage ? int.parse(_priceHourController.text) : 0,
          isDefaultImage: isDefaultImage,
          imageMetadata: imageData,
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
          'image': imageData, // Stocker l'objet complet
          'imageUrl': room.imageUrl, // Garder pour compatibilité
          'description': room.description,
          'userId': room.userId,
          'createdAt': FieldValue.serverTimestamp(),
          'datedisponible': FieldValue.serverTimestamp(),
          'passage': room.passage,
          'pricehour': room.priceHour,
        });

        // Informer le parent qu'une chambre a été ajoutée
        widget.onRoomAdded();

        // Fermer le bottom sheet
        Navigator.pop(context);

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chambre ajoutée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Afficher une erreur en cas d'échec
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout de la chambre: $e'),
            backgroundColor: Colors.red,
          ),
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

            FutureBuilder<Map<String, dynamic>>(
              future: HotelSettingsService().getHotelSettings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}');
                } else {
                  final roomTypes = List<String>.from(snapshot.data?['roomTypes'] ?? []);

                  // Vérifier si _type est initialisé avec une valeur qui existe
                  if (_type != null && !roomTypes.contains(_type)) {
                    _type = (roomTypes.isNotEmpty ? roomTypes.first : null)!; // Réinitialiser _type à la première valeur ou null
                  }

                  return DropdownButtonFormField<String>(
                    value: _type,
                    decoration: InputDecoration(
                      labelText: 'Type de chambre',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(LucideIcons.bed),
                    ),
                    items: roomTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _type = value!;
                      });
                    },
                  );
                }
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

            // Option passage
            SwitchListTile(
              title: Text('Autoriser le passage'),
              subtitle: Text('Permettre la réservation de la chambre à l\'heure'),
              value: _passage,
              onChanged: (bool value) {
                setState(() {
                  _passage = value;
                });
              },
              activeColor: Colors.green,
            ),
            SizedBox(height: 15),

            // Prix horaire (visible uniquement si passage est activé)
            if (_passage)
              TextFormField(
                controller: _priceHourController,
                decoration: InputDecoration(
                  labelText: 'Prix par heure (FCFA)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.clock),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_passage && (value == null || value.isEmpty)) {
                    return 'Veuillez entrer un prix horaire';
                  }
                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
            if (_passage) SizedBox(height: 15),

            // Sélection d'image
            // Remplacez la section de sélection d'image dans votre méthode build par ce code

// Sélection d'image
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      onPressed: _uploadProgress > 0 ? null : _pickImage,
                      icon: Icon(LucideIcons.upload),
                      label: Text('Parcourir'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      ),
                    ),
                  ],
                ),

                // Indicateur de progression du téléchargement
                if (_uploadProgress > 0)
                  Column(
                    children: [
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Téléchargement: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    child: Stack(
                      children: [
                        Image.memory(
                          _webImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        if (_uploadProgress > 0)
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: _uploadProgress,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                      ],
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
                    child: Stack(
                      children: [
                        Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        if (_uploadProgress > 0)
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: _uploadProgress,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
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
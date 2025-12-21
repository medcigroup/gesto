import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les prix par période
class PackagePricing {
  final double? pricePerHour;
  final double? pricePerDay;
  final double? pricePerWeek;
  final double? pricePerMonth;

  PackagePricing({
    this.pricePerHour,
    this.pricePerDay,
    this.pricePerWeek,
    this.pricePerMonth,
  });

  factory PackagePricing.fromMap(Map<String, dynamic>? data) {
    if (data == null) return PackagePricing();
    return PackagePricing(
      pricePerHour: data['pricePerHour']?.toDouble(),
      pricePerDay: data['pricePerDay']?.toDouble(),
      pricePerWeek: data['pricePerWeek']?.toDouble(),
      pricePerMonth: data['pricePerMonth']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'pricePerWeek': pricePerWeek,
      'pricePerMonth': pricePerMonth,
    };
  }

  bool hasAnyPrice() {
    return pricePerHour != null ||
           pricePerDay != null ||
           pricePerWeek != null ||
           pricePerMonth != null;
  }

  String getPricingInfo() {
    List<String> prices = [];
    if (pricePerHour != null) prices.add('${pricePerHour!.toStringAsFixed(0)} FCFA/h');
    if (pricePerDay != null) prices.add('${pricePerDay!.toStringAsFixed(0)} FCFA/j');
    if (pricePerWeek != null) prices.add('${pricePerWeek!.toStringAsFixed(0)} FCFA/sem');
    if (pricePerMonth != null) prices.add('${pricePerMonth!.toStringAsFixed(0)} FCFA/mois');
    return prices.join(' • ');
  }
}

// Modèle pour les packages
class HotelPackage {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isIncluded;
  final String category; // 'breakfast', 'amenities', 'services'
  final PackagePricing pricing;

  HotelPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isIncluded,
    required this.category,
    PackagePricing? pricing,
  }) : pricing = pricing ?? PackagePricing();

  factory HotelPackage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HotelPackage(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? 'hotel',
      isIncluded: data['isIncluded'] ?? false,
      category: data['category'] ?? 'amenities',
      pricing: PackagePricing.fromMap(data['pricing']),
    );
  }

  // Méthode pour convertir en Map (utile pour sauvegarder)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'isIncluded': isIncluded,
      'category': category,
      'pricing': pricing.toMap(),
    };
  }
}

// Service pour récupérer les packages
class PackageService {
  static Future<List<HotelPackage>> getHotelPackages(String userId) async {
    try {
      print('🔍 Recherche packages pour userId: $userId'); // Debug

      // D'abord, vérifiez s'il y a des packages sans filtre isIncluded
      final allPackagesSnapshot = await FirebaseFirestore.instance
          .collection('hotel_packages')
          .where('userId', isEqualTo: userId)
          .get();

      print('📦 Nombre total de packages trouvés: ${allPackagesSnapshot.docs.length}'); // Debug

      // Si aucun package du tout, retourner une liste vide
      if (allPackagesSnapshot.docs.isEmpty) {
        print('❌ Aucun package trouvé pour cet utilisateur');
        return [];
      }

      // Afficher tous les packages pour debug
      for (var doc in allPackagesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('📋 Package: ${data['name']}, isIncluded: ${data['isIncluded']}, category: ${data['category']}');
      }

      // Ensuite filtrez les packages inclus
      final snapshot = await FirebaseFirestore.instance
          .collection('hotel_packages')
          .where('userId', isEqualTo: userId)
          .where('isIncluded', isEqualTo: true)
          .orderBy('category')
          .orderBy('name')
          .get();

      print('✅ Nombre de packages inclus: ${snapshot.docs.length}'); // Debug

      final packages = snapshot.docs
          .map((doc) => HotelPackage.fromFirestore(doc))
          .toList();

      for (var package in packages) {
        print('🎁 Package inclus: ${package.name} - ${package.category}'); // Debug
      }

      return packages;
    } catch (e) {
      print('❌ Erreur lors du chargement des packages: $e');
      return [];
    }
  }

  // Méthode pour récupérer tous les packages (inclus et non inclus)
  static Future<List<HotelPackage>> getAllHotelPackages(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hotel_packages')
          .where('userId', isEqualTo: userId)
          .orderBy('category')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => HotelPackage.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur lors du chargement de tous les packages: $e');
      return [];
    }
  }

  // Méthode pour ajouter un package
  static Future<void> addPackage(String userId, HotelPackage package) async {
    try {
      await FirebaseFirestore.instance
          .collection('hotel_packages')
          .add({
        ...package.toMap(),
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Package ajouté: ${package.name}');
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du package: $e');
      throw e;
    }
  }

  // Méthode pour mettre à jour un package
  static Future<void> updatePackage(String packageId, HotelPackage package) async {
    try {
      await FirebaseFirestore.instance
          .collection('hotel_packages')
          .doc(packageId)
          .update({
        ...package.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Package mis à jour: ${package.name}');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du package: $e');
      throw e;
    }
  }

  // Méthode pour supprimer un package
  static Future<void> deletePackage(String packageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('hotel_packages')
          .doc(packageId)
          .delete();
      print('✅ Package supprimé');
    } catch (e) {
      print('❌ Erreur lors de la suppression du package: $e');
      throw e;
    }
  }
}

// Widget pour la section options
class OptionsSection extends StatefulWidget {
  final Map<String, bool> selectedOptions;
  final Function(Map<String, bool>) onOptionsChanged;
  final String? userId;
  final bool showTitle;
  final EdgeInsets? padding;

  const OptionsSection({
    Key? key,
    required this.selectedOptions,
    required this.onOptionsChanged,
    required this.userId,
    this.showTitle = true,
    this.padding,
  }) : super(key: key);

  @override
  _OptionsSectionState createState() => _OptionsSectionState();
}

class _OptionsSectionState extends State<OptionsSection> {
  List<HotelPackage> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('🚀 OptionsSection initState - userId: ${widget.userId}');
    _loadPackages();
  }

  @override
  void didUpdateWidget(OptionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharger les packages si l'userId change
    if (oldWidget.userId != widget.userId) {
      print('🔄 UserId changé de ${oldWidget.userId} à ${widget.userId}');
      _loadPackages();
    }
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);

    if (widget.userId != null && widget.userId!.isNotEmpty) {
      print('📥 Chargement des packages pour: ${widget.userId}');
      final packages = await PackageService.getHotelPackages(widget.userId!);
      if (mounted) {
        setState(() {
          _packages = packages;
          _isLoading = false;
        });
        print('✅ Packages chargés: ${_packages.length}');
      }
    } else {
      print('⚠️ UserId null ou vide');
      if (mounted) {
        setState(() {
          _packages = [];
          _isLoading = false;
        });
      }
    }
  }

  void _toggleOption(String packageId, bool value) {
    final updatedOptions = Map<String, bool>.from(widget.selectedOptions);
    updatedOptions[packageId] = value;
    widget.onOptionsChanged(updatedOptions);
    print('🎛️ Option ${value ? 'activée' : 'désactivée'}: $packageId');
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'pool':
        return Icons.pool;
      case 'wifi':
        return Icons.wifi;
      case 'parking':
        return Icons.local_parking;
      case 'gym':
        return Icons.fitness_center;
      case 'spa':
        return Icons.spa;
      case 'coffee':
        return Icons.local_cafe;
      case 'breakfast':
        return Icons.free_breakfast;
      case 'room_service':
        return Icons.room_service;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'concierge':
        return Icons.support_agent;
      case 'airport':
        return Icons.airport_shuttle;
      case 'pet':
        return Icons.pets;
      case 'business':
        return Icons.business_center;
      default:
        return Icons.check_circle;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'breakfast':
        return Colors.orange;
      case 'amenities':
        return Colors.blue;
      case 'services':
        return Colors.green;
      case 'transport':
        return Colors.purple;
      case 'wellness':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'breakfast':
        return 'Restauration';
      case 'amenities':
        return 'Équipements';
      case 'services':
        return 'Services';
      case 'transport':
        return 'Transport';
      case 'wellness':
        return 'Bien-être';
      default:
        return 'Autres';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 OptionsSection build - isLoading: $_isLoading, packages: ${_packages.length}, userId: ${widget.userId}');

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTitle) ...[
              Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Options incluses gratuitement',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(),
              SizedBox(height: 10),
            ],

            if (_isLoading) ...[
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text(
                      'Chargement des options...',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ] else if (_packages.isEmpty) ...[
              // Message si aucun package
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Aucune option gratuite configurée',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vous pouvez configurer des options dans les paramètres de votre hôtel.',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.userId != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'UserId: ${widget.userId}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              // Afficher les packages par catégorie
              ...(() {
                // Grouper les packages par catégorie
                Map<String, List<HotelPackage>> packagesByCategory = {};
                for (var package in _packages) {
                  if (!packagesByCategory.containsKey(package.category)) {
                    packagesByCategory[package.category] = [];
                  }
                  packagesByCategory[package.category]!.add(package);
                }

                return packagesByCategory.entries.map((entry) {
                  final category = entry.key;
                  final packages = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre de la catégorie
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _getCategoryTitle(category),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Liste des packages de cette catégorie
                      ...packages.map((package) {
                        final isSelected = widget.selectedOptions[package.id] ?? false;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? _getCategoryColor(category) : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected ? _getCategoryColor(category).withOpacity(0.05) : null,
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              _toggleOption(package.id, value ?? false);
                            },
                            title: Row(
                              children: [
                                Icon(
                                  _getIconData(package.icon),
                                  color: _getCategoryColor(category),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    package.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'GRATUIT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: package.description.isNotEmpty
                                ? Text(
                              package.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            )
                                : null,
                            activeColor: _getCategoryColor(category),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList();
              })(),

              if (widget.selectedOptions.isNotEmpty) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.selectedOptions.values.where((v) => v).length} option(s) sélectionnée(s)',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
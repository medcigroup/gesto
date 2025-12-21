import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../services/HotelSlugService.dart';
import '../../config/AppConstants.dart';
import '../../config/hotel_amenities.dart';

class ManagePublicPageScreen extends StatefulWidget {
  const ManagePublicPageScreen({Key? key}) : super(key: key);

  @override
  State<ManagePublicPageScreen> createState() => _ManagePublicPageScreenState();
}

class _ManagePublicPageScreenState extends State<ManagePublicPageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _hotelNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Réseaux sociaux
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();
  final _tripadvisorController = TextEditingController();

  // Tarifs et promotions
  final _startingPriceController = TextEditingController();
  final _promoTitleController = TextEditingController();
  final _promoDescriptionController = TextEditingController();
  final _promoCodeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPublic = true;
  String? _currentSlug;
  String? _userId;

  // Services et commodités sélectionnés
  List<String> _selectedAmenities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHotelData();
  }

  Future<void> _loadHotelData() async {
    setState(() => _isLoading = true);
    
    try {
      _userId = FirebaseAuth.instance.currentUser?.uid;
      if (_userId == null) return;

      // Charger les données de l'hôtel si elles existent
      final hotelDoc = await FirebaseFirestore.instance
          .collection('hotels')
          .doc(_userId)
          .get();

      if (hotelDoc.exists) {
        final data = hotelDoc.data()!;
        _hotelNameController.text = data['hotelName'] ?? '';
        _addressController.text = data['address'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _isPublic = data['isPublic'] ?? true;
        _currentSlug = data['slug'];

        // Charger les réseaux sociaux
        _facebookController.text = data['facebook'] ?? '';
        _instagramController.text = data['instagram'] ?? '';
        _websiteController.text = data['website'] ?? '';
        _tripadvisorController.text = data['tripadvisor'] ?? '';

        // Charger les tarifs et promotions
        _startingPriceController.text = data['startingPrice'] ?? '';
        _promoTitleController.text = data['promoTitle'] ?? '';
        _promoDescriptionController.text = data['promoDescription'] ?? '';
        _promoCodeController.text = data['promoCode'] ?? '';

        // Charger les amenities sélectionnés
        if (data['amenities'] != null) {
          _selectedAmenities = List<String>.from(data['amenities']);
        }
      } else {
        // Charger les données automatiquement depuis hotelSettings
        final settingsDoc = await FirebaseFirestore.instance
            .collection('hotelSettings')
            .doc(_userId)
            .get();
        
        if (settingsDoc.exists) {
          final data = settingsDoc.data()!;
          _hotelNameController.text = data['hotelName'] ?? '';
          _addressController.text = data['address'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _emailController.text = data['email'] ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveHotelPage() async {
    // Vérifier manuellement les champs requis au lieu d'utiliser le formulaire
    if (_hotelNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Le nom de l\'établissement est requis'),
          backgroundColor: Colors.orange,
        ),
      );
      // Basculer vers l'onglet Infos
      _tabController.animateTo(0);
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ L\'adresse est requise'),
          backgroundColor: Colors.orange,
        ),
      );
      // Basculer vers l'onglet Infos
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isSaving = true);

    try {
      print('🔵 Début de la sauvegarde...');
      print('🔵 UserId: $_userId');
      print('🔵 Hotel Name: ${_hotelNameController.text.trim()}');

      final success = await HotelSlugService.createOrUpdateHotelDocument(
        userId: _userId!,
        hotelName: _hotelNameController.text.trim(),
        address: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        isPublic: _isPublic,
        amenities: _selectedAmenities,
        facebook: _facebookController.text.trim(),
        instagram: _instagramController.text.trim(),
        website: _websiteController.text.trim(),
        tripadvisor: _tripadvisorController.text.trim(),
        startingPrice: _startingPriceController.text.trim(),
        promoTitle: _promoTitleController.text.trim(),
        promoDescription: _promoDescriptionController.text.trim(),
        promoCode: _promoCodeController.text.trim(),
      );

      print('🔵 Résultat de la sauvegarde: $success');

      if (success) {
        _currentSlug = await HotelSlugService.getHotelSlug(_userId!);
        print('🔵 Slug récupéré: $_currentSlug');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Page publique enregistrée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        }
      } else {
        print('❌ La sauvegarde a échoué (success = false)');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Échec de la sauvegarde. Vérifiez votre connexion.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la sauvegarde: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _copyPublicUrl() {
    if (_currentSlug == null) return;

    final url = HotelSlugService.getPublicUrl(_currentSlug!);
    Clipboard.setData(ClipboardData(text: url));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 URL copiée dans le presse-papiers'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showQrCodeDialog() {
    if (_currentSlug == null) return;

    final url = HotelSlugService.getPublicUrl(_currentSlug!);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(30),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Code QR de votre page',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _hotelNameController.text.isNotEmpty
                    ? _hotelNameController.text
                    : 'Votre Établissement',
                style: TextStyle(
                  fontSize: 18,
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 300,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                url,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyPublicUrl,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copier URL'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: AppConstants.primaryColor),
                        foregroundColor: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _printQrCode(url),
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimer'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: AppConstants.primaryColor,
                      ),
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

  Future<void> _printQrCode(String url) async {
    final hotelName = _hotelNameController.text.isNotEmpty
        ? _hotelNameController.text
        : 'Votre Établissement';

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();

          pdf.addPage(
            pw.Page(
              pageFormat: format,
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        hotelName,
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Scannez pour accéder à notre page',
                        style: const pw.TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(20),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 2),
                          borderRadius: pw.BorderRadius.circular(15),
                        ),
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: url,
                          width: 300,
                          height: 300,
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Text(
                        url,
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );

          return pdf.save();
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préparation de l\'impression...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'impression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppConstants.primaryColor,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text('Ma Page Publique', style: TextStyle(fontSize: 18)),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      // Bouton Aperçu rapide
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined),
                        tooltip: 'Aperçu',
                        onPressed: _showPreviewBottomSheet,
                      ),
                      // Bouton QR Code
                      if (_currentSlug != null)
                        IconButton(
                          icon: const Icon(Icons.qr_code_2),
                          tooltip: 'QR Code',
                          onPressed: _showQrCodeDialog,
                        ),
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      tabs: const [
                        Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Infos'),
                        Tab(icon: Icon(Icons.hotel_outlined, size: 20), text: 'Services'),
                        Tab(icon: Icon(Icons.local_offer_outlined, size: 20), text: 'Tarifs'),
                        Tab(icon: Icon(Icons.share_outlined, size: 20), text: 'Réseaux'),
                      ],
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  // Bandeau URL publique si disponible
                  if (_currentSlug != null) _buildCompactUrlBanner(),
                  
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInfoTab(),
                        _buildServicesTab(),
                        _buildPricingTab(),
                        _buildSocialTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton de visibilité
          FloatingActionButton.small(
            heroTag: 'visibility',
            onPressed: () {
              setState(() => _isPublic = !_isPublic);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isPublic ? '✓ Page visible' : '✗ Page masquée'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            backgroundColor: _isPublic ? Colors.green : Colors.grey,
            child: Icon(_isPublic ? Icons.visibility : Icons.visibility_off),
          ),
          const SizedBox(height: 10),
          // Bouton principal de sauvegarde
          FloatingActionButton.extended(
            heroTag: 'save',
            onPressed: _isSaving ? null : _saveHotelPage,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
            backgroundColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactUrlBanner() {
    final url = HotelSlugService.getPublicUrl(_currentSlug!);
    
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryColor.withOpacity(0.1), AppConstants.secondaryColor.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: AppConstants.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('URL Publique', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text(url, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: _copyPublicUrl,
            color: AppConstants.primaryColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildCompactTextField(
              controller: _hotelNameController,
              label: 'Nom de l\'établissement',
              icon: Icons.hotel,
              required: true,
            ),
            const SizedBox(height: 12),
            _buildCompactTextField(
              controller: _addressController,
              label: 'Adresse',
              icon: Icons.location_on,
              required: true,
            ),
            const SizedBox(height: 12),
            _buildCompactTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _buildCompactTextField(
              controller: _phoneController,
              label: 'Téléphone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildCompactTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    final Map<String, List<HotelAmenityData>> amenitiesByCategory = {};
    for (var amenity in HotelAmenities.all) {
      if (!amenitiesByCategory.containsKey(amenity.category)) {
        amenitiesByCategory[amenity.category] = [];
      }
      amenitiesByCategory[amenity.category]!.add(amenity);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Compteur en haut
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                '${_selectedAmenities.length} service(s) sélectionné(s)',
                style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_selectedAmenities.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selectedAmenities.clear()),
                  child: const Text('Tout effacer', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Afficher par catégorie
        ...amenitiesByCategory.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity.id);
                  return FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(amenity.icon, size: 16),
                        const SizedBox(width: 6),
                        Text(amenity.title, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity.id);
                        } else {
                          _selectedAmenities.remove(amenity.id);
                        }
                      });
                    },
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppConstants.primaryColor,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppConstants.primaryColor : Colors.grey.shade300,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPricingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCompactTextField(
            controller: _startingPriceController,
            label: 'Prix à partir de (€)',
            icon: Icons.euro,
            keyboardType: TextInputType.number,
            hint: 'Ex: 89',
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.campaign, color: AppConstants.primaryColor),
              const SizedBox(width: 10),
              const Text('Offre Spéciale (optionnel)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          _buildCompactTextField(
            controller: _promoTitleController,
            label: 'Titre de l\'offre',
            icon: Icons.campaign,
            hint: 'Ex: Offre Weekend',
          ),
          const SizedBox(height: 12),
          _buildCompactTextField(
            controller: _promoDescriptionController,
            label: 'Description',
            icon: Icons.description,
            maxLines: 2,
            hint: 'Ex: -20% pour 2 nuits minimum',
          ),
          const SizedBox(height: 12),
          _buildCompactTextField(
            controller: _promoCodeController,
            label: 'Code promo',
            icon: Icons.confirmation_number,
            hint: 'Ex: WEEKEND20',
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCompactTextField(
            controller: _facebookController,
            label: 'Facebook',
            icon: Icons.facebook,
            hint: 'https://facebook.com/...',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          _buildCompactTextField(
            controller: _instagramController,
            label: 'Instagram',
            icon: Icons.camera_alt,
            hint: 'https://instagram.com/...',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          _buildCompactTextField(
            controller: _websiteController,
            label: 'Site Web',
            icon: Icons.language,
            hint: 'https://votre-site.com',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          _buildCompactTextField(
            controller: _tripadvisorController,
            label: 'TripAdvisor',
            icon: Icons.star,
            hint: 'https://tripadvisor.com/...',
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required ? (value) => value?.isEmpty ?? true ? 'Champ requis' : null : null,
    );
  }

  void _showPreviewBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: AppConstants.primaryColor),
                    const SizedBox(width: 10),
                    const Text('Aperçu de la page', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPreviewContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hotelNameController.text.isEmpty ? 'Nom de votre hôtel' : _hotelNameController.text,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 16),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _addressController.text.isEmpty ? 'Adresse' : _addressController.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Prix
          if (_startingPriceController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.euro, color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('À partir de', style: TextStyle(fontSize: 12)),
                      Text(
                        '${_startingPriceController.text}€/nuit',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // Promo
          if (_promoTitleController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.red.shade400]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎉 OFFRE SPÉCIALE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_promoTitleController.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (_promoDescriptionController.text.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(_promoDescriptionController.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ],
              ),
            ),
          
          // Description
          if (_descriptionController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('À propos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_descriptionController.text, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          
          // Services
          if (_selectedAmenities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedAmenities.map((id) {
                      final amenity = HotelAmenities.all.firstWhere((a) => a.id == id);
                      return Chip(
                        avatar: Icon(amenity.icon, size: 16),
                        label: Text(amenity.title, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          
          // Contact
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (_phoneController.text.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16),
                      const SizedBox(width: 8),
                      Text(_phoneController.text),
                    ],
                  ),
                if (_emailController.text.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16),
                      const SizedBox(width: 8),
                      Text(_emailController.text),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hotelNameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _websiteController.dispose();
    _tripadvisorController.dispose();
    _startingPriceController.dispose();
    _promoTitleController.dispose();
    _promoDescriptionController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }
}

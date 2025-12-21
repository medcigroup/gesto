import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/AppConstants.dart';
import '../../config/routes.dart';
import '../../config/generationcode.dart';
import '../../config/hotel_amenities.dart';
import '../client/ModernClientBookingPage.dart';
import '../client/MyReservationsPage.dart';


class PublicHotelPage extends StatefulWidget {
  final String hotelSlug;

  const PublicHotelPage({Key? key, required this.hotelSlug}) : super(key: key);

  @override
  State<PublicHotelPage> createState() => _PublicHotelPageState();
}

class _PublicHotelPageState extends State<PublicHotelPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _hotelData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHotelData();
  }

  Future<void> _loadHotelData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔍 Recherche de l\'hôtel avec slug: ${widget.hotelSlug}');

      // Rechercher l'hôtel par slug dans Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('hotels')
          .where('slug', isEqualTo: widget.hotelSlug)
          .where('isPublic', isEqualTo: true)
          .limit(1)
          .get();

      print('📊 Résultats trouvés: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        // Vérifier si l'hôtel existe mais est privé
        final privateCheck = await FirebaseFirestore.instance
            .collection('hotels')
            .where('slug', isEqualTo: widget.hotelSlug)
            .limit(1)
            .get();
        
        if (privateCheck.docs.isNotEmpty) {
          print('⚠️ Hôtel trouvé mais non public');
          setState(() {
            _error = 'Cette page n\'est pas encore publique';
            _isLoading = false;
          });
        } else {
          print('❌ Aucun hôtel trouvé avec ce slug');
          setState(() {
            _error = 'Hôtel non trouvé';
            _isLoading = false;
          });
        }
        return;
      }

      final hotelDoc = querySnapshot.docs.first;
      final hotelId = hotelDoc.id;

      // Récupérer les chambres disponibles
      final roomsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(hotelId)
          .collection('rooms')
          .where('isAvailable', isEqualTo: true)
          .get();

      setState(() {
        _hotelData = {
          ...hotelDoc.data(),
          'id': hotelId,
          'availableRooms': roomsSnapshot.docs.map((doc) => doc.data()).toList(),
        };
        _isLoading = false;
      });

      // Afficher le dialogue de promotion après un court délai si une promo existe
      _showWelcomePromoIfAvailable();
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  // Afficher le dialogue de bienvenue avec promotion
  void _showWelcomePromoIfAvailable() {
    final promoTitle = _hotelData?['promoTitle'] as String?;
    final promoDescription = _hotelData?['promoDescription'] as String?;
    final promoCode = _hotelData?['promoCode'] as String?;

    // Vérifier si une promotion existe
    if (promoTitle != null && promoTitle.isNotEmpty) {
      // Afficher le dialogue après un court délai pour laisser la page se charger
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _showWelcomeDialog(promoTitle, promoDescription, promoCode);
        }
      });
    }
  }

  // Dialogue de bienvenue avec promotion
  void _showWelcomeDialog(String title, String? description, String? code) {
    final scaffoldContext = context;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FadeIn(
          duration: const Duration(milliseconds: 400),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade400,
                  Colors.red.shade500,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade300.withOpacity(0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Confettis décoratifs
                Positioned(
                  top: 20,
                  right: 20,
                  child: Icon(
                    Icons.celebration,
                    color: Colors.white.withOpacity(0.3),
                    size: 60,
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Icon(
                    Icons.star,
                    color: Colors.white.withOpacity(0.2),
                    size: 50,
                  ),
                ),

                // Contenu principal
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton fermer
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),

                    // Icône principale avec animation
                    BounceInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_offer,
                          color: Colors.deepOrange,
                          size: 50,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Contenu scrollable
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            // Badge "Bienvenue"
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'BIENVENUE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Titre
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Description
                            if (description != null && description.isNotEmpty) ...[
                              FadeInUp(
                                delay: const Duration(milliseconds: 300),
                                child: Text(
                                  description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Code promo
                            if (code != null && code.isNotEmpty) ...[
                              FadeInUp(
                                delay: const Duration(milliseconds: 400),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.card_giftcard,
                                        color: Colors.deepOrange,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Votre code promo',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.deepOrange,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          code,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange,
                                            letterSpacing: 3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Boutons d'action
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  scaffoldContext,
                                  MaterialPageRoute(
                                    builder: (context) => ModernClientBookingPage(
                                      preselectedHotelId: _hotelData!['id'],
                                      preselectedHotelName: _hotelData!['name'] ?? _hotelData!['hotelName'] ?? 'Hôtel',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.deepOrange,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_available, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Réserver maintenant',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Je découvre plus tard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildHotelContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isUserConnected = FirebaseAuth.instance.currentUser != null;
    
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.95),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: GestureDetector(
        onTap: () {
          // Si connecté, retour au dashboard, sinon à la page d'accueil
          if (isUserConnected) {
            Navigator.pushNamed(context, AppRoutes.dashboard);
          } else {
            Navigator.pushNamed(context, AppRoutes.home);
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/gesto_logo2.png',
              height: 35,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              AppConstants.appName,
              style: AppConstants.getHeadlineFont(color: AppConstants.darkColor)
                  .copyWith(fontSize: 20),
            ),
          ],
        ),
      ),
      actions: [
        // Bouton Espace Client
        PopupMenuButton<String>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUserConnected ? Icons.account_circle : Icons.person_outline,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                isUserConnected ? 'Mon Compte' : 'Espace Client',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          offset: const Offset(0, 50),
          itemBuilder: (context) => [
            if (!isUserConnected) ...[
              PopupMenuItem(
                value: 'login',
                child: Row(
                  children: const [
                    Icon(Icons.login, size: 20),
                    SizedBox(width: 12),
                    Text('Se Connecter'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'register',
                child: Row(
                  children: const [
                    Icon(Icons.person_add, size: 20),
                    SizedBox(width: 12),
                    Text('Créer un Compte'),
                  ],
                ),
              ),
            ] else ...[
              PopupMenuItem(
                value: 'bookings',
                child: Row(
                  children: const [
                    Icon(Icons.book_online, size: 20),
                    SizedBox(width: 12),
                    Text('Mes Réservations'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: const [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 12),
                    Text('Mon Profil'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Déconnexion', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ],
          onSelected: (value) async {
            switch (value) {
              case 'login':
                _showClientLoginDialog(context);
                break;
              case 'register':
                _showClientRegisterDialog(context);
                break;
              case 'bookings':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyReservationsPage()),
                );
                break;
              case 'profile':
                // Rediriger vers ClientDashboard avec l'onglet Profil
                Navigator.pushNamed(context, '/client-dashboard');
                break;
              case 'logout':
                await FirebaseAuth.instance.signOut();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Déconnexion réussie'), backgroundColor: Colors.green),
                );
                break;
            }
          },
        ),
        
        // Connexion Gérant (séparée)
        if (!isUserConnected)
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            icon: const Icon(Icons.admin_panel_settings, size: 18),
            label: const Text('Gérant'),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.primaryColor,
            ),
          ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Chargement des informations...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            _error ?? 'Une erreur est survenue',
            style: const TextStyle(fontSize: 18, color: Colors.red),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
            icon: const Icon(Icons.home),
            label: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelContent() {
    return CustomScrollView(
      slivers: [
        _buildHeroSection(),
        _buildQuickStats(),
        _buildHotelInfo(),
        _buildAmenities(),
        _buildPricingAndPromo(),
        _buildAvailableRooms(),
        _buildSocialMedia(),
        _buildContactSection(),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeroSection() {
    final coverImage = _hotelData?['coverImage'] as String?;
    final hotelName = _hotelData?['hotelName'] as String? ?? 'Hôtel';

    return SliverToBoxAdapter(
      child: FadeIn(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
            
            return Stack(
              children: [
                Container(
                  height: isMobile ? 400 : (isTablet ? 500 : 600),
                  decoration: BoxDecoration(
                    image: coverImage != null
                        ? DecorationImage(
                            image: NetworkImage(coverImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: coverImage == null
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1A237E),
                              const Color(0xFF0D47A1),
                              const Color(0xFF01579B),
                            ],
                          )
                        : null,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
                      vertical: isMobile ? 40 : (isTablet ? 60 : 80),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Text(
                              '⭐ Hôtel de Luxe',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          duration: const Duration(milliseconds: 800),
                          child: Text(
                            hotelName,
                            style: TextStyle(
                              fontSize: isMobile ? 32 : (isTablet ? 48 : 72),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          duration: const Duration(milliseconds: 800),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  _hotelData?['address'] as String? ?? 'Adresse non disponible',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        FadeInUp(
                          delay: const Duration(milliseconds: 600),
                          duration: const Duration(milliseconds: 800),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Rediriger vers la page de réservation moderne avec l'hôtel pré-sélectionné
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ModernClientBookingPage(
                                        preselectedHotelId: _hotelData!['id'],
                                        preselectedHotelName: _hotelData!['name'] ?? _hotelData!['hotelName'] ?? 'Hôtel',
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 20 : 32,
                                    vertical: isMobile ? 16 : 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                ),
                                icon: const Icon(Icons.hotel, size: 20),
                                label: Text(
                                  'Réserver Maintenant',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.contactpage),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 2),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 20 : 32,
                                    vertical: isMobile ? 16 : 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                icon: const Icon(Icons.phone, size: 20),
                                label: Text(
                                  'Nous Contacter',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final rooms = _hotelData?['availableRooms'] as List<dynamic>? ?? [];
    
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
          
          return Transform.translate(
            offset: Offset(0, isMobile ? -30 : -50),
            child: FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: Center(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: isMobile ? 20 : (isTablet ? 40 : 60)),
                  padding: EdgeInsets.all(isMobile ? 20 : (isTablet ? 30 : 40)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            _buildStatItem(Icons.hotel_outlined, rooms.length.toString(), 'Chambres Disponibles', const Color(0xFF1A237E)),
                            const SizedBox(height: 20),
                            _buildStatItem(Icons.star_rounded, '4.8', 'Note Moyenne', const Color(0xFFFFD700)),
                            const SizedBox(height: 20),
                            _buildStatItem(Icons.verified_outlined, '100%', 'Satisfaction Client', const Color(0xFF4CAF50)),
                            const SizedBox(height: 20),
                            _buildStatItem(Icons.support_agent_outlined, '24/7', 'Service Client', const Color(0xFFFF6B35)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(child: _buildStatItem(Icons.hotel_outlined, rooms.length.toString(), 'Chambres Disponibles', const Color(0xFF1A237E))),
                            if (!isTablet) _buildDivider(),
                            Expanded(child: _buildStatItem(Icons.star_rounded, '4.8', 'Note Moyenne', const Color(0xFFFFD700))),
                            if (!isTablet) _buildDivider(),
                            Expanded(child: _buildStatItem(Icons.verified_outlined, '100%', 'Satisfaction Client', const Color(0xFF4CAF50))),
                            if (!isTablet) _buildDivider(),
                            Expanded(child: _buildStatItem(Icons.support_agent_outlined, '24/7', 'Service Client', const Color(0xFFFF6B35))),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 80,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildHotelInfo() {
    final description = _hotelData?['description'] as String?;

    return SliverToBoxAdapter(
      child: FadeInUp(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
            
            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
                vertical: isMobile ? 20 : 40,
              ),
              child: isMobile || isTablet
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHotelInfoContent(description, isMobile, isTablet),
                        const SizedBox(height: 30),
                        _buildHotelInfoImage(isMobile, isTablet),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildHotelInfoContent(description, isMobile, isTablet),
                        ),
                        const SizedBox(width: 60),
                        Expanded(
                          child: _buildHotelInfoImage(isMobile, isTablet),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHotelInfoContent(String? description, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'À PROPOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Découvrez Notre Établissement',
          style: TextStyle(
            fontSize: isMobile ? 28 : (isTablet ? 36 : 42),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          description ?? 
              'Bienvenue dans notre établissement d\'exception. '
              'Nous vous offrons une expérience unique alliant confort, '
              'élégance et service personnalisé. Notre équipe dévouée '
              'est à votre disposition pour rendre votre séjour inoubliable.',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            height: 1.8,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildFeatureBadge(Icons.wifi, 'WiFi Gratuit'),
            _buildFeatureBadge(Icons.local_parking, 'Parking'),
            _buildFeatureBadge(Icons.restaurant, 'Restaurant'),
          ],
        ),
      ],
    );
  }

  Widget _buildHotelInfoImage(bool isMobile, bool isTablet) {
    return Container(
      height: isMobile ? 250 : (isTablet ? 300 : 400),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A237E),
            Color(0xFF0D47A1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _hotelData?['coverImage'] != null
            ? Image.network(
                _hotelData!['coverImage'],
                fit: BoxFit.cover,
              )
            : const Center(
                child: Icon(
                  Icons.hotel,
                  size: 120,
                  color: Colors.white24,
                ),
              ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A237E)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A237E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities() {
    return SliverToBoxAdapter(
      child: FadeInUp(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
            
            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
                vertical: isMobile ? 20 : 40,
              ),
              padding: EdgeInsets.all(isMobile ? 20 : (isTablet ? 30 : 50)),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  Text(
                    'Nos Services & Équipements',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 24 : (isTablet ? 32 : 38),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  SizedBox(height: isMobile ? 30 : 50),
                  _buildAmenitiesGrid(isMobile, isTablet),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAmenitiesGrid(bool isMobile, bool isTablet) {
    // Récupérer les IDs des amenities sélectionnés depuis les données de l'hôtel
    final amenityIds = _hotelData?['amenities'] as List<dynamic>? ?? [];

    // Si aucun amenity n'est sélectionné, afficher un message
    if (amenityIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            'Aucun service configuré pour le moment',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Convertir les IDs en objets HotelAmenityData
    final selectedAmenities = HotelAmenities.getByIds(
      amenityIds.map((id) => id.toString()).toList(),
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
      crossAxisSpacing: isMobile ? 15 : 30,
      mainAxisSpacing: isMobile ? 15 : 30,
      childAspectRatio: isMobile ? 0.9 : 1.3,
      children: selectedAmenities.map((amenity) {
        return _buildAmenityCard(
          amenity.icon,
          amenity.title,
          amenity.subtitle,
          isMobile,
        );
      }).toList(),
    );
  }

  Widget _buildAmenityCard(IconData icon, String title, String subtitle, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF1A237E)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableRooms() {
    final rooms = _hotelData?['availableRooms'] as List<dynamic>? ?? [];

    if (rooms.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: FadeInUp(
        delay: const Duration(milliseconds: 200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
            
            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
                vertical: isMobile ? 20 : 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'NOS CHAMBRES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chambres & Suites Disponibles',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 24 : (isTablet ? 32 : 42),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  SizedBox(height: isMobile ? 30 : 50),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : (isTablet ? 2 : (rooms.length >= 3 ? 3 : rooms.length)),
                      crossAxisSpacing: isMobile ? 0 : 30,
                      mainAxisSpacing: isMobile ? 20 : 30,
                      childAspectRatio: isMobile ? 1.1 : 0.85,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index] as Map<String, dynamic>;
                      return _buildModernRoomCard(room, index, isMobile);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernRoomCard(Map<String, dynamic> room, int index, bool isMobile) {
    final roomImages = [
      'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600',
      'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
      'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=600',
    ];
    
    return FadeInUp(
      delay: Duration(milliseconds: 100 * index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de la chambre
            Stack(
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(roomImages[index % 3]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Disponible',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Détails de la chambre
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Chambre ${room['roomNumber'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          room['roomType'] ?? 'Chambre Standard',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Équipements
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildRoomFeature(Icons.wifi, '2'),
                            _buildRoomFeature(Icons.tv, '1'),
                            _buildRoomFeature(Icons.ac_unit, '1'),
                          ],
                        ),
                      ],
                    ),
                    // Prix et bouton
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${room['price'] ?? '0'} FCFA',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  ),
                                ),
                                Text(
                                  'par nuit',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Rediriger vers la page de réservation moderne avec l'hôtel pré-sélectionné
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ModernClientBookingPage(
                                      preselectedHotelId: _hotelData!['id'],
                                      preselectedHotelName: _hotelData!['name'] ?? _hotelData!['hotelName'] ?? 'Hôtel',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Réserver',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomFeature(IconData icon, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingAndPromo() {
    final startingPrice = _hotelData?['startingPrice'] as String?;
    final promoTitle = _hotelData?['promoTitle'] as String?;
    final promoDescription = _hotelData?['promoDescription'] as String?;
    final promoCode = _hotelData?['promoCode'] as String?;

    // Ne rien afficher si aucune info de tarif ou promo
    if (startingPrice == null && promoTitle == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: FadeInUp(
        delay: const Duration(milliseconds: 300),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
                vertical: isMobile ? 30 : 40,
              ),
              child: isMobile || isTablet
                  ? Column(
                      children: [
                        if (startingPrice != null) _buildPricingCard(startingPrice, isMobile, isTablet),
                        if (startingPrice != null && promoTitle != null)
                          SizedBox(height: isMobile ? 20 : 30),
                        if (promoTitle != null)
                          _buildPromoCard(promoTitle, promoDescription, promoCode, isMobile, isTablet),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (startingPrice != null)
                          Expanded(
                            child: _buildPricingCard(startingPrice, isMobile, isTablet),
                          ),
                        if (startingPrice != null && promoTitle != null) const SizedBox(width: 30),
                        if (promoTitle != null)
                          Expanded(
                            child: _buildPromoCard(promoTitle, promoDescription, promoCode, isMobile, isTablet),
                          ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPricingCard(String price, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 25 : 35),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade600,
            Colors.green.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade300.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.euro,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  'TARIF AVANTAGEUX',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'À partir de',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$price€',
                style: TextStyle(
                  fontSize: isMobile ? 42 : 52,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '/nuit',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '✓ Meilleur prix garanti',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(String title, String? description, String? code, bool isMobile, bool isTablet) {
    return _PromoCardWithHover(
      title: title,
      description: description,
      code: code,
      isMobile: isMobile,
      isTablet: isTablet,
      onTap: () => _showPromoDialog(title, description, code),
    );
  }

  Widget _buildSocialMedia() {
    final facebook = _hotelData?['facebook'] as String?;
    final instagram = _hotelData?['instagram'] as String?;
    final website = _hotelData?['website'] as String?;
    final tripadvisor = _hotelData?['tripadvisor'] as String?;

    // Ne rien afficher si aucun réseau social
    final hasFacebook = facebook != null && facebook.isNotEmpty;
    final hasInstagram = instagram != null && instagram.isNotEmpty;
    final hasWebsite = website != null && website.isNotEmpty;
    final hasTripadvisor = tripadvisor != null && tripadvisor.isNotEmpty;

    if (!hasFacebook && !hasInstagram && !hasWebsite && !hasTripadvisor) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: FadeInUp(
        delay: const Duration(milliseconds: 350),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
                vertical: isMobile ? 30 : 40,
              ),
              padding: EdgeInsets.all(isMobile ? 30 : 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A237E).withOpacity(0.05),
                    const Color(0xFF0D47A1).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1A237E).withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'SUIVEZ-NOUS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Restez Connectés',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Découvrez nos actualités et offres exclusives',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      if (hasFacebook)
                        _buildSocialButton(
                          icon: Icons.facebook,
                          label: 'Facebook',
                          color: const Color(0xFF1877F2),
                          url: facebook,
                          isMobile: isMobile,
                        ),
                      if (hasInstagram)
                        _buildSocialButton(
                          icon: Icons.camera_alt,
                          label: 'Instagram',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                          ),
                          url: instagram,
                          isMobile: isMobile,
                        ),
                      if (hasWebsite)
                        _buildSocialButton(
                          icon: Icons.language,
                          label: 'Site Web',
                          color: const Color(0xFF0D47A1),
                          url: website,
                          isMobile: isMobile,
                        ),
                      if (hasTripadvisor)
                        _buildSocialButton(
                          icon: Icons.star,
                          label: 'TripAdvisor',
                          color: const Color(0xFF00AA6C),
                          url: tripadvisor,
                          isMobile: isMobile,
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    Color? color,
    Gradient? gradient,
    required String url,
    required bool isMobile,
  }) {
    return InkWell(
      onTap: () async {
        // Ouvrir le lien dans le navigateur
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Impossible d\'ouvrir le lien: $url'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de l\'ouverture du lien: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 30,
          vertical: isMobile ? 15 : 20,
        ),
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: (color ?? Colors.purple).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isMobile ? 22 : 26,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 15 : 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: isMobile ? 18 : 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    final phone = _hotelData?['phone'] as String?;
    final email = _hotelData?['email'] as String?;

    return SliverToBoxAdapter(
      child: FadeInUp(
        delay: const Duration(milliseconds: 400),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
            
            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
                vertical: isMobile ? 30 : 60,
              ),
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 30 : (isTablet ? 50 : 80)),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A237E),
                          Color(0xFF0D47A1),
                          Color(0xFF01579B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isMobile ? 20 : 40),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withOpacity(0.4),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: isMobile || isTablet
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildContactContent(phone, email, isMobile, isTablet),
                              SizedBox(height: isMobile ? 30 : 40),
                              _buildContactButtons(isMobile),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildContactContent(phone, email, isMobile, isTablet),
                              ),
                              const SizedBox(width: 60),
                              _buildContactButtons(isMobile),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContactContent(String? phone, String? email, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Text(
            'CONTACTEZ-NOUS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Prêt à Réserver\nVotre Séjour ?',
          style: TextStyle(
            fontSize: isMobile ? 28 : (isTablet ? 36 : 48),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Notre équipe est à votre disposition pour vous accompagner\net rendre votre expérience inoubliable.',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: Colors.white.withOpacity(0.9),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 30,
          runSpacing: 20,
          children: [
            if (phone != null) _buildContactInfo(Icons.phone_rounded, phone),
            if (email != null) _buildContactInfo(Icons.email_rounded, email),
          ],
        ),
      ],
    );
  }

  Widget _buildContactButtons(bool isMobile) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModernClientBookingPage(
                  preselectedHotelId: _hotelData!['id'],
                  preselectedHotelName: _hotelData!['name'] ?? _hotelData!['hotelName'] ?? 'Hôtel',
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 32,
              vertical: isMobile ? 16 : 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.phone, size: 20),
          label: Text(
            'Réserver Maintenant',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 2),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 32,
              vertical: isMobile ? 16 : 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(Icons.chat_bubble_outline, size: 20),
          label: Text(
            'Nous Écrire',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final hotelName = _hotelData?['hotelName'] as String? ?? 'Hôtel';
    
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
          
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : (isTablet ? 40 : 60),
              vertical: isMobile ? 30 : 60,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1128),
              border: Border(
                top: BorderSide(color: Colors.grey.shade800, width: 1),
              ),
            ),
            child: Column(
              children: [
                isMobile
                    ? _buildFooterMobile(hotelName)
                    : isTablet
                        ? _buildFooterTablet(hotelName)
                        : _buildFooterDesktop(hotelName),
                SizedBox(height: isMobile ? 30 : 50),
                Divider(color: Colors.grey.shade800),
                SizedBox(height: isMobile ? 20 : 30),
                isMobile
                    ? _buildFooterBottomMobile(hotelName)
                    : _buildFooterBottomDesktop(hotelName),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooterMobile(String hotelName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo et description
        Row(
          children: [
            Image.asset(
              'assets/images/gesto_logo2.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hotelName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Votre destination de choix pour un séjour exceptionnel.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        // Réseaux sociaux
        Row(
          children: [
            _buildSocialIcon(Icons.facebook),
            const SizedBox(width: 10),
            _buildSocialIcon(Icons.camera_alt),
            const SizedBox(width: 10),
            _buildSocialIcon(Icons.email),
          ],
        ),
        const SizedBox(height: 30),
        // Navigation
        _buildFooterColumn('Navigation', ['Accueil', 'Chambres', 'Services', 'À Propos', 'Contact']),
        const SizedBox(height: 24),
        // Services
        _buildFooterColumn('Services', ['WiFi Gratuit', 'Parking', 'Restaurant', 'Spa', 'Piscine']),
        const SizedBox(height: 24),
        // Contact
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildFooterContactItem(
              Icons.location_on,
              _hotelData?['address'] as String? ?? 'Adresse',
            ),
            const SizedBox(height: 12),
            if (_hotelData?['phone'] != null)
              _buildFooterContactItem(
                Icons.phone,
                _hotelData!['phone'],
              ),
            const SizedBox(height: 12),
            if (_hotelData?['email'] != null)
              _buildFooterContactItem(
                Icons.email,
                _hotelData!['email'],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterTablet(String hotelName) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/gesto_logo2.png',
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hotelName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Votre destination de choix pour un séjour exceptionnel.\nConfort, élégance et service personnalisé.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildSocialIcon(Icons.facebook),
                      const SizedBox(width: 12),
                      _buildSocialIcon(Icons.camera_alt),
                      const SizedBox(width: 12),
                      _buildSocialIcon(Icons.email),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFooterColumn('Navigation', ['Accueil', 'Chambres', 'Services', 'À Propos', 'Contact']),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: _buildFooterColumn('Services', ['WiFi Gratuit', 'Parking', 'Restaurant', 'Spa', 'Piscine']),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFooterContactItem(
                    Icons.location_on,
                    _hotelData?['address'] as String? ?? 'Adresse',
                  ),
                  const SizedBox(height: 12),
                  if (_hotelData?['phone'] != null)
                    _buildFooterContactItem(
                      Icons.phone,
                      _hotelData!['phone'],
                    ),
                  const SizedBox(height: 12),
                  if (_hotelData?['email'] != null)
                    _buildFooterContactItem(
                      Icons.email,
                      _hotelData!['email'],
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterDesktop(String hotelName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/gesto_logo2.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    hotelName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Votre destination de choix pour un séjour exceptionnel.\nConfort, élégance et service personnalisé.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildSocialIcon(Icons.facebook),
                  const SizedBox(width: 12),
                  _buildSocialIcon(Icons.camera_alt),
                  const SizedBox(width: 12),
                  _buildSocialIcon(Icons.email),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 60),
        Expanded(
          child: _buildFooterColumn('Navigation', ['Accueil', 'Chambres', 'Services', 'À Propos', 'Contact']),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: _buildFooterColumn('Services', ['WiFi Gratuit', 'Parking', 'Restaurant', 'Spa', 'Piscine']),
        ),
        const SizedBox(width: 40),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildFooterContactItem(
                Icons.location_on,
                _hotelData?['address'] as String? ?? 'Adresse',
              ),
              const SizedBox(height: 12),
              if (_hotelData?['phone'] != null)
                _buildFooterContactItem(
                  Icons.phone,
                  _hotelData!['phone'],
                ),
              const SizedBox(height: 12),
              if (_hotelData?['email'] != null)
                _buildFooterContactItem(
                  Icons.email,
                  _hotelData!['email'],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterBottomMobile(String hotelName) {
    return Column(
      children: [
        Text(
          '© ${DateTime.now().year} $hotelName.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tous droits réservés.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Propulsé par ',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFD700),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            'Créer ma page →',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterBottomDesktop(String hotelName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '© ${DateTime.now().year} $hotelName. Tous droits réservés.',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
        Row(
          children: [
            Text(
              'Propulsé par ',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFD700),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Créer ma page →',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _buildFooterColumn(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildFooterContactItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }

  // Dialogue de connexion client
  void _showClientLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Connexion Client',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // TODO: Implémenter la connexion client
                    try {
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Connexion réussie !'), backgroundColor: Colors.green),
                        );
                        // Rafraîchir la page pour afficher le statut connecté
                        setState(() {});
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Se Connecter', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showClientRegisterDialog(context);
                  },
                  child: const Text('Pas encore de compte ? Créer un compte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialogue d'inscription client
  void _showClientRegisterDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Créer un Compte Client',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // TODO: Implémenter l'inscription client
                      try {
                        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );
                        
                        // Enregistrer les informations client dans Firestore
                        await FirebaseFirestore.instance
                            .collection('clients')
                            .doc(userCredential.user!.uid)
                            .set({
                          'fullName': nameController.text.trim(),
                          'email': emailController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                          'hotelSlug': widget.hotelSlug,
                        });
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Compte créé avec succès !'), backgroundColor: Colors.green),
                          );
                          // Rafraîchir la page pour afficher le statut connecté
                          setState(() {});
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Créer mon Compte', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showClientLoginDialog(context);
                    },
                    child: const Text('Déjà un compte ? Se connecter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dialogue détaillé de la promotion
  void _showPromoDialog(String title, String? description, String? code) {
    final scaffoldContext = context;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade400,
                Colors.red.shade400,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête avec bouton fermer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_offer,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge "Offre Spéciale"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'OFFRE SPÉCIALE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Titre
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      if (description != null && description.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Code promo
                      if (code != null && code.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.card_giftcard,
                                    color: Colors.deepOrange,
                                    size: 24,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Votre code promo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.deepOrange,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Utilisez ce code lors de votre réservation',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),

              // Bouton d'action
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        scaffoldContext,
                        MaterialPageRoute(
                          builder: (context) => ModernClientBookingPage(
                            preselectedHotelId: _hotelData!['id'],
                            preselectedHotelName: _hotelData!['name'] ?? _hotelData!['hotelName'] ?? 'Hôtel',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Réserver maintenant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Formulaire de réservation avec recherche paramétrée
  Widget _buildBookingForm() {
    return StatefulBuilder(
      builder: (context, setState) {
        DateTime? checkInDate;
        DateTime? checkOutDate;
        int numberOfGuests = 1;
        String? selectedRoomType;
        List<Map<String, dynamic>> filteredRooms = [];
        bool isSearching = false;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rechercher une chambre disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 20),
            
            // Dates
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF1A237E),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() => checkInDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF1A237E)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Arrivée',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                checkInDate != null
                                    ? '${checkInDate!.day}/${checkInDate!.month}/${checkInDate!.year}'
                                    : 'Sélectionner',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: checkInDate?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 1)),
                        firstDate: checkInDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF1A237E),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() => checkOutDate = date);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF1A237E)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Départ',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                checkOutDate != null
                                    ? '${checkOutDate!.day}/${checkOutDate!.month}/${checkOutDate!.year}'
                                    : 'Sélectionner',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Nombre de personnes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, color: Color(0xFF1A237E)),
                      const SizedBox(width: 12),
                      const Text('Nombre de personnes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: numberOfGuests > 1 ? () => setState(() => numberOfGuests--) : null,
                      ),
                      Text('$numberOfGuests', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => numberOfGuests++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Bouton de recherche
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (checkInDate != null && checkOutDate != null)
                    ? () async {
                        setState(() => isSearching = true);
                        
                        // Rechercher les chambres disponibles
                        final rooms = _hotelData?['availableRooms'] as List<dynamic>? ?? [];
                        filteredRooms = rooms
                            .where((room) =>
                                (room['capacity'] as int? ?? 1) >= numberOfGuests &&
                                (room['isAvailable'] as bool? ?? false))
                            .map((room) => Map<String, dynamic>.from(room))
                            .toList();
                        
                        setState(() => isSearching = false);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  isSearching ? 'Recherche en cours...' : 'Rechercher des chambres',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            if (filteredRooms.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                '${filteredRooms.length} chambre(s) disponible(s)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 16),
              
              // Liste des chambres disponibles
              ...filteredRooms.map((room) => _buildRoomCard(room, checkInDate!, checkOutDate!)),
            ] else if (!isSearching && checkInDate != null && checkOutDate != null) ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune chambre disponible pour ces critères',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // Carte de chambre dans les résultats
  Widget _buildRoomCard(Map<String, dynamic> room, DateTime checkIn, DateTime checkOut) {
    final nights = checkOut.difference(checkIn).inDays;
    final pricePerNight = (room['price'] as num?)?.toDouble() ?? 0.0;
    final totalPrice = pricePerNight * nights;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image de la chambre
                Container(
                  width: 120,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                    ),
                  ),
                  child: const Icon(Icons.hotel, size: 48, color: Colors.white),
                ),
                const SizedBox(width: 16),
                
                // Détails de la chambre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room['name'] ?? 'Chambre ${room['roomNumber'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${room['capacity'] ?? 1} personne(s)',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.bed, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            room['type'] ?? 'Standard',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildAmenityChip(Icons.wifi, 'WiFi'),
                          _buildAmenityChip(Icons.ac_unit, 'Climatisation'),
                          _buildAmenityChip(Icons.tv, 'TV'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Prix
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${pricePerNight.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '${totalPrice.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    Text(
                      'pour $nights nuit(s)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmBooking(room, checkIn, checkOut, totalPrice),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text('Réserver cette chambre', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF1A237E)),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // Confirmer la réservation
  void _confirmBooking(Map<String, dynamic> room, DateTime checkIn, DateTime checkOut, double totalPrice) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Récupérer les données client
      final clientDoc = await FirebaseFirestore.instance
          .collection('clients')
          .doc(user.uid)
          .get();
      
      final clientData = clientDoc.data() ?? {};
      
      // Récupérer le userId du propriétaire de l'hôtel
      final hotelDoc = await FirebaseFirestore.instance
          .collection('hotels')
          .where('slug', isEqualTo: widget.hotelSlug)
          .limit(1)
          .get();
      
      if (hotelDoc.docs.isEmpty) {
        throw Exception('Hôtel non trouvé');
      }
      
      final hotelUserId = hotelDoc.docs.first.data()['userId'];
      final numberOfNights = checkOut.difference(checkIn).inDays;
      
      // Générer un code de réservation
      final reservationCode = await CodeGenerator.generateReservationCode();
      
      // Créer la réservation dans Firestore (collection 'reservations')
      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': hotelUserId,
        'clientId': user.uid,
        'hotelSlug': widget.hotelSlug,
        'roomId': room['id'] ?? room['roomNumber'],
        'roomNumber': room['roomNumber'] ?? 'N/A',
        'roomType': room['roomType'] ?? 'Standard',
        'customerName': clientData['fullName'] ?? '',
        'customerEmail': clientData['email'] ?? user.email ?? '',
        'customerPhone': clientData['phone'] ?? '',
        'numberOfGuests': 1,
        'specialRequests': '',
        'checkInDate': Timestamp.fromDate(checkIn),
        'checkOutDate': Timestamp.fromDate(checkOut),
        'reservationCode': reservationCode,
        'numberOfNights': numberOfNights,
        'pricePerNight': room['price'] ?? 0,
        'totalPrice': totalPrice,
        'status': 'en attente',
        'createdAt': FieldValue.serverTimestamp(),
        'paymentMethod': 'En attente',
        'depositPercentage': 0,
        'depositAmount': 0,
        'balanceDue': totalPrice,
        'depositPaid': false,
      });
      
      if (mounted) {
        Navigator.pop(context); // Fermer le dialogue de réservation
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Réservation Confirmée !',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre réservation a été enregistrée avec succès.\nCode: $reservationCode\nMontant total: ${totalPrice.toStringAsFixed(0)} FCFA',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la réservation: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// Widget de carte de promotion avec effet hover
class _PromoCardWithHover extends StatefulWidget {
  final String title;
  final String? description;
  final String? code;
  final bool isMobile;
  final bool isTablet;
  final VoidCallback onTap;

  const _PromoCardWithHover({
    required this.title,
    required this.description,
    required this.code,
    required this.isMobile,
    required this.isTablet,
    required this.onTap,
  });

  @override
  State<_PromoCardWithHover> createState() => _PromoCardWithHoverState();
}

class _PromoCardWithHoverState extends State<_PromoCardWithHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.01 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(widget.isMobile ? 25 : 35),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade500,
                  Colors.red.shade500,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade300.withOpacity(_isHovered ? 0.7 : 0.5),
                  blurRadius: _isHovered ? 25 : 20,
                  offset: Offset(0, _isHovered ? 12 : 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_offer,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        'OFFRE SPÉCIALE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.touch_app, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Cliquez',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: widget.isMobile ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                if (widget.description != null && widget.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.description!.length > 100
                        ? '${widget.description!.substring(0, 100)}...'
                        : widget.description!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
                if (widget.code != null && widget.code!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.confirmation_number,
                          color: Colors.deepOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Code: ${widget.code}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.description != null && widget.description!.length > 100) ...[
                  const SizedBox(height: 15),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Cliquez pour voir plus de détails',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

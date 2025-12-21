import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'config/AppConstants.dart';
import 'config/routes.dart';
import 'gesto_mobile_download_page.dart';

class GestoLandingPage extends StatefulWidget {
  const GestoLandingPage({Key? key}) : super(key: key);

  @override
  _GestoLandingPageState createState() => _GestoLandingPageState();
}

class _GestoLandingPageState extends State<GestoLandingPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _showBackToTopButton = _scrollController.offset >= 300;
        _isScrolled = _scrollController.offset > 50;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(context),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: BouncingScrollPhysics(),
            slivers: [
              _buildHeroSection(context),
              _buildTrustedBySection(),
              _buildFeaturesShowcase(),
              _buildInteractiveDemo(),
              _buildBenefitsWithVisuals(),
              _buildHowItWorks(),
              _buildTestimonialsModern(),
              _buildPricingModern(context),
              _buildFaqAccordion(),
              _buildCtaSection(context),
              _buildFooterModern(context),
            ],
          ),
          if (_showBackToTopButton) _buildFloatingBackButton(),
        ],
      ),
    );
  }

  // ==================== APP BAR MODERNE AVEC GLASSMORPHISM ====================
  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _isScrolled
          ? Colors.white.withOpacity(0.95)
          : Colors.transparent,
      elevation: _isScrolled ? 8 : 0,
      shadowColor: Colors.black.withOpacity(0.1),
      title: GestureDetector(
        onTap: () {
          // Si on n'est pas déjà sur l'accueil, y retourner
          if (ModalRoute.of(context)?.settings.name != AppRoutes.home) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            );
          }
        },
        child: Row(
          children: [
            Image.asset(
              'assets/images/gesto_logo2.png',
              height: 40,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 12),
            Text(
              AppConstants.appName,
              style: AppConstants.getHeadlineFont(
                  color: _isScrolled ? AppConstants.darkColor : Colors.white
              ).copyWith(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      actions: [
        ...AppConstants.navItems.map((item) => TextButton(
          onPressed: () => Navigator.pushNamed(context, item['route']!),
          child: Text(
            item['label']!,
            style: TextStyle(
              color: _isScrolled ? AppConstants.darkColor : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        )),
        SizedBox(width: 10),
        // Bouton Télécharger l'App
        TextButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.mobileDownload);
          },
          icon: Icon(
            Icons.phone_android,
            color: _isScrolled ? AppConstants.primaryColor : Colors.white,
            size: 18,
          ),
          label: Text(
            'App Mobile',
            style: TextStyle(
              color: _isScrolled ? AppConstants.primaryColor : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            child: Row(
              children: [
                Icon(Icons.login, size: 18),
                SizedBox(width: 8),
                Text('Connexion', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        SizedBox(width: 20),
      ],
    );
  }

  // ==================== HERO SECTION MODERNE ====================
  SliverToBoxAdapter _buildHeroSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor,
              AppConstants.primaryColor.withOpacity(0.8),
              AppConstants.secondaryColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Pattern animé en arrière-plan
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: ModernPatternPainter(),
                ),
              ),
            ),
            // Contenu principal
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 80),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < AppConstants.tabletBreakpoint) {
                      return _buildMobileHeroContent(context);
                    }
                    return _buildDesktopHeroContent(context);
                  },
                ),
              ),
            ),
            // Indicateur de scroll
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: FadeInDown(
                delay: Duration(milliseconds: 1200),
                child: Column(
                  children: [
                    Text(
                      'Découvrez plus',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeroContent(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInLeft(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '🎉 Solution N°1 pour les hôteliers',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              FadeInLeft(
                delay: Duration(milliseconds: 200),
                child: Text(
                  'Transformez votre\nhôtel avec Gesto',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -2,
                  ),
                ),
              ),
              SizedBox(height: 25),
              FadeInLeft(
                delay: Duration(milliseconds: 400),
                child: Text(
                  'La plateforme tout-en-un pour gérer vos réservations,\nvotre restaurant et maximiser votre rentabilité.',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.95),
                    height: 1.6,
                  ),
                ),
              ),
              SizedBox(height: 50),
              FadeInLeft(
                delay: Duration(milliseconds: 600),
                child: Row(
                  children: [
                    _buildModernButton(
                      context: context,
                      label: 'Essai gratuit 30 jours',
                      icon: Icons.rocket_launch,
                      isPrimary: true,
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 60),
              FadeInLeft(
                delay: Duration(milliseconds: 800),
                child: Row(
                  children: [
                    _buildTrustBadge(Icons.verified_user, 'SSL Sécurisé'),
                    SizedBox(width: 30),
                    _buildTrustBadge(Icons.credit_card_off, 'Sans CB'),
                    SizedBox(width: 30),
                    _buildTrustBadge(Icons.support_agent, 'Support 24/7'),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 60),
        Expanded(
          flex: 5,
          child: FadeInRight(
            delay: Duration(milliseconds: 400),
            child: _buildHeroImage(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeroContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeInDown(
          child: Text(
            'Transformez votre hôtel avec Gesto',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 20),
        FadeInDown(
          delay: Duration(milliseconds: 200),
          child: Text(
            'La plateforme tout-en-un pour gérer vos réservations, votre restaurant et maximiser votre rentabilité.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.95),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 40),
        FadeInUp(
          delay: Duration(milliseconds: 400),
          child: Column(
            children: [
              _buildModernButton(
                context: context,
                label: 'Essai gratuit 30 jours',
                icon: Icons.rocket_launch,
                isPrimary: true,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
              ),
              SizedBox(height: 15),
              _buildModernButton(
                context: context,
                label: 'Voir la démo',
                icon: Icons.play_circle_outline,
                isPrimary: false,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ] : [],
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 22),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : Colors.transparent,
          foregroundColor: isPrimary ? AppConstants.primaryColor : Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: isPrimary ? BorderSide.none : BorderSide(color: Colors.white, width: 2),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Image.asset(
              AppConstants.dashboardPreviewPath,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SECTION "TRUSTED BY" ====================
  SliverToBoxAdapter _buildTrustedBySection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 60, horizontal: 40),
        color: Colors.white,
        child: Column(
          children: [
            FadeInUp(
              child: Text(
                'Ils nous font confiance',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
            SizedBox(height: 40),
            FadeInUp(
              delay: Duration(milliseconds: 200),
              child: Wrap(
                spacing: 60,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                children: [
                  _buildClientLogo('🏨 Grand Hotel Paris'),
                  _buildClientLogo('🌴 Resort Paradise'),
                  _buildClientLogo('⭐ Luxury Suites'),
                  _buildClientLogo('🍽️ Restaurant Le Gourmet'),
                  _buildClientLogo('🏖️ Beach Resort'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientLogo(String name) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // ==================== FEATURES SHOWCASE MODERNE ====================
  SliverToBoxAdapter _buildFeaturesShowcase() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 100, horizontal: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Column(
          children: [
            FadeInUp(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✨ FONCTIONNALITÉS',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            FadeInUp(
              delay: Duration(milliseconds: 200),
              child: Text(
                'Tout ce dont vous avez besoin',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.darkColor,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 15),
            FadeInUp(
              delay: Duration(milliseconds: 400),
              child: Container(
                constraints: BoxConstraints(maxWidth: 700),
                child: Text(
                  'Une suite complète d\'outils pour gérer votre établissement de A à Z',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 80),
            _buildStepsTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsTimeline() {
    final steps = [
      {
        'number': '01',
        'title': 'Créez votre compte',
        'description': 'Inscription en 2 minutes. Aucune carte bancaire requise.',
        'icon': Icons.person_add,
        'color': Colors.blue,
      },
      {
        'number': '02',
        'title': 'Configurez votre hôtel',
        'description': 'Ajoutez vos chambres, services et tarifs en quelques clics.',
        'icon': Icons.settings,
        'color': Colors.purple,
      },
      {
        'number': '03',
        'title': 'Importez vos données',
        'description': 'Migration automatique depuis votre ancien système.',
        'icon': Icons.cloud_upload,
        'color': Colors.orange,
      },
      {
        'number': '04',
        'title': 'Lancez-vous !',
        'description': 'Commencez à gérer votre établissement efficacement.',
        'icon': Icons.rocket_launch,
        'color': Colors.green,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: steps.asMap().entries.map((entry) {
              return Column(
                children: [
                  FadeInUp(
                    delay: Duration(milliseconds: 100 * entry.key),
                    child: _buildStepCard(entry.value),
                  ),
                  if (entry.key < steps.length - 1)
                    Container(
                      height: 60,
                      width: 2,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            entry.value['color'] as Color,
                            steps[entry.key + 1]['color'] as Color,
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps.asMap().entries.map((entry) {
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: FadeInUp(
                      delay: Duration(milliseconds: 100 * entry.key),
                      child: _buildStepCard(entry.value),
                    ),
                  ),
                  if (entry.key < steps.length - 1)
                    Container(
                      width: 40,
                      height: 2,
                      margin: EdgeInsets.only(top: 60),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            entry.value['color'] as Color,
                            steps[entry.key + 1]['color'] as Color,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStepCard(Map<String, dynamic> step) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: (step['color'] as Color).withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  step['color'] as Color,
                  (step['color'] as Color).withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (step['color'] as Color).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              step['icon'] as IconData,
              color: Colors.white,
              size: 36,
            ),
          ),
          SizedBox(height: 20),
          Text(
            step['number'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: step['color'] as Color,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            step['title'],
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppConstants.darkColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            step['description'],
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== TESTIMONIALS MODERNE ====================
  SliverToBoxAdapter _buildTestimonialsModern() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 100, horizontal: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor.withOpacity(0.05),
              AppConstants.secondaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            FadeInUp(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '💬 TÉMOIGNAGES',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            FadeInUp(
              delay: Duration(milliseconds: 200),
              child: Text(
                'Ce que disent nos clients',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.darkColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 80),
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1),
                  crossAxisSpacing: 30,
                  mainAxisSpacing: 30,
                  childAspectRatio: 0.85,
                  children: AppConstants.testimonials.asMap().entries.map((entry) {
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * entry.key),
                      child: _buildModernTestimonialCard(entry.value),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTestimonialCard(Map<String, String> testimonial) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (index) =>
                Icon(Icons.star, color: Colors.amber, size: 20),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Text(
              '"${testimonial['text']!}"',
              style: TextStyle(
                fontSize: 16,
                color: AppConstants.darkColor,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(height: 20),
          Divider(color: Colors.grey[200]),
          SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    testimonial['author']!.substring(0, 1),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial['author']!,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppConstants.darkColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      testimonial['position']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== PRICING MODERNE ====================
  SliverToBoxAdapter _buildPricingModern(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 100, horizontal: 40),
        color: Colors.white,
        child: Column(
          children: [
            FadeInUp(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '💰 TARIFS',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            FadeInUp(
              delay: Duration(milliseconds: 200),
              child: Text(
                'Des prix transparents',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.darkColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 15),
            FadeInUp(
              delay: Duration(milliseconds: 400),
              child: Text(
                'Choisissez le plan qui correspond à vos besoins',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 60),
            LayoutBuilder(
              builder: (context, constraints) {
                final displayPlans = AppConstants.pricingPlans.take(3).toList();
                return constraints.maxWidth > 900
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: displayPlans.asMap().entries.map((entry) {
                    return Expanded(
                      child: FadeInUp(
                        delay: Duration(milliseconds: 100 * entry.key),
                        child: _buildModernPricingCard(context, entry.value),
                      ),
                    );
                  }).toList(),
                )
                    : Column(
                  children: displayPlans.asMap().entries.map((entry) {
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * entry.key),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 30),
                        child: _buildModernPricingCard(context, entry.value),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 60),
            FadeInUp(
              child: TextButton.icon(
                icon: Icon(Icons.arrow_forward, size: 20),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.tarifpage),
                label: Text(
                  'Voir tous les tarifs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPricingCard(BuildContext context, Map<String, dynamic> plan) {
    final bool isPopular = plan['isPopular'] as bool;
    final Color planColor = plan['color'] as Color;
    final int? priceMonthly = plan['priceMonthly'] as int?;
    final String? badge = plan['badge'] as String?;
    final NumberFormat currencyFormatter = NumberFormat('#,###', 'fr_FR');

    int? priceAnnual;
    int? savings;
    if (priceMonthly != null) {
      priceAnnual = AppConstants.calculateAnnualPrice(priceMonthly);
      savings = AppConstants.calculateSavings(priceMonthly);
    }

    return Container(
      margin: EdgeInsets.all(10),
      constraints: BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular ? planColor : Colors.grey[200]!,
          width: isPopular ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? planColor.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: isPopular ? 30 : 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (badge != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [planColor, planColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: Text(
                badge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(40),
            child: Column(
              children: [
                Text(
                  plan['name'],
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: planColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  plan['description'],
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan['currency'] != '')
                      Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          plan['currency'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.darkColor,
                          ),
                        ),
                      ),
                    SizedBox(width: 5),
                    Text(
                      priceMonthly != null
                          ? currencyFormatter.format(priceMonthly)
                          : 'Sur mesure',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.darkColor,
                        height: 1,
                      ),
                    ),
                    if (priceMonthly != null)
                      Padding(
                        padding: EdgeInsets.only(top: 18),
                        child: Text(
                          '/mois',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
                if (priceMonthly != null && savings != null)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '💰 Économisez ${currencyFormatter.format(savings)} /an',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? planColor : Colors.white,
                      foregroundColor: isPopular ? Colors.white : planColor,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: planColor,
                          width: isPopular ? 0 : 2,
                        ),
                      ),
                      elevation: isPopular ? 4 : 0,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.register,
                        arguments: {
                          'planId': plan['planId'],
                          'billingCycle': 'monthly',
                          'planName': plan['name'],
                          'priceValue': priceMonthly,
                          'currency': plan['currency'],
                        },
                      );
                    },
                    child: Text(
                      plan['buttonText'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Divider(color: Colors.grey[200]),
                SizedBox(height: 24),
                ...(plan['features'] as List<String>).map((feature) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: planColor,
                          size: 22,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppConstants.darkColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FAQ ACCORDION ====================
  SliverToBoxAdapter _buildFaqAccordion() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 100, horizontal: 40),
        color: Colors.grey[50],
        child: Column(
          children: [
            FadeInUp(
              child: Text(
                'Questions fréquentes',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.darkColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 60),
            Container(
              constraints: BoxConstraints(maxWidth: 900),
              child: Column(
                children: AppConstants.faqs.asMap().entries.map((entry) {
                  return FadeInUp(
                    delay: Duration(milliseconds: 50 * entry.key),
                    child: _buildModernFaqItem(entry.value),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFaqItem(Map<String, String> faq) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          childrenPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.help_outline,
              color: AppConstants.primaryColor,
              size: 24,
            ),
          ),
          title: Text(
            faq['question']!,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppConstants.darkColor,
            ),
          ),
          children: [
            Text(
              faq['answer']!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CTA SECTION ====================
  SliverToBoxAdapter _buildCtaSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 120, horizontal: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor,
              AppConstants.secondaryColor,
            ],
          ),
        ),
        child: FadeInUp(
          child: Column(
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Text(
                      'Prêt à transformer votre hôtel ?',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Rejoignez des centaines d\'hôteliers qui ont déjà fait le choix de Gesto',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.95),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 50),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.rocket_launch, size: 24),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppConstants.primaryColor,
                              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                            label: Text(
                              'Démarrer gratuitement',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: Icon(Icons.phone_android, size: 24),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 24),
                            side: BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.mobileDownload);
                          },
                          label: Text(
                            'Télécharger l\'App Mobile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: Icon(Icons.calendar_today, size: 24),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 24),
                            side: BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.contactpage),
                          label: Text(
                            'Réserver une démo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCtaBadge(Icons.credit_card_off, 'Sans CB'),
                        SizedBox(width: 30),
                        _buildCtaBadge(Icons.access_time, '30 jours gratuits'),
                        SizedBox(width: 30),
                        _buildCtaBadge(Icons.cancel, 'Sans engagement'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCtaBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==================== FOOTER MODERNE ====================
  SliverToBoxAdapter _buildFooterModern(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 80, horizontal: 40),
        color: AppConstants.darkColor,
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      _buildFooterBrand(),
                      SizedBox(height: 50),
                      ...AppConstants.footerSections.entries.map(
                            (section) => Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: _buildFooterColumn(context, section.key, section.value),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildFooterBrand()),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: AppConstants.footerSections.entries
                            .map((section) => _buildFooterColumn(context, section.key, section.value))
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 60),
            Divider(color: Colors.white.withOpacity(0.1)),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppConstants.copyrightText,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
                _buildSocialIcons(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.hotel, color: Colors.white, size: 32),
            ),
            SizedBox(width: 15),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        Container(
          constraints: BoxConstraints(maxWidth: 300),
          child: Text(
            AppConstants.appDescription,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
        SizedBox(height: 30),
        _buildFooterContactInfo(Icons.email, AppConstants.companyEmail),
        SizedBox(height: 12),
        _buildFooterContactInfo(Icons.phone, AppConstants.companyPhone),
        SizedBox(height: 12),
        _buildFooterContactInfo(Icons.location_on, AppConstants.companyAddress),
      ],
    );
  }

  Widget _buildFooterContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppConstants.primaryColor, size: 18),
        ),
        SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterColumn(
      BuildContext context,
      String title,
      List<Map<String, String>> items,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 24),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: () {
              if (item['route'] != null) {
                Navigator.pushNamed(context, item['route']!);
              }
            },
            child: Text(
              item['label']!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildSocialIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(Icons.facebook, AppConstants.facebookUrl),
        SizedBox(width: 12),
        _buildSocialIcon(Icons.flutter_dash, AppConstants.twitterUrl),
        SizedBox(width: 12),
        _buildSocialIcon(Icons.business, AppConstants.linkedinUrl),
        SizedBox(width: 12),
        _buildSocialIcon(Icons.photo_camera, AppConstants.instagramUrl),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () {
        // Ouvrir l'URL
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
      ),
    );
  }

  // ==================== FLOATING BACK BUTTON ====================
  Widget _buildFloatingBackButton() {
    return Positioned(
      bottom: 30,
      right: 30,
      child: FadeIn(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.4),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Icon(Icons.arrow_upward, size: 28),
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: Duration(milliseconds: 800),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ==================== MODERN PATTERN PAINTER ====================
class ModernPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Grille de points
    for (int i = 0; i < size.width; i += 80) {
      for (int j = 0; j < size.height; j += 80) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 2, paint);
      }
    }

    // Lignes diagonales
    for (int i = -size.height.toInt(); i < size.width; i += 150) {
      final path = Path();
      path.moveTo(i.toDouble(), 0);
      path.lineTo(i + size.height, size.height);
      canvas.drawPath(path, paint..strokeWidth = 0.5);
    }

    // Cercles décoratifs
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      150,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      200,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      100,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


Widget _buildFeatureGrid() {
  final features = [
    {
      'icon': Icons.calendar_today,
      'title': 'Gestion des réservations',
      'description': 'Planifiez et gérez toutes vos réservations en temps réel',
      'color': Colors.blue,
    },
    {
      'icon': Icons.restaurant_menu,
      'title': 'Point de vente restaurant',
      'description': 'Système POS complet pour votre restaurant et bar',
      'color': Colors.orange,
    },
    {
      'icon': Icons.people,
      'title': 'Gestion des clients',
      'description': 'Base de données clients avec historique et préférences',
      'color': Colors.purple,
    },
    {
      'icon': Icons.analytics,
      'title': 'Analyses & Rapports',
      'description': 'Tableaux de bord détaillés pour suivre vos performances',
      'color': Colors.green,
    },
    {
      'icon': Icons.room_service,
      'title': 'Service en chambre',
      'description': 'Gérez les commandes et demandes des clients',
      'color': Colors.red,
    },
    {
      'icon': Icons.inventory_2,
      'title': 'Gestion des stocks',
      'description': 'Suivez votre inventaire en temps réel',
      'color': Colors.teal,
    },
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      return GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1),
        crossAxisSpacing: 30,
        mainAxisSpacing: 30,
        childAspectRatio: 1.1,
        children: features.asMap().entries.map((entry) {
          return FadeInUp(
            delay: Duration(milliseconds: 100 * entry.key),
            child: _buildModernFeatureCard(entry.value),
          );
        }).toList(),
      );
    },
  );
}

Widget _buildModernFeatureCard(Map<String, dynamic> feature) {
  return Container(
    padding: EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: [
        BoxShadow(
          color: (feature['color'] as Color).withOpacity(0.1),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (feature['color'] as Color).withOpacity(0.1),
                (feature['color'] as Color).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            feature['icon'] as IconData,
            size: 48,
            color: feature['color'] as Color,
          ),
        ),
        SizedBox(height: 24),
        Text(
          feature['title'],
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppConstants.darkColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          feature['description'],
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// ==================== DEMO INTERACTIVE ====================
SliverToBoxAdapter _buildInteractiveDemo() {
  return SliverToBoxAdapter(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      color: AppConstants.darkColor,
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              'Découvrez Gesto en action',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 60),
          FadeInUp(
            delay: Duration(milliseconds: 300),
            child: Container(
              constraints: BoxConstraints(maxWidth: 1200),
              height: 600,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  AppConstants.dashboardPreviewPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ==================== BENEFITS AVEC VISUELS ====================
SliverToBoxAdapter _buildBenefitsWithVisuals() {
  return SliverToBoxAdapter(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      color: Colors.white,
      child: Column(
        children: [
          _buildBenefitRow(
            title: 'Augmentez votre chiffre d\'affaires',
            description: 'Optimisez vos tarifs avec notre système de revenue management intelligent. Augmentez votre CA jusqu\'à 35%.',
            icon: Icons.trending_up,
            color: Colors.green,
            isReversed: false,
            stats: [
              {'value': '+35%', 'label': 'Revenus'},
              {'value': '24/7', 'label': 'Support'},
            ],
          ),
          SizedBox(height: 120),
          _buildBenefitRow(
            title: 'Automatisez vos opérations',
            description: 'Réduisez le temps passé sur les tâches administratives. Notre IA s\'occupe de tout.',
            icon: Icons.auto_awesome,
            color: Colors.purple,
            isReversed: true,
            stats: [
              {'value': '-60%', 'label': 'Temps admin'},
              {'value': '99.9%', 'label': 'Uptime'},
            ],
          ),
          SizedBox(height: 120),
          _buildBenefitRow(
            title: 'Expérience client premium',
            description: 'Offrez une expérience 5 étoiles avec notre système de communication intégré.',
            icon: Icons.diamond,
            color: Colors.orange,
            isReversed: false,
            stats: [
              {'value': '4.9/5', 'label': 'Satisfaction'},
              {'value': '+40%', 'label': 'Fidélité'},
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildBenefitRow({
  required String title,
  required String description,
  required IconData icon,
  required Color color,
  required bool isReversed,
  required List<Map<String, String>> stats,
}) {
  final content = Expanded(
    child: FadeIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppConstants.darkColor,
              height: 1.2,
            ),
          ),
          SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
          SizedBox(height: 32),
          Row(
            children: stats.map((stat) {
              return Padding(
                padding: EdgeInsets.only(right: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['value']!,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      stat['label']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ),
  );

  final visual = Expanded(
    child: FadeIn(
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Icon(icon, size: 120, color: color.withOpacity(0.3)),
        ),
      ),
    ),
  );

  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 900) {
        return Column(
          children: [content, SizedBox(height: 40), visual],
        );
      }
      return Row(
        children: isReversed
            ? [visual, SizedBox(width: 80), content]
            : [content, SizedBox(width: 80), visual],
      );
    },
  );
}

SliverToBoxAdapter _buildHowItWorks() {
  return SliverToBoxAdapter(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      color: Colors.grey[50],
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              'Comment ça marche ?',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppConstants.darkColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 80),
          _buildStepsTimeline(),
        ],
      ),
    ),
  );
}
Widget _buildStepsTimeline() {
  final steps = [
    {
      'number': '01',
      'title': 'Créez votre compte',
      'description': 'Inscription en 2 minutes. Aucune carte bancaire requise.',
      'icon': Icons.person_add,
      'color': Colors.blue,
    },
    {
      'number': '02',
      'title': 'Configurez votre hôtel',
      'description': 'Ajoutez vos chambres, services et tarifs en quelques clics.',
      'icon': Icons.settings,
      'color': Colors.purple,
    },
    {
      'number': '03',
      'title': 'Importez vos données',
      'description': 'Migration automatique depuis votre ancien système.',
      'icon': Icons.cloud_upload,
      'color': Colors.orange,
    },
    {
      'number': '04',
      'title': 'Lancez-vous !',
      'description': 'Commencez à gérer votre établissement efficacement.',
      'icon': Icons.rocket_launch,
      'color': Colors.green,
    },
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 900) {
        return Column(
          children: steps.asMap().entries.map((entry) {
            return Column(
              children: [
                FadeInUp(
                  delay: Duration(milliseconds: 100 * entry.key),
                  child: _buildStepCard(entry.value),
                ),
                if (entry.key < steps.length - 1)
                  Container(
                    height: 60,
                    width: 2,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          entry.value['color'] as Color,
                          steps[entry.key + 1]['color'] as Color,
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }).toList(),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps.asMap().entries.map((entry) {
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: FadeInUp(
                    delay: Duration(milliseconds: 100 * entry.key),
                    child: _buildStepCard(entry.value),
                  ),
                ),
                if (entry.key < steps.length - 1)
                  Container(
                    width: 40,
                    height: 2,
                    margin: EdgeInsets.only(top: 60),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          entry.value['color'] as Color,
                          steps[entry.key + 1]['color'] as Color,
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      );
    },
  );
}

Widget _buildStepCard(Map<String, dynamic> step) {
  return Container(
    padding: EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: [
        BoxShadow(
          color: (step['color'] as Color).withOpacity(0.1),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                step['color'] as Color,
                (step['color'] as Color).withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (step['color'] as Color).withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            step['icon'] as IconData,
            color: Colors.white,
            size: 36,
          ),
        ),
        SizedBox(height: 20),
        Text(
          step['number'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: step['color'] as Color,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 12),
        Text(
          step['title'],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppConstants.darkColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          step['description'],
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
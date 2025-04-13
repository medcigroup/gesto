import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;  // Utiliser avec alias pour éviter toute confusion

import 'config/routes.dart';

class GestoLandingPage extends StatefulWidget {
  const GestoLandingPage({Key? key}) : super(key: key);

  @override
  _GestoLandingPageState createState() => _GestoLandingPageState();
}

class _GestoLandingPageState extends State<GestoLandingPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        if (_scrollController.offset >= 300) {
          _showBackToTopButton = true;
        } else {
          _showBackToTopButton = false;
        }
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
    // Palette de couleurs modernisée
    final primaryColor = Color(0xFF6366F1);
    final secondaryColor = Color(0xFF10B981);
    final accentColor = Color(0xFFFF6B6B);
    final backgroundColor = Colors.white;
    final darkColor = Color(0xFF0F172A);

    final headlineFont = GoogleFonts.poppins(
      fontWeight: FontWeight.w800,
      color: darkColor,
    );

    final bodyFont = GoogleFonts.poppins(
      color: Colors.grey[700],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, primaryColor),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: BouncingScrollPhysics(),
            slivers: [
              buildHeaderSliver(context, headlineFont, bodyFont, primaryColor, secondaryColor),
              _buildHeroSectionSliver(context, headlineFont, bodyFont, primaryColor),
              _buildFeaturesSectionSliver(headlineFont, bodyFont, primaryColor, secondaryColor, accentColor),
              _buildTestimonialsSliver(headlineFont, bodyFont, primaryColor),
              _buildCallToActionSliver(context, headlineFont, primaryColor, darkColor),
              _buildFooterSliver(bodyFont, darkColor),
            ],
          ),
          if (_showBackToTopButton)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: primaryColor,
                child: Icon(Icons.arrow_upward),
                onPressed: () {
                  _scrollController.animateTo(0,
                      duration: Duration(seconds: 1),
                      curve: Curves.easeInOut);
                },
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color primaryColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Text('Gesto',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.contactpage),
          child: Text('Nous Contacter', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.tarifpage),
          child: Text('Tarifs', style: TextStyle(color: Colors.white)),
        ),
        SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: primaryColor,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
          child: Text('Se connecter'),
        ),
        SizedBox(width: 20),
      ],
    );
  }

  // Modification de la signature de la méthode pour accepter BuildContext en premier paramètre
  SliverToBoxAdapter buildHeaderSliver(BuildContext context, TextStyle headlineFont, TextStyle bodyFont, Color primaryColor, Color secondaryColor) {
    return SliverToBoxAdapter(
      child: Container(
        height: 700,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
        ),
        child: Stack(
          children: [
            // Motif graphique moderne en arrière plan
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: BackgroundPatternPainter(),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElasticIn(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/gesto_logo.png',
                          width: 250,
                          height: 250,
                        ),
                        // Le SizedBox et le Text ont été supprimés ici
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  FadeInUp(
                    delay: Duration(milliseconds: 200),
                    child: Container(
                      width: 700,
                      child: Text(
                        'Réinventez la gestion hôtelière avec intelligence',
                        textAlign: TextAlign.center,
                        style: bodyFont.copyWith(fontSize: 24, color: Colors.white.withOpacity(0.9)),
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  FadeInUp(
                    delay: Duration(milliseconds: 400),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: primaryColor,
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                      child: Text('Commencer votre essai gratuit',
                          style: bodyFont.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryColor)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeroSectionSliver(BuildContext context, TextStyle headlineFont, TextStyle bodyFont, Color primaryColor) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        transform: Matrix4.translationValues(0, -40, 0),
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return constraints.maxWidth < 900
                ? _buildMobileHero(context, headlineFont, bodyFont, primaryColor)
                : _buildDesktopHero(context, headlineFont, bodyFont, primaryColor);
          },
        ),
      ),
    );
  }

  Widget _buildMobileHero(BuildContext context, TextStyle headlineFont, TextStyle bodyFont, Color primaryColor) {
    return Column(
      children: [
        FadeInLeft(
          child: Text('L\'excellence opérationnelle simplifiée',
              style: headlineFont.copyWith(fontSize: 36)),
        ),
        SizedBox(height: 20),
        FadeInRight(
          child: Text('Une plateforme unifiée pour la gestion intelligente des hôtels.',
              textAlign: TextAlign.center, style: bodyFont.copyWith(fontSize: 18)),
        ),
        SizedBox(height: 30),
        FadeInUp(child: _buildHeroButtons(context)),
        SizedBox(height: 40),
        FadeInUp(
          delay: Duration(milliseconds: 300),
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage('assets/images/dashboard_preview.jpg'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHero(BuildContext context, TextStyle headlineFont, TextStyle bodyFont, Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInLeft(
                child: Text('L\'excellence opérationnelle simplifiée',
                    style: headlineFont.copyWith(fontSize: 48)),
              ),
              SizedBox(height: 30),
              FadeInLeft(
                delay: Duration(milliseconds: 200),
                child: Text('Une plateforme unifiée pour la gestion intelligente des hôtels.',
                    style: bodyFont.copyWith(fontSize: 18)),
              ),
              SizedBox(height: 40),
              FadeInLeft(
                delay: Duration(milliseconds: 400),
                child: _buildHeroButtons(context),
              ),
            ],
          ),
        ),
        SizedBox(width: 40),
        Expanded(
          child: FadeInRight(
            delay: Duration(milliseconds: 300),
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage('assets/images/dashboard_preview.jpg'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroButtons(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 15,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
          child: Text('Essai gratuit 30 jours'),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
          child: Text('Se connecter'),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildFeaturesSectionSliver(TextStyle headlineFont, TextStyle bodyFont, Color primaryColor, Color secondaryColor, Color accentColor) {
    return SliverToBoxAdapter(
        child: Container(
        padding: EdgeInsets.symmetric(vertical: 80),
    color: Colors.grey[50],
    child: Column(
    children: [
    FadeInUp(
    child: Text(
    'Découvrez notre écosystème',
    style: headlineFont.copyWith(fontSize: 36, color: Colors.black),
    textAlign: TextAlign.center,
    ),
    ),
    SizedBox(height: 20),
    FadeInUp(
    delay: Duration(milliseconds: 200),
    child: Text(
    'Solutions complètes pour l\'industrie hôtelière',
    style: bodyFont.copyWith(fontSize: 18),
    textAlign: TextAlign.center,
    ),
    ),
    SizedBox(height: 60),
    Padding(
    padding: EdgeInsets.symmetric(horizontal: 40),
    child: Builder(
    builder: (context) {
    return GridView.count(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 3 :
    (MediaQuery.of(context).size.width > 600 ? 2 : 1),
    crossAxisSpacing: 30,
    mainAxisSpacing: 30,
    childAspectRatio: 1.0,
    children: [
    _buildModernFeatureCard(
    icon: Icons.hotel_rounded,
    title: 'Gestion Hôtelière',
    description: 'Suivi en temps réel, gestion multi-propriétés, contrôle d\'accès',
    color: primaryColor,
    bodyFont: bodyFont,
    ),
    _buildModernFeatureCard(
    icon: Icons.restaurant_menu_rounded,
    title: 'Solution Restauration',
    description: 'Commandes en ligne, gestion de stocks, analyse des ventes',
    color: secondaryColor,
    bodyFont: bodyFont,
    ),
    _buildModernFeatureCard(
    icon: Icons.analytics_rounded,
    title: 'Analyses Avancées',
    description: 'Tableaux de bord personnalisés, prévisions et insights business',
    color: accentColor,
    bodyFont: bodyFont,
    ),
    _buildModernFeatureCard(
    icon: Icons.support_agent_rounded,
    title: 'Service Client',
    description: 'Gestion des demandes, historique client, suivi de satisfaction',
    color: Color(0xFF8B5CF6),
    bodyFont: bodyFont,
    ),
      _buildModernFeatureCard(
        icon: Icons.payments_rounded,
        title: 'Gestion Financière',
        description: 'Facturation automatique, paiements sécurisés, rapports financiers détaillés',
        color: Color(0xFF3B82F6),
        bodyFont: bodyFont,
      ),
      _buildModernFeatureCard(
        icon: Icons.calendar_month_rounded,
        title: 'Réservations',
        description: 'Système de réservation en ligne, optimisation du taux d\'occupation',
        color: Color(0xFFF59E0B),
        bodyFont: bodyFont,
      ),
    ],
    );
    },
    ),
    ),
    ],
    ),
        ),
    );
  }

  Widget _buildModernFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required TextStyle bodyFont,
  }) {
    return FadeInUp(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            SizedBox(height: 20),
            Text(
              title,
              style: bodyFont.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: bodyFont.copyWith(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildTestimonialsSliver(TextStyle headlineFont, TextStyle bodyFont, Color primaryColor) {
    final testimonials = [
      {
        'text': 'Gesto a révolutionné notre façon de gérer notre chaîne d\'hôtels. Notre efficacité a augmenté de 40% en quelques mois.',
        'author': 'Marie Dupont',
        'position': 'Directrice, Hôtels Royale'
      },
      {
        'text': 'Une solution complète qui s\'adapte parfaitement à nos besoins spécifiques. Le support client est exceptionnel.',
        'author': 'Thomas Martin',
        'position': 'Gérant, Le Grand Resort'
      },
      {
        'text': 'L\'interface intuitive permet à notre équipe de se former rapidement. Un investissement qui a rapidement porté ses fruits.',
        'author': 'Sophie Bernard',
        'position': 'Opérations, Boutique Hôtels'
      },
    ];

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 80, horizontal: 40),
        child: Column(
          children: [
            FadeInUp(
              child: Text(
                'Ce que nos clients disent',
                style: headlineFont.copyWith(fontSize: 36),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 60),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: testimonials.map((t) => Expanded(
                      child: _buildTestimonialCard(t, bodyFont, primaryColor),
                    )).toList(),
                  );
                } else {
                  return Column(
                    children: testimonials.map((t) => Padding(
                      padding: EdgeInsets.only(bottom: 30),
                      child: _buildTestimonialCard(t, bodyFont, primaryColor),
                    )).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonialCard(Map<String, String> testimonial, TextStyle bodyFont, Color primaryColor) {
    return FadeInUp(
      child: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.format_quote, size: 40, color: primaryColor.withOpacity(0.2)),
            SizedBox(height: 15),
            Text(
              testimonial['text']!,
              style: bodyFont.copyWith(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.2),
                  child: Text(
                    testimonial['author']!.substring(0, 1),
                    style: TextStyle(color: primaryColor),
                  ),
                ),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial['author']!,
                      style: bodyFont.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      testimonial['position']!,
                      style: bodyFont.copyWith(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildCallToActionSliver(BuildContext context, TextStyle headlineFont, Color primaryColor, Color darkColor) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 100, horizontal: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor.withOpacity(0.8), primaryColor],
          ),
        ),
        child: FadeInUp(
          child: Column(
            children: [
              Text('Prêt à transformer votre gestion hôtelière ?',
                  style: headlineFont.copyWith(fontSize: 36, color: Colors.white)),
              SizedBox(height: 20),
              Text(
                'Essai gratuit de 30 jours, sans engagement. Démarrez en moins de 5 minutes.',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.white.withOpacity(0.9)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                child: Text('Commencer maintenant',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildFooterSliver(TextStyle bodyFont, Color darkColor) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 60, horizontal: 40),
        color: darkColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                          ElasticIn(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/gesto_logo.png',
                                  width: 100,
                                  height: 100,
                                ),
                                // Le SizedBox et le Text ont été supprimés ici
                              ],
                            ),
                          ),
                    SizedBox(height: 15),
                    Container(
                      width: 300,
                      child: Text(
                        'Solutions innovantes pour l\'industrie hôtelière',
                        style: bodyFont.copyWith(color: Colors.white.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 40,
                  children: [
                    _buildFooterColumn('Produit', ['Fonctionnalités', 'Tarifs', 'FAQ', 'Témoignages'], bodyFont),
                    _buildFooterColumn('Entreprise', ['À propos', 'Blog', 'Carrières', 'Contact'], bodyFont),
                    _buildFooterColumn('Légal', ['Confidentialité', 'Conditions', 'Cookies'], bodyFont),
                  ],
                ),
              ],
            ),
            SizedBox(height: 60),
            Divider(color: Colors.white.withOpacity(0.1)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('© 2024 Gesto. Tous droits réservés.',
                    style: bodyFont.copyWith(color: Colors.white.withOpacity(0.7))),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.facebook, color: Colors.white.withOpacity(0.7)),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterColumn(String title, List<String> items, TextStyle bodyFont) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: bodyFont.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        SizedBox(height: 15),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: TextButton(
            onPressed: () {},
            child: Text(item, style: bodyFont.copyWith(color: Colors.white.withOpacity(0.7))),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        )),
      ],
    );
  }
}

// Classe pour créer un motif graphique moderne en arrière-plan
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Motif de lignes et de cercles
    for (int i = 0; i < size.width; i += 60) {
      for (int j = 0; j < size.height; j += 60) {
        // Dessiner un cercle à chaque intersection
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 2, paint);

        // Lignes horizontales et verticales
        if (i % 180 == 0) {
          canvas.drawLine(
            Offset(i.toDouble(), 0),
            Offset(i.toDouble(), size.height),
            paint,
          );
        }

        if (j % 180 == 0) {
          canvas.drawLine(
            Offset(0, j.toDouble()),
            Offset(size.width, j.toDouble()),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


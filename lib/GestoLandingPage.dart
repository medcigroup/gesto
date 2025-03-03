import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/routes.dart';

class GestoLandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF6366F1);
    final secondaryColor = Color(0xFF10B981);
    final accentColor = Color(0xFFFF6B6B);
    final backgroundColor = Colors.white;
    final darkColor = Color(0xFF0F172A);

    final headlineFont = GoogleFonts.inter(
      fontWeight: FontWeight.w800,
      color: darkColor,
    );

    final bodyFont = GoogleFonts.inter(
      color: Colors.grey[700],
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeaderSliver(headlineFont, bodyFont, primaryColor, secondaryColor),
          _buildHeroSectionSliver(context, headlineFont, bodyFont, primaryColor),
          _buildFeaturesSectionSliver(headlineFont, bodyFont, primaryColor, secondaryColor, accentColor),
          _buildCallToActionSliver(context, headlineFont, primaryColor, darkColor),
          _buildFooterSliver(bodyFont, darkColor),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildHeaderSliver(TextStyle headlineFont, TextStyle bodyFont, Color primaryColor, Color secondaryColor) {
    return SliverToBoxAdapter(
      child: FadeInDown(
        duration: Duration(milliseconds: 800),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 80, horizontal: 20),
          child: Column(
            children: [
              ElasticIn(
                child: Text('Gesto',
                  style: headlineFont.copyWith(fontSize: 48, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              FadeInUp(
                delay: Duration(milliseconds: 200),
                child: Text(
                  'Réinventez la gestion hôtelière avec intelligence',
                  textAlign: TextAlign.center,
                  style: bodyFont.copyWith(fontSize: 20, color: Colors.white.withOpacity(0.9)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildHeroSectionSliver(BuildContext context, TextStyle headlineFont, TextStyle bodyFont, Color primaryColor) {
    return SliverToBoxAdapter(
      child: Padding(
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
        Text('L\'excellence opérationnelle simplifiée', style: headlineFont.copyWith(fontSize: 36)),
        SizedBox(height: 20),
        Text('Une plateforme unifiée pour la gestion intelligente des hôtels.',
            textAlign: TextAlign.center, style: bodyFont.copyWith(fontSize: 18)),
        SizedBox(height: 30),
        _buildHeroButtons(context),
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
              Text('L\'excellence opérationnelle simplifiée', style: headlineFont.copyWith(fontSize: 48)),
              SizedBox(height: 30),
              Text('Une plateforme unifiée pour la gestion intelligente des hôtels.',
                  style: bodyFont.copyWith(fontSize: 18)),
              SizedBox(height: 40),
              _buildHeroButtons(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroButtons(BuildContext context) {
    return Wrap(
      spacing: 20,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
          child: Text('Essai gratuit 30 jours'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
          child: Text('Se connecter'),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildFeaturesSectionSliver(TextStyle headlineFont, TextStyle bodyFont, Color primaryColor, Color secondaryColor, Color accentColor) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              'Découvrez notre écosystème',
              style: headlineFont.copyWith(fontSize: 36, color: accentColor),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 60),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Builder(
              builder: (context) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                  crossAxisSpacing: 30,
                  mainAxisSpacing: 30,
                  childAspectRatio: 1.2,
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
                  ],
                );
              },
            ),
          ),
        ],
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: color,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            SizedBox(height: 20),
            Text(title, style: bodyFont.copyWith(fontSize: 22, color: Colors.white)),
            SizedBox(height: 10),
            Text(description, style: bodyFont.copyWith(color: Colors.white.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildCallToActionSliver(BuildContext context, TextStyle headlineFont, Color primaryColor, Color darkColor) {
    return SliverToBoxAdapter(
      child: FadeInUp(
        delay: Duration(milliseconds: 400),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 100),
          child: Column(
            children: [
              Text('Commencez votre essai gratuit', style: headlineFont.copyWith(fontSize: 36, color: darkColor)),
              SizedBox(height: 30),
              _buildHeroButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildFooterSliver(TextStyle bodyFont, Color darkColor) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        color: darkColor,
        child: Column(
          children: [
            Text('© 2024 Gesto. Tous droits réservés.',
                style: bodyFont.copyWith(color: Colors.white.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }
}


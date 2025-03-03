import 'package:flutter/material.dart';

import 'config/routes.dart';


class GestoLandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Définition des couleurs de l'application
    final primaryColor = Color(0xFF4A6FFF);
    final secondaryColor = Color(0xFF28CCAC);
    final backgroundColor = Colors.white;
    final textColor = Color(0xFF333333);

    return Scaffold(
      body: Container(
        color: backgroundColor,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // En-tête avec dégradé
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                ),
                padding: EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
                child: Column(
                  children: [
                    Text(
                      'Gesto',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'La solution complète pour la gestion hôtelière et restauration',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Section Hero
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenue sur Gesto',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                'Gérez votre hôtel et restaurant en toute simplicité avec notre solution tout-en-un. Optimisez vos opérations et améliorez l\'expérience client.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: 25),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.login,);
                                    },
                                    child: Text('Se connecter'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white, backgroundColor: primaryColor,
                                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.register,);
                                    },
                                    child: Text('Créer un compte'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryColor, side: BorderSide(color: primaryColor),
                                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              'assets/images/hotel_restaurant.jpeg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Section des fonctionnalités
              Container(
                padding: EdgeInsets.symmetric(vertical: 60),
                color: Color(0xFFF8F9FA),
                child: Column(
                  children: [
                    Text(
                      'Fonctionnalités principales',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    // Grille de fonctionnalités
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.3,
                        children: [
                          _buildFeatureCard(
                            icon: Icons.hotel,
                            title: 'Gestion des réservations',
                            description: 'Gérez facilement les réservations de chambres avec un calendrier intuitif',
                            color: secondaryColor,
                          ),
                          _buildFeatureCard(
                            icon: Icons.restaurant,
                            title: 'Gestion des commandes',
                            description: 'Créez et modifiez vos menus en temps réel et traitez les commandes',
                            color: secondaryColor,
                          ),
                          _buildFeatureCard(
                            icon: Icons.analytics,
                            title: 'Suivi des performances',
                            description: 'Analysez vos données financières et opérationnelles avec des tableaux de bord',
                            color: secondaryColor,
                          ),
                          _buildFeatureCard(
                            icon: Icons.phone_android,
                            title: 'Application mobile',
                            description: 'Accédez à toutes les fonctionnalités de Gesto où que vous soyez',
                            color: secondaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Section CTA
              Padding(
                padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'Prêt à simplifier votre gestion ?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Rejoignez des milliers de professionnels qui font confiance à Gesto pour optimiser leur activité.',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.register,);
                          },
                          child: Text('Essai gratuit de 30 jours'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: primaryColor,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        OutlinedButton(
                          onPressed: () {
                            // Navigation vers la démo
                          },
                          child: Text('Demander un devis'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor, side: BorderSide(color: primaryColor),
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                color: Color(0xFF333333),
                child: Column(
                  children: [
                    Text(
                      'Gesto',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFooterLink('À propos'),
                        _buildFooterLink('Fonctionnalités'),
                        _buildFooterLink('Tarifs'),
                        _buildFooterLink('Blog'),
                        _buildFooterLink('Contact'),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      '© 2025 Gesto. Tous droits réservés.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
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

  // Méthode pour créer une carte de fonctionnalité
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour créer un lien dans le footer
  Widget _buildFooterLink(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: TextButton(
        onPressed: () {
          // Navigation
        },
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
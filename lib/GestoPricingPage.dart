import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import 'config/routes.dart';

enum PlanId { gratuit, starter, pro, entreprise }

class Plan {
  final String title;
  final String price;
  final String duration;
  final List<String> features;
  final PlanId planId;
  final bool isRecommended;

  Plan({
    required this.title,
    required this.price,
    required this.duration,
    required this.features,
    required this.planId,
    required this.isRecommended,
  });
}

class GestoPricingPage extends StatelessWidget {
  GestoPricingPage({Key? key}) : super(key: key);

  final List<Plan> plans = [
    Plan(
      title: 'Essai Gratuit',
      price: '0 FCFA',
      duration: '30 jours',
      features: ['Module de réservation', '14 chambres max', 'Support de base', 'Rapports hebdo'],
      planId: PlanId.gratuit,
      isRecommended: false,
    ),
    Plan(
      title: 'Starter',
      price: '20000 FCFA',
      duration: '/mois',
      features: [
        'Module de réservation',
        '20 chambres max',
        'Gestion resto',
        '10 tables resto',
        'Support prioritaire',
        'Rapports quotidiens'
      ],
      planId: PlanId.starter,
      isRecommended: true,
    ),
    Plan(
      title: 'Starter Pro',
      price: '50000 FCFA',
      duration: '/mois',
      features: [
        'Module de réservation',
        'Chambres illimitées',
        'Gestion resto',
        'Tables resto illimitées',
        'Support 24/7',
        'Analyses temps réel',
        'Marketing tools',
        'Formation incluse'
      ],
      planId: PlanId.pro,
      isRecommended: false,
    ),
    Plan(
      title: 'Grand Hôtel',
      price: 'Sur mesure',
      duration: '',
      features: [
        'Solution personnalisée',
        'Intégrations API',
        'Account manager dédié',
        'Formation avancée',
        'Maintenance incluse'
      ],
      planId: PlanId.entreprise,
      isRecommended: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Gesto',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ),
            ),
          ),
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(headlineFont, bodyFont),
                _buildPricingPlans(context, plans, bodyFont, primaryColor, secondaryColor),
                _buildFAQSection(headlineFont, bodyFont),
                _buildCtaSection(context, headlineFont, bodyFont, primaryColor),
                _buildFooter(bodyFont, darkColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(TextStyle headlineFont, TextStyle bodyFont) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 120, 20, 40),
      child: Column(
        children: [
          FadeInDown(
            child: Text(
              'Nos tarifs',
              style: headlineFont.copyWith(fontSize: 42, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          FadeInUp(
            delay: Duration(milliseconds: 200),
            child: Text(
              'Choisissez le plan qui correspond à vos besoins',
              style: bodyFont.copyWith(fontSize: 18, color: Colors.white.withOpacity(0.9)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingPlans(BuildContext context, List<Plan> plans, TextStyle bodyFont, Color primaryColor, Color secondaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1000) {
                // Desktop layout - all plans in one row
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: plans.map((plan) {
                    return Expanded(
                      child: FadeInUp(
                        delay: Duration(milliseconds: 100 * plans.indexOf(plan)),
                        child: _buildPricingCard(context, plan, bodyFont, primaryColor, secondaryColor),
                      ),
                    );
                  }).toList(),
                );
              } else if (constraints.maxWidth > 600) {
                // Tablet layout - 2x2 grid
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FadeInUp(
                            delay: Duration(milliseconds: 100),
                            child: _buildPricingCard(context, plans[0], bodyFont, primaryColor, secondaryColor),
                          ),
                        ),
                        Expanded(
                          child: FadeInUp(
                            delay: Duration(milliseconds: 200),
                            child: _buildPricingCard(context, plans[1], bodyFont, primaryColor, secondaryColor),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FadeInUp(
                            delay: Duration(milliseconds: 300),
                            child: _buildPricingCard(context, plans[2], bodyFont, primaryColor, secondaryColor),
                          ),
                        ),
                        Expanded(
                          child: FadeInUp(
                            delay: Duration(milliseconds: 400),
                            child: _buildPricingCard(context, plans[3], bodyFont, primaryColor, secondaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Mobile layout - vertical stack
                return Column(
                  children: plans.map((plan) {
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * plans.indexOf(plan)),
                      child: _buildPricingCard(context, plan, bodyFont, primaryColor, secondaryColor),
                    );
                  }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context, Plan plan, TextStyle bodyFont, Color primaryColor, Color secondaryColor) {
    Color cardColor = Colors.white;
    Color textColor = Colors.black87;
    Color buttonColor = primaryColor;
    Color buttonTextColor = Colors.white;
    Color borderColor = Colors.grey.withOpacity(0.2);

    // Style spécial pour le plan recommandé
    if (plan.isRecommended) {
      cardColor = primaryColor;
      textColor = Colors.white;
      buttonColor = Colors.white;
      buttonTextColor = primaryColor;
      borderColor = primaryColor;
    }

    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badge pour le plan recommandé
          if (plan.isRecommended)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Text(
                'RECOMMANDÉ',
                textAlign: TextAlign.center,
                style: bodyFont.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  plan.title,
                  style: bodyFont.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.price,
                      style: bodyFont.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      plan.duration,
                      style: bodyFont.copyWith(
                        fontSize: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                // Liste des fonctionnalités
                ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: plan.isRecommended ? Colors.white : secondaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: bodyFont.copyWith(
                            color: textColor.withOpacity(0.9),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),

                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: buttonTextColor,
                    backgroundColor: buttonColor,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    if (plan.planId == PlanId.gratuit||plan.planId == PlanId.starter||plan.planId == PlanId.pro) {
                      Navigator.pushNamed(context, AppRoutes.register);
                    } else {
                      Navigator.pushNamed(context, AppRoutes.contactpage);
                    }
                  },
                  child: Text(
                    plan.planId == PlanId.gratuit
                        ? 'Démarrer l\'essai'
                        : (plan.planId == PlanId.entreprise ? 'Contacter un expert' : 'Souscrire maintenant'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(TextStyle headlineFont, TextStyle bodyFont) {
    final faqs = [
      {
        'question': 'Puis-je changer de plan à tout moment ?',
        'answer': 'Oui, vous pouvez mettre à niveau ou rétrograder votre plan à tout moment. Les modifications seront prises en compte lors de votre prochain cycle de facturation.'
      },
      {
        'question': 'Comment fonctionne l\'essai gratuit ?',
        'answer': 'L\'essai gratuit vous donne accès à toutes les fonctionnalités de base pendant 30 jours. Aucune carte de crédit n\'est requise pour commencer.'
      },
      {
        'question': 'Que se passe-t-il à la fin de mon essai gratuit ?',
        'answer': 'À la fin de votre essai gratuit, vous pourrez choisir de passer à l\'un de nos plans payants. Si vous ne faites pas de choix, votre compte sera automatiquement limité.'
      },
      {
        'question': 'Proposez-vous des remises pour les paiements annuels ?',
        'answer': 'Oui, nous offrons une remise de 15% pour tous les paiements annuels sur les plans Starter et Starter Pro.'
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      color: Colors.grey[50],
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              'Questions fréquentes',
              style: headlineFont.copyWith(fontSize: 32),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 40),
          ...faqs.map((faq) => FadeInUp(
            child: _buildFAQItem(faq['question']!, faq['answer']!, bodyFont),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, TextStyle bodyFont) {
    return Container(
        margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.03),
    blurRadius: 10,
    offset: Offset(0, 3),
    ),
    ],
    ),child: ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      title: Text(
        question,
        style: bodyFont.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            answer,
            style: bodyFont.copyWith(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildCtaSection(BuildContext context, TextStyle headlineFont, TextStyle bodyFont, Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              'Prêt à transformer votre hôtel ?',
              style: headlineFont.copyWith(fontSize: 32),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          FadeInUp(
            delay: Duration(milliseconds: 200),
            child: Text(
              'Découvrez comment Gesto peut vous aider à augmenter vos revenus et améliorer la satisfaction de vos clients',
              style: bodyFont.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 40),
          FadeInUp(
            delay: Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                  child: Text('Démarrer gratuitement'),
                ),
                SizedBox(width: 20),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.contactpage),
                  child: Text('Contacter un expert'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(TextStyle bodyFont, Color darkColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      color: darkColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Gesto',
                style: bodyFont.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Text(
                ' - Solutions hôtelières',
                style: bodyFont.copyWith(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            '© ${DateTime.now().year} Gesto. Tous droits réservés.',
            style: bodyFont.copyWith(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 20,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Mentions légales',
                  style: bodyFont.copyWith(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Politique de confidentialité',
                  style: bodyFont.copyWith(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Conditions générales',
                  style: bodyFont.copyWith(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Contact',
                  style: bodyFont.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
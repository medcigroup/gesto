import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  // ==================== INFORMATIONS DE L'APPLICATION ====================
  static const String appName = 'Gesto';
  static const String appVersion = 'v1.3.1 Build 20251217';
  static const String appTagline = 'Réinventez la gestion hôtelière avec intelligence';
  static const String appDescription = 'Solutions innovantes pour l\'industrie hôtelière';

  // ==================== COORDONNÉES ====================
  static const String companyEmail = 'contact@app.gestoapp.cloud';
  static const String companyPhone = '+225 0701997478';
  static const String companyAddress = 'Riviera 2 Anono Marché, Abidjan Côte d\'ivoire';
  static const String companySupportEmail = 'support@app.gestoapp.cloud';

  // ==================== RÉSEAUX SOCIAUX ====================
  static const String facebookUrl = 'https://facebook.com/gesto';
  static const String twitterUrl = 'https://twitter.com/gesto';
  static const String linkedinUrl = 'https://linkedin.com/company/gesto';
  static const String instagramUrl = 'https://instagram.com/gesto';

  // ==================== PALETTE DE COULEURS ====================
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Colors.white;
  static const Color darkColor = Color(0xFF0F172A);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color orangeAccent = Color(0xFFF59E0B);

  // ==================== TEXTES DE LA LANDING PAGE ====================
  static const String heroTitle = 'L\'excellence opérationnelle simplifiée';
  static const String heroSubtitle = 'Une plateforme unifiée pour la gestion intelligente des hôtels.';
  static const String ctaButton = 'Commencer votre essai gratuit';
  static const String trialDuration = '30 jours';
  static const String trialButtonText = 'Essai gratuit 30 jours';

  // ==================== SECTIONS ====================
  static const String featuresSectionTitle = 'Découvrez notre écosystème';
  static const String featuresSectionSubtitle = 'Solutions complètes pour l\'industrie hôtelière';

  static const String testimonialsSectionTitle = 'Ce que nos clients disent';

  static const String ctaSectionTitle = 'Prêt à transformer votre gestion hôtelière ?';
  static const String ctaSectionSubtitle = 'Essai gratuit de 30 jours, sans engagement. Démarrez en moins de 5 minutes.';

  // ==================== FONCTIONNALITÉS ====================
  static final List<Map<String, dynamic>> features = [
    {
      'icon': Icons.hotel_rounded,
      'title': 'Gestion Hôtelière',
      'description': 'Suivi en temps réel, gestion multi-propriétés, contrôle d\'accès',
      'color': primaryColor,
    },
    {
      'icon': Icons.restaurant_menu_rounded,
      'title': 'Solution Restauration',
      'description': 'Commandes en ligne, gestion de stocks, analyse des ventes',
      'color': secondaryColor,
    },
    {
      'icon': Icons.analytics_rounded,
      'title': 'Analyses Avancées',
      'description': 'Tableaux de bord personnalisés, prévisions et insights business',
      'color': accentColor,
    },
    {
      'icon': Icons.support_agent_rounded,
      'title': 'Service Client',
      'description': 'Gestion des demandes, historique client, suivi de satisfaction',
      'color': purpleAccent,
    },
    {
      'icon': Icons.payments_rounded,
      'title': 'Gestion Financière',
      'description': 'Facturation automatique, paiements sécurisés, rapports financiers détaillés',
      'color': blueAccent,
    },
    {
      'icon': Icons.calendar_month_rounded,
      'title': 'Réservations',
      'description': 'Système de réservation en ligne, optimisation du taux d\'occupation',
      'color': orangeAccent,
    },
  ];

  // ==================== TÉMOIGNAGES ====================
  static final List<Map<String, String>> testimonials = [
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

  // ==================== MENU DE NAVIGATION ====================
  static final List<Map<String, String>> navItems = [
    {'label': 'Nous Contacter', 'route': '/contactpage'},
    {'label': 'Tarifs', 'route': '/tarifpage'},
  ];

  // ==================== FOOTER ====================
  static const String copyrightText = '© 2024 Gesto. Tous droits réservés.';

  static final Map<String, List<Map<String, String>>> footerSections = {
    'Produit': [
      {'label': 'Fonctionnalités', 'route': '/features'},
      {'label': 'Tarifs', 'route': '/tarifpage'},
      {'label': 'FAQ', 'route': '/faq'},
      {'label': 'Témoignages', 'route': '/testimonials'},
    ],
    'Entreprise': [
      {'label': 'À propos', 'route': '/about'},
      {'label': 'Blog', 'route': '/blog'},
      {'label': 'Carrières', 'route': '/careers'},
      {'label': 'Contact', 'route': '/contactpage'},
    ],
    'Légal': [
      {'label': 'Confidentialité', 'route': '/privacy'},
      {'label': 'Conditions d\'utilisation', 'route': '/terms'},
      {'label': 'Politique de cookies', 'route': '/cookies'},
      {'label': 'Mentions légales', 'route': '/legal'},
    ],
  };

  // ==================== AVANTAGES CLIENTS ====================
  static final List<Map<String, dynamic>> benefits = [
    {
      'icon': Icons.speed,
      'title': 'Déploiement rapide',
      'description': 'Opérationnel en moins de 5 minutes',
    },
    {
      'icon': Icons.security,
      'title': 'Sécurité maximale',
      'description': 'Chiffrement de bout en bout',
    },
    {
      'icon': Icons.cloud_done,
      'title': '100% Cloud',
      'description': 'Accès depuis n\'importe où',
    },
    {
      'icon': Icons.support_agent,
      'title': 'Support 24/7',
      'description': 'Assistance en temps réel',
    },
  ];

  // ==================== PARTENAIRES ====================
  static final List<String> partners = [
    'assets/images/partner1.png',
    'assets/images/partner2.png',
    'assets/images/partner3.png',
    'assets/images/partner4.png',
    'assets/images/partner5.png',
  ];

  static const String partnersSectionTitle = 'Ils nous font confiance';

  // ==================== PROCESSUS D'ONBOARDING ====================
  static final List<Map<String, dynamic>> onboardingSteps = [
    {
      'step': '1',
      'icon': Icons.person_add,
      'title': 'Inscription',
      'description': 'Créez votre compte en 2 minutes',
    },
    {
      'step': '2',
      'icon': Icons.settings,
      'title': 'Configuration',
      'description': 'Personnalisez selon vos besoins',
    },
    {
      'step': '3',
      'icon': Icons.upload_file,
      'title': 'Import des données',
      'description': 'Importez vos données existantes',
    },
    {
      'step': '4',
      'icon': Icons.rocket_launch,
      'title': 'Lancement',
      'description': 'Commencez à gérer votre hôtel',
    },
  ];

  static const String onboardingSectionTitle = 'Démarrez en 4 étapes simples';
  static const String onboardingSectionSubtitle = 'Un processus d\'intégration fluide et guidé';

  // ==================== FAQ ====================
  static final List<Map<String, String>> faqs = [
    {
      'question': 'Combien de temps dure l\'essai gratuit ?',
      'answer': 'L\'essai gratuit dure 30 jours complets sans engagement ni carte bancaire requise.',
    },
    {
      'question': 'Puis-je annuler à tout moment ?',
      'answer': 'Oui, vous pouvez annuler votre abonnement à tout moment sans frais ni pénalités.',
    },
    {
      'question': 'Mes données sont-elles sécurisées ?',
      'answer': 'Absolument. Nous utilisons un chiffrement de bout en bout et des serveurs sécurisés certifiés.',
    },
    {
      'question': 'Proposez-vous une formation ?',
      'answer': 'Oui, nous offrons une formation complète et un support dédié pour votre équipe.',
    },
  ];

  static const String faqSectionTitle = 'Questions fréquentes';

  // ==================== PRIX ====================
  static const double annualDiscount = 0.10; // 15% de réduction
  static const String annualDiscountText = '10% de réduction';

  // Fonction helper pour calculer le prix annuel avec réduction
  static int calculateAnnualPrice(int monthlyPrice) {
    return (monthlyPrice * 12 * (1 - annualDiscount)).round();
  }

  // Fonction helper pour calculer les économies
  static int calculateSavings(int monthlyPrice) {
    return (monthlyPrice * 12) - calculateAnnualPrice(monthlyPrice);
  }

  static final List<Map<String, dynamic>> pricingPlans = [
    {
      'name': 'Basic',
      'subtitle': '(essai gratuit 30j)',
      'priceMonthly': 20000,
      'currency': 'FCFA',
      'description': 'Parfait pour débuter',
      'features': [
        '14 chambres max',
        'Limite nombre employé : 3',
        'Support de base',
        'Rapports hebdomadaires',
      ],
      'planId': 'basic',
      'color': AppConstants.secondaryColor,
      'isPopular': false,
      'buttonText': 'Démarrer l\'essai',
      'badge': 'ESSAI GRATUIT',
    },
    {
      'name': 'Starter',
      'subtitle': '',
      'priceMonthly': 30000,
      'currency': 'FCFA',
      'description': 'Le plus populaire',
      'features': [
        'Module de réservation',
        '20 chambres max',
        'Limite nombre employé : 10',
        'Support standard',
        'Rapports journaliers',
      ],
      'planId': 'starter',
      'color': AppConstants.primaryColor,
      'isPopular': true,
      'buttonText': 'Commencer maintenant',
      'badge': 'RECOMMANDÉ',
    },
    {
      'name': 'Pro',
      'subtitle': '',
      'priceMonthly': 50000,
      'currency': 'FCFA',
      'description': 'Pour les hôtels en croissance',
      'features': [
        'Module de réservation',
        'Chambres illimitées',
        'Limite nombre employé : 20',
        'Gestion resto complète',
        'Tables resto illimitées',
        'Support 24/7',
        'Analyses temps réel',
        'Marketing tools',
      ],
      'planId': 'pro',
      'color': AppConstants.blueAccent,
      'isPopular': false,
      'buttonText': 'Commencer maintenant',
      'badge': null,
    },
    {
      'name': 'Grand Hôtel',
      'subtitle': '',
      'priceMonthly': null,
      'currency': '',
      'description': 'Pour les grandes chaînes',
      'features': [
        'Solution personnalisée',
        'Chambres et employés illimités',
        'Intégrations API avancées',
        'Account manager dédié',
        'Formation sur site',
        'Maintenance prioritaire',
        'SLA garanti 99.9%',
      ],
      'planId': 'entreprise',
      'color': AppConstants.purpleAccent,
      'isPopular': false,
      'buttonText': 'Contacter un expert',
      'badge': 'SUR MESURE',
    },
  ];

  static const String pricingSectionTitle = 'Nos tarifs';
  static const String pricingSectionSubtitle = 'Choisissez le plan qui correspond à vos besoins';
  static const String pricingToggleMonthly = 'Mensuel';
  static const String pricingToggleAnnual = 'Annuel';
  static const String pricingSaveText = 'Économisez 10%';

  // ==================== FAQ TARIFS ====================
  static final List<Map<String, String>> pricingFaqs = [
    {
      'question': 'Puis-je changer de plan à tout moment ?',
      'answer': 'Oui, vous pouvez mettre à niveau ou rétrograder votre plan à tout moment. Les modifications seront prises en compte lors de votre prochain cycle de facturation.',
    },
    {
      'question': 'Comment fonctionne l\'essai gratuit ?',
      'answer': 'L\'essai gratuit vous donne accès à toutes les fonctionnalités de base pendant 30 jours. Aucune carte de crédit n\'est requise pour commencer.',
    },
    {
      'question': 'Quelle est la réduction pour le paiement annuel ?',
      'answer': 'Nous offrons une réduction de 10% sur tous nos plans (Basic, Starter et Starter Pro) lorsque vous choisissez le paiement annuel. C\'est l\'équivalent de 2 mois gratuits !',
    },
    {
      'question': 'Que se passe-t-il à la fin de mon essai gratuit ?',
      'answer': 'À la fin de votre essai gratuit, vous pourrez choisir de passer à l\'un de nos plans payants. Si vous ne faites pas de choix, votre compte sera automatiquement limité aux fonctionnalités gratuites.',
    },
    {
      'question': 'Puis-je annuler mon abonnement ?',
      'answer': 'Oui, vous pouvez annuler votre abonnement à tout moment sans frais ni pénalités. Votre accès restera actif jusqu\'à la fin de votre période de facturation.',
    },
  ];

  static const String pricingCtaTitle = 'Prêt à transformer votre hôtel ?';
  static const String pricingCtaSubtitle = 'Découvrez comment Gesto peut vous aider à augmenter vos revenus et améliorer la satisfaction de vos clients';

  // ==================== ASSETS ====================
  static const String logoPath = 'assets/images/gesto_logo.png';
  static const String dashboardPreviewPath = 'assets/images/dashboard_preview.jpg';

  // ==================== STYLES DE TEXTE ====================
  static TextStyle getHeadlineFont({Color? color}) {
    return GoogleFonts.poppins(
      fontWeight: FontWeight.w800,
      color: color ?? darkColor,
    );
  }

  static TextStyle getBodyFont({Color? color}) {
    return GoogleFonts.poppins(
      color: color ?? Colors.grey[700],
    );
  }

  // ==================== ANIMATIONS ====================
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(seconds: 1);

  // ==================== DIMENSIONS ====================
  static const double headerHeight = 700.0;
  static const double sectionPadding = 80.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 30.0;

  // ==================== BREAKPOINTS ====================
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1100.0;

  // ==================== STATISTIQUES ====================
  static const String efficiencyIncrease = '40%';
  static const String setupTime = '5 minutes';
  static const String satisfactionRate = '98%';
  static const String clientsCount = '500+';
}
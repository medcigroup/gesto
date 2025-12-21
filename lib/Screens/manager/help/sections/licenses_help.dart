import 'package:flutter/material.dart';
import '../../../../config/AppConstants.dart';
import '../help_models.dart';

/// ===============================
/// Utils Pricing
/// ===============================

int _annualPrice(int monthly, double discount) =>
    (monthly * 12 * (1 - discount)).round();

int _annualSavings(int monthly, double discount) =>
    (monthly * 12) - _annualPrice(monthly, discount);

/// ===============================
/// Widgets Prix Modernes
/// ===============================

class _PricingPlanCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final int? priceMonthly;
  final int? priceAnnual;
  final int? annualSavings;
  final String tag;
  final Color tagColor;
  final List<String> features;
  final bool isPopular;
  final bool isCustom;

  const _PricingPlanCard({
    required this.name,
    required this.subtitle,
    this.priceMonthly,
    this.priceAnnual,
    this.annualSavings,
    required this.tag,
    required this.tagColor,
    required this.features,
    this.isPopular = false,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Colors.grey.shade300,
          width: isPopular ? 2 : 1,
        ),
        color: isPopular
            ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec badge populaire
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          if (isPopular) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Le plus populaire',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(
                                  color:
                                  Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: tagColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Prix
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCustom)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$priceMonthly',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'FCFA/mois',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      if (priceAnnual != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.savings_rounded,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$priceAnnual FCFA/an',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Économisez $annualSavings FCFA',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.contact_support_rounded,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tarification personnalisée',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              Text(
                                'Contactez-nous pour un devis adapté',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(color: Colors.blue.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Fonctionnalités
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ce plan inclut :',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PaymentMethodsWidget extends StatelessWidget {
  const _PaymentMethodsWidget();

  @override
  Widget build(BuildContext context) {
    final paymentMethods = [
      {
        'icon': Icons.credit_card_rounded,
        'title': 'Carte bancaire',
        'subtitle': 'Paiement sécurisé SSL',
        'color': Colors.blue,
      },
      {
        'icon': Icons.phone_android_rounded,
        'title': 'Mobile Money',
        'subtitle': 'Wave, Orange, MTN, Moov',
        'color': Colors.green,
      },
      {
        'icon': Icons.account_balance_rounded,
        'title': 'Virement bancaire',
        'subtitle': 'Pour les entreprises',
        'color': Colors.purple,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moyens de paiement acceptés :',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...paymentMethods.map((method) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: method['color'] as Color? ?? Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    method['icon'] as IconData? ?? Icons.payment,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method['title'] as String? ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        method['subtitle'] as String? ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _LicenseExpirationWidget extends StatelessWidget {
  const _LicenseExpirationWidget();

  @override
  Widget build(BuildContext context) {
    final blockedActions = [
      'Nouvelles réservations',
      'Encaissements',
      'Ajout de chambres',
      'Ajout d\'employés',
      'Modifications des données',
    ];

    final allowedActions = [
      'Consultation du tableau de bord',
      'Accès aux historiques',
      'Export des données',
      'Visualisation des statistiques',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode lecture seule activé :',
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.block_rounded,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Actions bloquées',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...blockedActions.map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            color: Colors.red.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Actions autorisées',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...allowedActions.map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: Colors.green.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alertes automatiques',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    Text(
                      'J-14 | J-7 | J-3 | J-1',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ===============================
/// Licences & Abonnements – Aide (Modernisé)
/// ===============================

HelpCategory getLicensesHelp() {
  final plans = AppConstants.pricingPlans;
  final discount = AppConstants.annualDiscount;
  final discountText = AppConstants.annualDiscountText;
  final trialDays = AppConstants.trialDuration;

  Map<String, dynamic> plan(String name) =>
      plans.firstWhere((p) => p['name'] == name, orElse: () => {});

  final basic = plan('Basic');
  final starter = plan('Starter');
  final pro = plan('Pro');
  final enterprise = plan('Grand Hôtel');

  final starterMonthly = starter['priceMonthly'] ?? 0;
  final proMonthly = pro['priceMonthly'] ?? 0;

  return HelpCategory(
    title: 'Licences & Abonnements',
    icon: Icons.workspace_premium_rounded,
    sections: [
      /// Section 1 : Présentation des plans avec widgets modernes
      HelpSection(
        title: 'Choisir le bon plan GESTO',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GESTO propose 4 plans flexibles, adaptés à toutes les tailles d\'établissements hôteliers.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),

            // Plan Basic
            _PricingPlanCard(
              name: basic['name'] ?? 'Basic',
              subtitle: basic['subtitle'] ?? 'Parfait pour débuter',
              priceMonthly: basic['priceMonthly'] ?? 0,
              tag: 'SIMPLE',
              tagColor: Colors.green,
              features: (basic['features'] as List<dynamic>?)
                  ?.map((f) => f.toString())
                  .toList() ??
                  [],
            ),

            // Plan Starter
            _PricingPlanCard(
              name: starter['name'] ?? 'Starter',
              subtitle: starter['subtitle'] ?? 'Idéal pour la croissance',
              priceMonthly: starterMonthly,
              priceAnnual: _annualPrice(starterMonthly, discount),
              annualSavings: _annualSavings(starterMonthly, discount),
              tag: 'POPULAIRE',
              tagColor: Colors.blue,
              features: (starter['features'] as List<dynamic>?)
                  ?.map((f) => f.toString())
                  .toList() ??
                  [],
              isPopular: true,
            ),

            // Plan Pro
            _PricingPlanCard(
              name: pro['name'] ?? 'Pro',
              subtitle: pro['subtitle'] ?? 'Gestion avancée',
              priceMonthly: proMonthly,
              priceAnnual: _annualPrice(proMonthly, discount),
              annualSavings: _annualSavings(proMonthly, discount),
              tag: 'PROFESSIONNEL',
              tagColor: Colors.purple,
              features: (pro['features'] as List<dynamic>?)
                  ?.map((f) => f.toString())
                  .toList() ??
                  [],
            ),

            // Plan Enterprise
            _PricingPlanCard(
              name: enterprise['name'] ?? 'Grand Hôtel',
              subtitle: enterprise['subtitle'] ?? 'Solutions sur mesure',
              tag: 'ENTREPRISE',
              tagColor: Colors.amber.shade800,
              features: (enterprise['features'] as List<dynamic>?)
                  ?.map((f) => f.toString())
                  .toList() ??
                  [],
              isCustom: true,
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_rounded,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Essai gratuit de $trialDays jours',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Aucune carte bancaire requise',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// Section 2 : Activation & Paiement
      HelpSection(
        title: 'Activer ou renouveler votre licence',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'L\'activation de votre licence est immédiate après paiement.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            const _PaymentMethodsWidget(),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.blue.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    color: Colors.green.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Renouvellement automatique',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        Text(
                          'Activez-le pour éviter toute interruption de service',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Ouvrez **Licences / Facturation**',
          'Consultez votre plan et sa validité',
          'Cliquez sur *Renouveler* ou *Changer de plan*',
          'Choisissez la durée (mensuel / annuel)',
          'Effectuez le paiement',
          'Recevez votre facture par email',
        ],
      ),

      /// Section 3 : Expiration de licence
      HelpSection(
        title: 'Expiration de licence : que se passe-t-il ?',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'En cas d\'expiration, votre compte passe en mode lecture seule.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            const _LicenseExpirationWidget(),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.data_saver_on_rounded,
                    color: Colors.grey.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conservation des données',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Vos données sont conservées au moins 90 jours après expiration',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Surveillez la date d\'expiration',
          'Consultez les emails de rappel',
          'Renouvelez avant échéance',
          'Activez le renouvellement automatique',
        ],
      ),
    ],
  );
}
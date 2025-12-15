import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import 'config/AppConstants.dart';
import 'config/routes.dart';
class GestoPricingPage extends StatefulWidget {
  const GestoPricingPage({Key? key}) : super(key: key);

  @override
  State<GestoPricingPage> createState() => _GestoPricingPageState();
}

class _GestoPricingPageState extends State<GestoPricingPage> {
  bool _isAnnual = false;
  final NumberFormat _currencyFormatter = NumberFormat('#,###', 'fr_FR');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildHeaderGradient(),
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                _buildBillingToggle(),
                _buildPricingPlans(context),
                _buildComparisonTable(),
                _buildFAQSection(),
                _buildCtaSection(context),
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Image.asset(
            AppConstants.logoPath,
            height: 40,
          ),
          SizedBox(width: 10),
          Text(
            AppConstants.appName,
            style: AppConstants.getHeadlineFont(color: Colors.white)
                .copyWith(fontSize: 20),
          ),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeaderGradient() {
    return Container(
      height: 280,
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 120, 20, 20),
      child: Column(
        children: [
          FadeInDown(
            child: Text(
              AppConstants.pricingSectionTitle,
              style: AppConstants.getHeadlineFont(color: Colors.white)
                  .copyWith(fontSize: 42),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          FadeInUp(
            delay: AppConstants.shortAnimationDuration,
            child: Text(
              AppConstants.pricingSectionSubtitle,
              style: AppConstants.getBodyFont(
                color: Colors.white.withOpacity(0.9),
              ).copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return FadeInUp(
      delay: Duration(milliseconds: 300),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 30),
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleButton(
              AppConstants.pricingToggleMonthly,
              !_isAnnual,
                  () => setState(() => _isAnnual = false),
            ),
            _buildToggleButton(
              AppConstants.pricingToggleAnnual,
              _isAnnual,
                  () => setState(() => _isAnnual = true),
              showBadge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap,
      {bool showBadge = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              text,
              style: AppConstants.getBodyFont(
                color: isSelected ? Colors.white : Colors.grey[700],
              ).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showBadge)
              Positioned(
                right: -60,
                top: -20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppConstants.pricingSaveText,
                    style: AppConstants.getBodyFont(color: Colors.white)
                        .copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingPlans(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > AppConstants.desktopBreakpoint) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AppConstants.pricingPlans.asMap().entries.map((entry) {
                return Expanded(
                  child: FadeInUp(
                    delay: Duration(milliseconds: 100 * entry.key),
                    child: _buildPricingCard(context, entry.value),
                  ),
                );
              }).toList(),
            );
          } else if (constraints.maxWidth > AppConstants.mobileBreakpoint) {
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: AppConstants.pricingPlans.asMap().entries.map((entry) {
                return Container(
                  width: (constraints.maxWidth - 60) / 2,
                  child: FadeInUp(
                    delay: Duration(milliseconds: 100 * entry.key),
                    child: _buildPricingCard(context, entry.value),
                  ),
                );
              }).toList(),
            );
          } else {
            return Column(
              children: AppConstants.pricingPlans.asMap().entries.map((entry) {
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * entry.key),
                  child: _buildPricingCard(context, entry.value),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context, Map<String, dynamic> plan) {
    final bool isPopular = plan['isPopular'] as bool;
    final Color planColor = plan['color'] as Color;
    final int? priceMonthly = plan['priceMonthly'] as int?;
    final String? badge = plan['badge'] as String?;

    // Calcul dynamique du prix annuel
    int? priceAnnual;
    if (priceMonthly != null) {
      priceAnnual = AppConstants.calculateAnnualPrice(priceMonthly);
    }

    Color cardColor = Colors.white;
    Color textColor = Colors.black87;
    Color buttonColor = planColor;
    Color buttonTextColor = Colors.white;
    Color borderColor = Colors.grey.withOpacity(0.2);

    if (isPopular) {
      cardColor = planColor;
      textColor = Colors.white;
      buttonColor = Colors.white;
      buttonTextColor = planColor;
      borderColor = planColor;
    }

    String displayPrice = 'Sur mesure';
    String displayPeriod = '';
    String? oldPrice;
    int? savings;

    if (priceMonthly != null) {
      if (_isAnnual && priceAnnual != null) {
        displayPrice = _currencyFormatter.format(priceAnnual);
        displayPeriod = '/an';
        oldPrice = _currencyFormatter.format(priceMonthly * 12);
        savings = AppConstants.calculateSavings(priceMonthly);
      } else {
        displayPrice = _currencyFormatter.format(priceMonthly);
        displayPeriod = '/mois';
      }
    }

    return Container(
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isPopular ? 0.15 : 0.05),
            blurRadius: isPopular ? 20 : 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: borderColor, width: isPopular ? 3 : 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (badge != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isPopular
                    ? AppConstants.secondaryColor
                    : (plan['planId'] == 'basic'
                    ? AppConstants.orangeAccent
                    : AppConstants.purpleAccent),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.cardBorderRadius - 3),
                  topRight: Radius.circular(AppConstants.cardBorderRadius - 3),
                ),
              ),
              child: Text(
                badge,
                textAlign: TextAlign.center,
                style: AppConstants.getBodyFont(color: Colors.white).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  plan['name'],
                  style: AppConstants.getHeadlineFont(color: textColor).copyWith(
                    fontSize: 26,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (plan['subtitle'] != '')
                  Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      plan['subtitle'],
                      style: AppConstants.getBodyFont(
                        color: textColor.withOpacity(0.7),
                      ).copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: 10),
                Text(
                  plan['description'],
                  style: AppConstants.getBodyFont(
                    color: textColor.withOpacity(0.8),
                  ).copyWith(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 25),

                // Prix avec effet de barré pour l'ancien prix
                if (_isAnnual && oldPrice != null && priceMonthly != null)
                  Column(
                    children: [
                      Text(
                        '${plan['currency']} $oldPrice/an',
                        style: AppConstants.getBodyFont(
                          color: textColor.withOpacity(0.5),
                        ).copyWith(
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(height: 5),
                    ],
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan['currency'] != '')
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          plan['currency'],
                          style: AppConstants.getBodyFont(color: textColor)
                              .copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        displayPrice,
                        style:
                        AppConstants.getHeadlineFont(color: textColor).copyWith(
                          fontSize: 36,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (displayPeriod != '')
                      Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: Text(
                          displayPeriod,
                          style: AppConstants.getBodyFont(
                            color: textColor.withOpacity(0.7),
                          ).copyWith(fontSize: 16),
                        ),
                      ),
                  ],
                ),

                // Badge économies pour annuel (calculé dynamiquement)
                if (_isAnnual && priceMonthly != null && savings != null)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppConstants.secondaryColor.withOpacity(
                          isPopular ? 0.3 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPopular
                              ? Colors.white.withOpacity(0.5)
                              : AppConstants.secondaryColor,
                        ),
                      ),
                      child: Text(
                        '💰 Économisez ${_currencyFormatter.format(savings)} FCFA',
                        style: AppConstants.getBodyFont(
                          color: isPopular ? Colors.white : AppConstants.secondaryColor,
                        ).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 30),
                Divider(color: textColor.withOpacity(0.2)),
                SizedBox(height: 25),

                ...(plan['features'] as List<String>).map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: isPopular
                            ? Colors.white
                            : AppConstants.secondaryColor,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: AppConstants.getBodyFont(
                            color: textColor.withOpacity(0.9),
                          ).copyWith(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                )),

                SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: buttonTextColor,
                    backgroundColor: buttonColor,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(AppConstants.buttonBorderRadius),
                    ),
                    elevation: isPopular ? 5 : 2,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    final planId = plan['planId'] as String;
                    final billingCycle = _isAnnual ? 'annual' : 'monthly';

                    // Calcul du prix final à passer
                    String finalPrice = displayPrice;
                    int? finalPriceValue;
                    if (priceMonthly != null) {
                      finalPriceValue = _isAnnual ? priceAnnual : priceMonthly;
                    }

                    // Toutes les souscriptions vont vers register avec les paramètres
                    Navigator.pushNamed(
                      context,
                      AppRoutes.register,
                      arguments: {
                        'planId': planId,
                        'billingCycle': billingCycle,
                        'planName': plan['name'],
                        'price': finalPrice,
                        'priceValue': finalPriceValue,
                        'currency': plan['currency'],
                        'savings': savings,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              'Comparez nos offres',
              style: AppConstants.getHeadlineFont().copyWith(fontSize: 36),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 40),
          FadeInUp(
            delay: AppConstants.shortAnimationDuration,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    AppConstants.primaryColor.withOpacity(0.1),
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        'Fonctionnalités',
                        style: AppConstants.getBodyFont().copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...AppConstants.pricingPlans.map((plan) => DataColumn(
                      label: Text(
                        plan['name'],
                        style: AppConstants.getBodyFont().copyWith(
                          fontWeight: FontWeight.bold,
                          color: plan['color'] as Color,
                        ),
                      ),
                    )),
                  ],
                  rows: [
                    _buildComparisonRow('Chambres', ['14', '20', 'Illimité', 'Illimité']),
                    _buildComparisonRow('Employés', ['3', '10', '20', 'Illimité']),
                    _buildComparisonRow('Réservations', ['❌', '✅', '✅', '✅']),
                    _buildComparisonRow('Gestion resto', ['❌', '❌', '✅', '✅']),
                    _buildComparisonRow('Analyses temps réel', ['❌', '❌', '✅', '✅']),
                    _buildComparisonRow('Support', ['Base', 'Standard', '24/7', 'Prioritaire']),
                    _buildComparisonRow('API', ['❌', '❌', '❌', '✅']),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildComparisonRow(String feature, List<String> values) {
    return DataRow(
      cells: [
        DataCell(Text(
          feature,
          style: AppConstants.getBodyFont().copyWith(fontWeight: FontWeight.w600),
        )),
        ...values.map((value) => DataCell(Text(
          value,
          style: AppConstants.getBodyFont(),
        ))),
      ],
    );
  }

  Widget _buildFAQSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      color: Colors.grey[50],
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              AppConstants.faqSectionTitle,
              style: AppConstants.getHeadlineFont().copyWith(fontSize: 36),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 40),
          Container(
            constraints: BoxConstraints(maxWidth: 900),
            child: Column(
              children: AppConstants.pricingFaqs.map((faq) {
                return FadeInUp(
                  child: _buildFAQItem(faq['question']!, faq['answer']!),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          iconColor: AppConstants.primaryColor,
          collapsedIconColor: Colors.grey[600],
          title: Text(
            question,
            style: AppConstants.getBodyFont().copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          children: [
            Text(
              answer,
              style: AppConstants.getBodyFont(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor.withOpacity(0.9),
            AppConstants.secondaryColor.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          FadeInUp(
            child: Text(
              AppConstants.pricingCtaTitle,
              style: AppConstants.getHeadlineFont(color: Colors.white)
                  .copyWith(fontSize: 36),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          FadeInUp(
            delay: AppConstants.shortAnimationDuration,
            child: Container(
              constraints: BoxConstraints(maxWidth: 700),
              child: Text(
                AppConstants.pricingCtaSubtitle,
                style: AppConstants.getBodyFont(
                  color: Colors.white.withOpacity(0.95),
                ).copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 50),
          FadeInUp(
            delay: AppConstants.mediumAnimationDuration,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < AppConstants.mobileBreakpoint) {
                  return Column(
                    children: [
                      _buildCtaButton(
                        context,
                        'Démarrer gratuitement',
                        Icons.rocket_launch,
                        true,
                            () => Navigator.pushNamed(
                          context,
                          AppRoutes.register,
                          arguments: {
                            'planId': 'basic',
                            'billingCycle': 'monthly',
                          },
                        ),
                      ),
                      SizedBox(height: 15),
                      _buildCtaButton(
                        context,
                        'Contacter un expert',
                        Icons.support_agent,
                        false,
                            () => Navigator.pushNamed(context, AppRoutes.contactpage),
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCtaButton(
                      context,
                      'Démarrer gratuitement',
                      Icons.rocket_launch,
                      true,
                          () => Navigator.pushNamed(
                        context,
                        AppRoutes.register,
                        arguments: {
                          'planId': 'basic',
                          'billingCycle': 'monthly',
                        },
                      ),
                    ),
                    SizedBox(width: 20),
                    _buildCtaButton(
                      context,
                      'Contacter un expert',
                      Icons.support_agent,
                      false,
                          () => Navigator.pushNamed(context, AppRoutes.contactpage),
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

  Widget _buildCtaButton(
      BuildContext context,
      String text,
      IconData icon,
      bool isPrimary,
      VoidCallback onPressed,
      ) {
    if (isPrimary) {
      return ElevatedButton.icon(
        icon: Icon(icon),
        style: ElevatedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 35, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
          elevation: 8,
        ),
        onPressed: onPressed,
        label: Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return OutlinedButton.icon(
        icon: Icon(icon),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white, width: 2),
          padding: EdgeInsets.symmetric(horizontal: 35, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
        ),
        onPressed: onPressed,
        label: Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      color: AppConstants.darkColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppConstants.logoPath,
                height: 40,
              ),
              SizedBox(width: 10),
              Text(
                AppConstants.appName,
                style: AppConstants.getHeadlineFont(color: Colors.white)
                    .copyWith(fontSize: 24),
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            AppConstants.appDescription,
            style: AppConstants.getBodyFont(color: Colors.white70)
                .copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 25),
          Text(
            AppConstants.copyrightText,
            style: AppConstants.getBodyFont(color: Colors.white60)
                .copyWith(fontSize: 14),
          ),
          SizedBox(height: 25),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: AppConstants.footerSections['Légal']!.map((item) {
              return TextButton(
                onPressed: () {
                  if (item['route'] != null) {
                    Navigator.pushNamed(context, item['route']!);
                  }
                },
                child: Text(
                  item['label']!,
                  style: AppConstants.getBodyFont(color: Colors.white70),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
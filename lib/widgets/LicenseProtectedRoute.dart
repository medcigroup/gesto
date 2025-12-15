import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../LicenseFeatures.dart';
import '../../../config/routes.dart';
import '../services/LicenseStreamService.dart';

class LicenseProtectedRoute extends StatefulWidget {
  final Widget child;
  final bool isEmployeeRoute;
  final String? pageTitle;
  final bool bypassLicenseCheck;

  const LicenseProtectedRoute({
    Key? key,
    required this.child,
    this.isEmployeeRoute = false,
    this.pageTitle,
    this.bypassLicenseCheck = false,
  }) : super(key: key);

  @override
  _LicenseProtectedRouteState createState() => _LicenseProtectedRouteState();
}

class _LicenseProtectedRouteState extends State<LicenseProtectedRoute> {
  final LicenseStreamService _licenseService = LicenseStreamService();
  bool _hasShownError = false;
  bool _isRedirecting = false;
  Stream<LicenseStatus>? _licenseStream; // Cache du stream

  // ⚠️ SEULEMENT Licences et Paramètres sont exemptés
  // Le Dashboard n'est PAS exempté - il doit rediriger si la licence expire
  static const List<String> _alwaysAccessiblePages = [
    'Licences',
    'Paramètres',
  ];

  @override
  void initState() {
    super.initState();
    _initializeLicenseStream();
  }

  @override
  void dispose() {
    _licenseService.dispose();
    super.dispose();
  }

  // Initialiser le stream une seule fois - TOUJOURS, même pour les pages exemptées
  void _initializeLicenseStream() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final stream = await _licenseService.getLicenseStream(user.uid);
        if (mounted) {
          setState(() {
            _licenseStream = stream;
          });
          print('[LICENSE WIDGET] 🔄 Stream de licence initialisé');
        }
      } catch (e) {
        print('[LICENSE WIDGET] ❌ Erreur initialisation stream: $e');
      }
    }
  }

  bool _isPageAlwaysAccessible() {
    if (widget.bypassLicenseCheck) {
      return true;
    }

    if (widget.pageTitle != null && _alwaysAccessiblePages.contains(widget.pageTitle)) {
      return true;
    }

    return false;
  }

  void _handleLicenseExpired(LicenseStatus status) async {
    // Empêcher les appels multiples
    if (_isRedirecting) {
      print('[LICENSE WIDGET] ⏸️ Redirection déjà en cours, ignoré');
      return;
    }

    print('[LICENSE WIDGET] 🚨 Gestion de l\'expiration de licence');

    if (!mounted) {
      print('[LICENSE WIDGET] ⚠️ Widget non monté, abandon');
      return;
    }

    setState(() {
      _isRedirecting = true;
    });

    try {
      if (widget.isEmployeeRoute) {
        // Pour les employés : déconnecter
        print('[LICENSE WIDGET] 👤 Employé détecté, déconnexion...');
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "La licence de votre administrateur a expiré. "
                    "Veuillez contacter votre administrateur pour renouveler la licence.",
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 7),
            ),
          );

          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
                (route) => false,
          );
        }
      } else {
        // Pour les propriétaires : rediriger vers renouvellement
        print('[LICENSE WIDGET] 🏢 Propriétaire détecté, redirection vers renouvellement...');

        String expiryMessage = status.expiryDate != null
            ? "Votre licence a expiré le ${status.expiryDate!.day}/${status.expiryDate!.month}/${status.expiryDate!.year}."
            : "Votre licence a expiré.";

        if (mounted) {
          // Afficher le dialogue
          final shouldRedirect = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return WillPopScope(
                onWillPop: () async => false, // Empêcher de fermer le dialogue
                child: AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Licence Expirée',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expiryMessage,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Renouvelez votre licence pour continuer à utiliser Gesto.',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text('Renouveler Maintenant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(true); // Retourner true
                      },
                    ),
                  ],
                ),
              );
            },
          );

          // Rediriger après fermeture du dialogue
          if (mounted && (shouldRedirect ?? true)) {
            print('[LICENSE WIDGET] ➡️ Redirection vers renewlicencePage');
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.renewlicencePage,
                  (route) => false,
            );
          }
        }
      }
    } catch (e) {
      print('[LICENSE WIDGET] ❌ Erreur lors de la gestion d\'expiration: $e');
    } finally {
      // ⚠️ TOUJOURS RÉINITIALISER LE FLAG
      if (mounted) {
        setState(() {
          _isRedirecting = false;
        });
      }
    }
  }

  void _updateLicenseManager(LicenseStatus status) {
    if (status.licenseType != null) {
      try {
        final licenseManager = Provider.of<LicenseManager>(context, listen: false);
        licenseManager.updateLicenseType(status.licenseType!, status.expiryDate);
        print('[LICENSE WIDGET] 📊 LicenseManager mis à jour: ${status.licenseType}');
      } catch (e) {
        print('[LICENSE WIDGET] ⚠️ Erreur mise à jour LicenseManager: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
                (route) => false,
          );
        }
      });
      return _buildLoadingScreen();
    }

    // Attendre que le stream soit initialisé
    if (_licenseStream == null) {
      return _buildLoadingScreen();
    }

    return StreamBuilder<LicenseStatus>(
      stream: _licenseStream,
      builder: (context, licenseSnapshot) {
        if (licenseSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (licenseSnapshot.hasError) {
          print('[LICENSE WIDGET] ❌ Erreur licence: ${licenseSnapshot.error}');
          return _buildErrorScreen('Erreur lors de la vérification de la licence');
        }

        final licenseStatus = licenseSnapshot.data;

        if (licenseStatus == null) {
          return _buildLoadingScreen();
        }

        print('[LICENSE WIDGET] 📋 Status: valid=${licenseStatus.isValid}, expired=${licenseStatus.isExpired}, page=${widget.pageTitle}');

        // ⚠️ TOUJOURS mettre à jour le LicenseManager, même pour les pages exemptées
        _updateLicenseManager(licenseStatus);

        // Si c'est une page exemptée (Licences, Paramètres), afficher directement sans redirection
        if (_isPageAlwaysAccessible()) {
          print('[LICENSE WIDGET] ✅ Page exemptée, affichage direct: ${widget.pageTitle}');
          return widget.child;
        }

        // Pour les pages NON exemptées (y compris Dashboard), vérifier si la licence est expirée
        if (!licenseStatus.isValid || licenseStatus.isExpired) {
          print('[LICENSE WIDGET] ❌ Licence invalide ou expirée - déclenchement redirection');

          // Utiliser addPostFrameCallback pour exécuter après le build
          if (!_isRedirecting) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isRedirecting) {
                _handleLicenseExpired(licenseStatus);
              }
            });
          }

          // Afficher un écran d'attente pendant la redirection
          return _buildExpirationScreen();
        }

        // Vérifier les permissions de page
        if (widget.pageTitle != null && !licenseStatus.canAccessPage(widget.pageTitle!)) {
          print('[LICENSE WIDGET] 🚫 Accès refusé à: ${widget.pageTitle}');

          if (!_isRedirecting) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isRedirecting) {
                setState(() {
                  _isRedirecting = true;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "Vous n'avez pas accès à cette fonctionnalité avec votre licence ${licenseStatus.licenseType?.toString().split('.').last ?? 'actuelle'}."
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 5),
                  ),
                );

                Navigator.of(context).pushReplacementNamed(
                    widget.isEmployeeRoute ? AppRoutes.employeeDashboard : AppRoutes.dashboard
                ).then((_) {
                  if (mounted) {
                    setState(() {
                      _isRedirecting = false;
                    });
                  }
                });
              }
            });
          }

          return _buildLoadingScreen();
        }

        // Tout est OK
        print('[LICENSE WIDGET] ✅ Accès autorisé');
        return widget.child;
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Vérification de votre licence...'),
          ],
        ),
      ),
    );
  }

  Widget _buildExpirationScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Licence Expirée',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text('Redirection en cours...'),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                      (route) => false,
                );
              },
              child: Text('Retour à la connexion'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widgets helpers
class PremiumFeatureBadge extends StatelessWidget {
  final String featureName;
  final Widget child;

  const PremiumFeatureBadge({
    Key? key,
    required this.featureName,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final licenseManager = Provider.of<LicenseManager>(context);
    final isPremium = licenseManager.isFeaturePremium(featureName);

    if (!isPremium) {
      return child;
    }

    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: child,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class UpgradeButton extends StatelessWidget {
  final String featureName;

  const UpgradeButton({
    Key? key,
    required this.featureName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final licenseManager = Provider.of<LicenseManager>(context);
    final requiredLicense = licenseManager.getRequiredLicenseNameForFeature(featureName);

    return ElevatedButton.icon(
      icon: Icon(Icons.upgrade),
      label: Text('Passer à $requiredLicense pour débloquer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        Navigator.of(context).pushNamed(AppRoutes.renewlicencePage);
      },
    );
  }
}
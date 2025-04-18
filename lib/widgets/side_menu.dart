import 'package:flutter/material.dart';
import '../config/AuthService.dart';
import '../config/UserModel.dart';
import '../config/localStorage.dart';
import '../config/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  _SideMenuState createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  UserModel? _userModel;
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _licenseExpired = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    UserModel? userModel = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _userModel = userModel;
        _isLoading = false;
        _checkLicenseExpiration();
      });
    }
  }

  Future<void> _checkLicenseExpiration() async {
    if (_userModel != null && _userModel!.licenceExpiryDate != null) {
      DateTime expiryDate = _userModel!.licenceExpiryDate!.toDate();
      if (DateTime.now().isAfter(expiryDate)) {
        setState(() {
          _licenseExpired = true;
        });
        _showLicenseExpiredDialog();
      }
    }
  }

  void _showLicenseExpiredDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Licence expirée'),
            content: const Text('Votre licence a expiré. Veuillez renouveler votre licence pour continuer à utiliser l\'application.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Renouveler la licence'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, AppRoutes.renewlicencePage);
                },
              ),
            ],
          );
        },
      );
    });
  }

  // Fonction pour vérifier si l'utilisateur est un administrateur
  bool _isAdmin() {
    return _userModel?.userRole == 'admin' || _userModel?.userRole == 'superAdmin';
  }


  bool _shouldDisplayMenuItem(String routeName) {
    // Récupérer le plan de l'utilisateur
    String userPlan = _userModel?.plan ?? 'basic';

    // Si l'utilisateur a un plan premium, afficher tous les éléments
    if (userPlan == 'pro') {
      return true;
    }
    // Si l'utilisateur a un plan starter, afficher les statistiques et les éléments de base
    else if (userPlan == 'starter') {
      if (routeName == AppRoutes.restaurant ||
          routeName == AppRoutes.clients ||
          routeName == AppRoutes.statistiques ) {
        return false; // Masquer les éléments premium uniquement
      }
      return true; // Afficher les statistiques et les éléments de base
    }
    // Si l'utilisateur a un plan basic, masquer les fonctionnalités payantes
    else {
      if (routeName == AppRoutes.restaurant ||
          routeName == AppRoutes.clients ||
          routeName == AppRoutes.employees ||
          routeName == AppRoutes.statistiques ||
          routeName == AppRoutes.services) {
        return false; // Masquer tous les éléments premium et statistiques
      }
      return true; // Afficher uniquement les éléments de base
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPremium = _userModel?.plan != 'basic';
    final bool isBasic = _userModel?.plan == 'basic';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(height: 8),
                Text(
                  _userModel?.fullName ?? 'Nom d\'utilisateur',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  _userModel?.email ?? 'email@example.com',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Row(
                  children: [
                    if (isBasic)
                      Expanded( // Utiliser Expanded pour qu'ils prennent la même largeur
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, right: 4), // Ajouter une marge à droite
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Licence Basic',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    if (isPremium)
                      Expanded( // Utiliser Expanded pour qu'ils prennent la même largeur
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, right: 4), // Ajouter une marge à droite
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Licence Premium',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    if (_isAdmin())
                      Expanded( // Utiliser Expanded pour qu'ils prennent la même largeur
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, left: 4), // Ajouter une marge à gauche
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Administrateur',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Tableau de bord
          _buildMenuItem(Icons.home, 'Tableau de bord', AppRoutes.dashboard, enabled: !_licenseExpired),

          // Réservation
          _buildMenuItem(Icons.book_online, 'Réservation', AppRoutes.reservationPage, enabled: !_licenseExpired),

          // Enregistrement
          _buildMenuItem(Icons.book_rounded, 'Enregistrement', AppRoutes.enregistrement, enabled: !_licenseExpired),
          // Enregistrement passage
          _buildMenuItem(Icons.bed, 'Passage', AppRoutes.hourlyCheckInPage, enabled: !_licenseExpired),

          // Départ
          _buildMenuItem(Icons.library_add_check_outlined, 'Départ', AppRoutes.occupiedrooms, enabled: !_licenseExpired),

          // Chambres
          _buildMenuItem(Icons.checkroom_outlined, 'Chambres', AppRoutes.roomsPage, enabled: !_licenseExpired),
          // Chambres
          _buildMenuItem(Icons.add_card_sharp, 'Paiement', AppRoutes.paiement, enabled: !_licenseExpired),

          // Restaurant (affiché uniquement si payant)
          if (_shouldDisplayMenuItem(AppRoutes.restaurant))
            _buildMenuItem(
              Icons.restaurant,
              'Restaurant',
              AppRoutes.comingSoonPage,
              enabled: !_licenseExpired,
              isPremium: isPremium,
            ),

          // Clients (affiché uniquement si payant)
          if (_shouldDisplayMenuItem(AppRoutes.clients))
            _buildMenuItem(
              Icons.person,
              'Clients',
              AppRoutes.comingSoonPage,
              enabled: !_licenseExpired,
              isPremium: isPremium,
            ),

          // Personnel
          if (_shouldDisplayMenuItem(AppRoutes.employees))
          _buildMenuItem(Icons.perm_contact_calendar_outlined, 'Personnel', AppRoutes.employees, enabled: !_licenseExpired,isPremium: isPremium,),
          if (_shouldDisplayMenuItem(AppRoutes.employees))
            _buildMenuItem(Icons.home_repair_service, 'Services', AppRoutes.services, enabled: !_licenseExpired,isPremium: isPremium,),

          // Finances
          _buildMenuItem(Icons.monetization_on_sharp, 'Finances', AppRoutes.finance, enabled: !_licenseExpired),

          // Statistiques (affiché uniquement si payant)
          if (_shouldDisplayMenuItem(AppRoutes.statistiques))
            _buildMenuItem(
              Icons.analytics_outlined,
              'Statistiques',
              AppRoutes.comingSoonPage,
              enabled: !_licenseExpired,
              isPremium: isPremium,
            ),

          // Gestion de la licence
          _buildMenuItem(Icons.data_saver_on, 'Gestion de la licence', AppRoutes.renewlicencePage, enabled: !_licenseExpired),

          // Paramètres
          _buildMenuItem(Icons.settings, 'Paramètres', AppRoutes.settingspage, enabled: !_licenseExpired),

          // Administration (affiché uniquement si Admin)
          if (_isAdmin())
            _buildMenuItem(
              Icons.admin_panel_settings,
              'Administration',
              AppRoutes.administration,
              enabled: !_licenseExpired,
            ),

          // Déconnexion
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 20,
              ),
              title: const Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () async {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmation'),
                    content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Déconnecter'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseAuth.instance.signOut();
                  LocalStorage.remove('userData');
                  LocalStorage.remove('userDataTimestamp');
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
                }
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String routeName, {bool enabled = true, bool isPremium = false}) {
    return ListTile(
      leading: Icon(icon, color: enabled ? null : Colors.grey),
      title: Row(
        children: [
          Text(title, style: TextStyle(color: enabled ? null : Colors.grey)),
          if (isPremium && _shouldDisplayMenuItem(routeName))
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Premium',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
      onTap: enabled ? () {
        Navigator.pop(context);
        Navigator.pushNamed(context, routeName);
      } : null,
    );
  }
}
import 'package:flutter/material.dart';
import '../config/AuthService.dart';
import '../config/UserModel.dart';
import '../config/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importez Cloud Firestore

class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  _SideMenuState createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  UserModel? _userModel;
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _licenseExpired = false; // Ajout d'un booléen pour l'expiration de la licence

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
        _checkLicenseExpiration(); // Vérifier l'expiration de la licence après le chargement des données
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
        _showLicenseExpiredDialog(); // Afficher le dialogue d'expiration de la licence
      }
    }
  }

  void _showLicenseExpiredDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false, // Empêche la fermeture en touchant à l'extérieur
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

  @override
  Widget build(BuildContext context) {
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
              ],
            ),
          ),
          _buildMenuItem(Icons.home, 'Tableau de bord', AppRoutes.dashboard, enabled: !_licenseExpired),
          _buildMenuItem(Icons.book_online, 'Réservation', AppRoutes.reservationPage, enabled: !_licenseExpired),
          _buildMenuItem(Icons.book_rounded, 'Enregistrement', AppRoutes.enregistrement, enabled: !_licenseExpired),
          _buildMenuItem(Icons.library_add_check_outlined, 'Départ', AppRoutes.checkoutPage, enabled: !_licenseExpired),
          _buildMenuItem(Icons.checkroom_outlined, 'Chambres', AppRoutes.roomsPage, enabled: !_licenseExpired),
          _buildMenuItem(Icons.restaurant, 'Restaurant', AppRoutes.restaurant, enabled: !_licenseExpired),
          _buildMenuItem(Icons.person, 'Clients', AppRoutes.clients, enabled: !_licenseExpired),
          _buildMenuItem(Icons.perm_contact_calendar_outlined, 'Personnel', AppRoutes.employees, enabled: !_licenseExpired),
          _buildMenuItem(Icons.monetization_on_sharp, 'Finances', AppRoutes.finance, enabled: !_licenseExpired),
          _buildMenuItem(Icons.analytics_outlined, 'Statistiques', AppRoutes.statistiques, enabled: !_licenseExpired),
          _buildMenuItem(Icons.data_saver_on, 'Gestion de la licence', AppRoutes.renewlicencePage, enabled: !_licenseExpired),
          _buildMenuItem(Icons.settings, 'Paramètres', AppRoutes.settings, enabled: !_licenseExpired),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // ... (votre code de déconnexion)
            },
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String routeName, {bool enabled = true}) {
    return ListTile(
      leading: Icon(icon, color: enabled ? null : Colors.grey),
      title: Text(title, style: TextStyle(color: enabled ? null : Colors.grey)),
      onTap: enabled ? () {
        Navigator.pop(context);
        Navigator.pushNamed(context, routeName);
      } : null,
    );
  }
}

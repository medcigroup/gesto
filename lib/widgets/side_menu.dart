import 'package:flutter/material.dart';
import '../config/AuthService.dart';
import '../config/UserModel.dart';
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
      });
    }
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
          _buildMenuItem(Icons.home, 'Tableau de bord', AppRoutes.dashboard),
          _buildMenuItem(Icons.book_online, 'Réservation', AppRoutes.reservationPage),
          _buildMenuItem(Icons.checkroom_outlined, 'Chambres', AppRoutes.roomsPage),
          _buildMenuItem(Icons.restaurant, 'Restaurant', AppRoutes.restaurant),
          _buildMenuItem(Icons.person, 'Clients', AppRoutes.clients),
          _buildMenuItem(Icons.perm_contact_calendar_outlined, 'Personnel', AppRoutes.employees),
          _buildMenuItem(Icons.monetization_on_sharp, 'Finances', AppRoutes.finance),
          _buildMenuItem(Icons.analytics_outlined, 'Statistiques', AppRoutes.statistiques),
          _buildMenuItem(Icons.settings, 'Paramètres', AppRoutes.settings),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // Afficher une boîte de dialogue de confirmation
              bool confirmLogout = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmation'),
                  content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);  // Annuler la déconnexion
                      },
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);  // Confirmer la déconnexion
                      },
                      child: const Text('Déconnecter', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              // Si l'utilisateur confirme la déconnexion
              if (confirmLogout == true) {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
              }
            },
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String routeName) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Ferme le Drawer
        Navigator.pushNamed(context, routeName);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/HotelSettingsService.dart';
import '../../config/AuthService.dart';

class HotelProfileDrawer extends StatefulWidget {
  final VoidCallback? onNavigateToSettings;
  
  const HotelProfileDrawer({Key? key, this.onNavigateToSettings}) : super(key: key);

  @override
  State<HotelProfileDrawer> createState() => _HotelProfileDrawerState();
}

class _HotelProfileDrawerState extends State<HotelProfileDrawer> {
  final HotelSettingsService _hotelSettingsService = HotelSettingsService();
  Map<String, dynamic>? _hotelData;
  bool _isLoading = true;
  String? _userEmail;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadHotelData();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email;
        });

        // Récupérer le rôle de l'utilisateur
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userRole = userDoc.data()?['userRole'] ?? 'Employé';
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  Future<void> _loadHotelData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final data = await _hotelSettingsService.getHotelSettings();

      setState(() {
        _hotelData = data;
        _isLoading = false;
      });

      print('✅ Données hôtel chargées: $data');
    } catch (e) {
      print('❌ Erreur lors du chargement des données hôtel: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Container(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête avec photo de profil
                      _buildHeader(isDark),

                      const Divider(height: 1),

                      // Informations de l'hôtel
                      _buildSection(
                        title: 'Informations de l\'hôtel',
                        isDark: isDark,
                        children: [
                          _buildInfoTile(
                            icon: Icons.hotel_rounded,
                            label: 'Nom',
                            value: _hotelData?['hotelName'] ?? 'Non défini',
                            isDark: isDark,
                          ),
                          _buildInfoTile(
                            icon: Icons.location_on_rounded,
                            label: 'Adresse',
                            value: _hotelData?['address'] ?? 'Non défini',
                            isDark: isDark,
                          ),
                          _buildInfoTile(
                            icon: Icons.phone_rounded,
                            label: 'Téléphone',
                            value: _hotelData?['phoneNumber'] ?? 'Non défini',
                            isDark: isDark,
                          ),
                          _buildInfoTile(
                            icon: Icons.email_rounded,
                            label: 'Email',
                            value: _hotelData?['email'] ?? 'Non défini',
                            isDark: isDark,
                          ),
                        ],
                      ),

                      const Divider(height: 1),

                      // Paramètres opérationnels
                      _buildSection(
                        title: 'Paramètres opérationnels',
                        isDark: isDark,
                        children: [
                          _buildInfoTile(
                            icon: Icons.login_rounded,
                            label: 'Check-in',
                            value: _hotelData?['checkInTime'] ?? '12:00',
                            isDark: isDark,
                          ),
                          _buildInfoTile(
                            icon: Icons.logout_rounded,
                            label: 'Check-out',
                            value: _hotelData?['checkOutTime'] ?? '10:00',
                            isDark: isDark,
                          ),
                          _buildInfoTile(
                            icon: Icons.attach_money_rounded,
                            label: 'Devise',
                            value: _hotelData?['currency'] ?? 'USD',
                            isDark: isDark,
                          ),
                          _buildInfoTile(
                            icon: Icons.percent_rounded,
                            label: 'Acompte',
                            value: '${_hotelData?['depositPercentage'] ?? 0}%',
                            isDark: isDark,
                          ),
                        ],
                      ),

                      const Divider(height: 1),

                      // Informations restaurant (si disponibles)
                      if (_hotelData?['restaurantName'] != null)
                        _buildSection(
                          title: 'Restaurant',
                          isDark: isDark,
                          children: [
                            _buildInfoTile(
                              icon: Icons.restaurant_rounded,
                              label: 'Nom',
                              value: _hotelData?['restaurantName'] ?? 'Non défini',
                              isDark: isDark,
                            ),
                            if (_hotelData?['restaurantAddress'] != null)
                              _buildInfoTile(
                                icon: Icons.location_on_rounded,
                                label: 'Adresse',
                                value: _hotelData?['restaurantAddress'] ?? '',
                                isDark: isDark,
                              ),
                            if (_hotelData?['restaurantPhone'] != null)
                              _buildInfoTile(
                                icon: Icons.phone_rounded,
                                label: 'Téléphone',
                                value: _hotelData?['restaurantPhone'] ?? '',
                                isDark: isDark,
                              ),
                          ],
                        ),

                      const Divider(height: 1),

                      // Types de chambres
                      if (_hotelData?['roomTypes'] != null &&
                          (_hotelData!['roomTypes'] as List).isNotEmpty)
                        _buildSection(
                          title: 'Types de chambres',
                          isDark: isDark,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (_hotelData!['roomTypes'] as List)
                                    .map((type) => Chip(
                                          label: Text(type.toString()),
                                          backgroundColor: isDark
                                              ? Colors.grey[800]
                                              : Colors.grey[200],
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Statistiques rapides
                      _buildQuickStats(isDark),

                      const SizedBox(height: 16),

                      // Boutons d'action
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Navigation vers la page de paramètres
                                  widget.onNavigateToSettings?.call();
                                },
                                icon: const Icon(Icons.settings_rounded),
                                label: const Text('Modifier les paramètres'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _loadHotelData();
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Actualiser'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.hotel_rounded,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _hotelData?['hotelName'] ?? 'Mon Hôtel',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _userRole ?? 'Utilisateur',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_userEmail != null) ...[
            const SizedBox(height: 4),
            Text(
              _userEmail!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isDark) {
    return FutureBuilder<Map<String, int>>(
      future: _getHotelStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistiques rapides',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.hotel_rounded,
                      label: 'Chambres',
                      value: stats['rooms']?.toString() ?? '0',
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.people_rounded,
                      label: 'Personnel',
                      value: stats['staff']?.toString() ?? '0',
                      color: Colors.green,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.event_note_rounded,
                      label: 'Réservations',
                      value: stats['bookings']?.toString() ?? '0',
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Occupées',
                      value: stats['occupied']?.toString() ?? '0',
                      color: Colors.purple,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getHotelStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {};

      // Récupérer l'ID approprié (admin ou userId)
      String userId = user.uid;
      final staffDoc = await FirebaseFirestore.instance
          .collection('staff')
          .doc(user.uid)
          .get();

      if (staffDoc.exists) {
        userId = staffDoc.data()?['idadmin'] ?? user.uid;
      }

      // Compter les chambres
      final roomsSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('userId', isEqualTo: userId)
          .get();

      // Compter le personnel
      final staffSnapshot = await FirebaseFirestore.instance
          .collection('staff')
          .where('idadmin', isEqualTo: userId)
          .get();

      // Compter les réservations actives
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['confirmé', 'enregistré'])
          .get();

      // Compter les chambres occupées
      final occupiedSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'enregistré')
          .get();

      return {
        'rooms': roomsSnapshot.docs.length,
        'staff': staffSnapshot.docs.length,
        'bookings': bookingsSnapshot.docs.length,
        'occupied': occupiedSnapshot.docs.length,
      };
    } catch (e) {
      print('❌ Erreur lors du chargement des stats: $e');
      return {};
    }
  }
}

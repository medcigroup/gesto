import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../config/routes.dart';
import '../../config/printReservationReceipt.dart';
import 'ModernClientBookingPage.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({Key? key}) : super(key: key);

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _clientData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClientData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('clients')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _clientData = doc.data();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement données client: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        title: const Text('Espace Client', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Mes Réservations'),
            Tab(icon: Icon(Icons.person), text: 'Mon Profil'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyBookingsTab(),
                _buildProfileTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ModernClientBookingPage()),
          );
        },
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nouvelle réservation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Onglet Mes Réservations
  Widget _buildMyBookingsTab() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('clientId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final reservations = snapshot.data?.docs ?? [];

        // Trier les réservations en mémoire par date de création (plus récent en premier)
        reservations.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aCreated = aData['createdAt'] as Timestamp?;
          final bCreated = bData['createdAt'] as Timestamp?;

          if (aCreated == null || bCreated == null) return 0;
          return bCreated.compareTo(aCreated); // Plus récent en premier
        });

        if (reservations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Aucune réservation',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos réservations apparaîtront ici',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModernClientBookingPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une réservation'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final reservation = reservations[index].data() as Map<String, dynamic>;
            return _buildBookingCard(reservation);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final checkIn = (booking['checkInDate'] as Timestamp).toDate();
    final checkOut = (booking['checkOutDate'] as Timestamp).toDate();
    final status = booking['status'] as String;
    final totalPrice = booking['totalPrice'] as num;
    final reservationCode = booking['reservationCode'] as String? ?? 'N/A';
    final roomNumber = booking['roomNumber'] as String? ?? 'N/A';
    final roomType = booking['roomType'] as String? ?? 'Standard';
    final numberOfGuests = booking['numberOfGuests'] as int? ?? 1;
    final pricePerNight = booking['pricePerNight'] as num? ?? 0;
    final depositAmount = booking['depositAmount'] as num? ?? 0;
    final balanceDue = booking['balanceDue'] as num? ?? totalPrice;
    final specialRequests = booking['specialRequests'] as String? ?? '';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'enregistré':
      case 'registered':
      case 'checked-in':
        statusColor = Colors.blue;
        statusText = 'Enregistré';
        statusIcon = Icons.hotel;
        break;
      case 'confirmée':
      case 'confirmed':
      case 'réservée':
        statusColor = Colors.green;
        statusText = 'Confirmée';
        statusIcon = Icons.check_circle;
        break;
      case 'annulée':
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Annulée';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'En attente';
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chambre $roomNumber',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roomType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Code de réservation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.confirmation_number, size: 16, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Code: $reservationCode',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Message informatif pour le statut Enregistré
            if (status.toLowerCase() == 'enregistré' || status.toLowerCase() == 'registered' || status.toLowerCase() == 'checked-in')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous êtes déjà enregistré à l\'hôtel. Bon séjour !',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (status.toLowerCase() == 'enregistré' || status.toLowerCase() == 'registered' || status.toLowerCase() == 'checked-in')
              const SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Arrivée: ${DateFormat('dd/MM/yyyy').format(checkIn)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Départ: ${DateFormat('dd/MM/yyyy').format(checkOut)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Nuits et personnes
            Row(
              children: [
                Icon(Icons.nights_stay, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${booking['numberOfNights']} nuit(s)',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '$numberOfGuests personne(s)',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),

            // Demandes spéciales
            if (specialRequests.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: $specialRequests',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 24),

            // Détails du prix
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Prix par nuit',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    Text(
                      '${pricePerNight.toStringAsFixed(0)} FCFA',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    ),
                  ],
                ),
                if (depositAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Acompte versé',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      Text(
                        '${depositAmount.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Solde restant',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      Text(
                        '${balanceDue.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      Text(
                        '${totalPrice.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Boutons d'action
            if (status.toLowerCase() != 'annulée' && status.toLowerCase() != 'cancelled') ...[
              const SizedBox(height: 12),
              // Afficher les boutons selon le statut
              if (status.toLowerCase() == 'en attente' || status.toLowerCase() == 'pending')
                // Pour les réservations en attente : Seulement Annuler
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelBooking(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Annuler la réservation'),
                  ),
                )
              else
                // Pour les réservations confirmées ou enregistrées : Seulement Imprimer
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _printReservationReceipt(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A237E),
                      side: const BorderSide(color: Color(0xFF1A237E)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Imprimer le reçu'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _printReservationReceipt(Map<String, dynamic> booking) async {
    try {
      // Charger les paramètres de l'hôtel
      final hotelUserId = booking['userId'];
      
      if (hotelUserId == null) {
        throw Exception('Information de l\'hôtel manquante');
      }

      final hotelDoc = await FirebaseFirestore.instance
          .collection('hotels')
          .where('userId', isEqualTo: hotelUserId)
          .limit(1)
          .get();

      Map<String, dynamic> hotelSettings = {
        'hotelName': booking['hotelName'] ?? 'Hôtel',
        'address': '',
        'phoneNumber': '',
        'email': '',
        'currency': 'FCFA',
      };

      if (hotelDoc.docs.isNotEmpty) {
        final hotelData = hotelDoc.docs.first.data();
        hotelSettings = {
          'hotelName': hotelData['name'] ?? hotelData['hotelName'] ?? 'Hôtel',
          'address': hotelData['address'] ?? '',
          'phoneNumber': hotelData['phone'] ?? hotelData['phoneNumber'] ?? '',
          'email': hotelData['email'] ?? '',
          'currency': hotelData['currency'] ?? 'FCFA',
        };
      }

      // Préparer les données de réservation avec les dates converties
      final reservationData = Map<String, dynamic>.from(booking);
      
      // Convertir les Timestamps en DateTime si nécessaire
      if (booking['checkInDate'] is Timestamp) {
        reservationData['checkInDate'] = (booking['checkInDate'] as Timestamp).toDate();
      }
      if (booking['checkOutDate'] is Timestamp) {
        reservationData['checkOutDate'] = (booking['checkOutDate'] as Timestamp).toDate();
      }

      final printerService = PrinterService();
      await printerService.printReservationReceipt(
        reservationData: reservationData,
        reservationCode: booking['reservationCode'] ?? '',
        hotelSettings: hotelSettings,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reçu généré avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Erreur impression reçu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'impression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    // Afficher une confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm == true && booking['reservationCode'] != null) {
      try {
        // Rechercher la réservation par code
        final reservationsSnapshot = await FirebaseFirestore.instance
            .collection('reservations')
            .where('reservationCode', isEqualTo: booking['reservationCode'])
            .limit(1)
            .get();

        if (reservationsSnapshot.docs.isNotEmpty) {
          await reservationsSnapshot.docs.first.reference.update({
            'status': 'Annulée',
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Réservation annulée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Onglet Profil
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                    ),
                  ),
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _clientData?['fullName'] ?? 'Client',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _clientData?['email'] ?? '',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(Icons.person, 'Nom complet', _clientData?['fullName'] ?? 'N/A'),
          _buildInfoCard(Icons.email, 'Email', _clientData?['email'] ?? 'N/A'),
          _buildInfoCard(Icons.phone, 'Téléphone', _clientData?['phone'] ?? 'N/A'),
          _buildInfoCard(Icons.calendar_today, 'Membre depuis',
            _clientData?['createdAt'] != null
              ? DateFormat('dd/MM/yyyy').format((_clientData!['createdAt'] as Timestamp).toDate())
              : 'N/A'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Modifier le profil
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modification du profil - En développement')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A237E),
                side: const BorderSide(color: Color(0xFF1A237E)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Modifier mon profil'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1A237E), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

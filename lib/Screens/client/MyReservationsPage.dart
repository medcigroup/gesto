import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../config/printReservationReceipt.dart';

class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({Key? key}) : super(key: key);

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  final _user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reservations = [];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    if (_user == null) return;

    setState(() => _isLoading = true);

    try {
      // Charger toutes les réservations du client
      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('clientId', isEqualTo: _user!.uid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _reservations = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
            'checkInDate': (data['checkInDate'] as Timestamp?)?.toDate(),
            'checkOutDate': (data['checkOutDate'] as Timestamp?)?.toDate(),
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement réservations: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printReservationReceipt(Map<String, dynamic> reservation) async {
    try {
      // Charger les paramètres de l'hôtel
      final hotelUserId = reservation['userId'];
      final hotelDoc = await FirebaseFirestore.instance
          .collection('hotels')
          .where('userId', isEqualTo: hotelUserId)
          .limit(1)
          .get();

      Map<String, dynamic> hotelSettings = {
        'hotelName': reservation['hotelName'] ?? 'Hôtel',
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

      final printerService = PrinterService();
      await printerService.printReservationReceipt(
        reservationData: reservation,
        reservationCode: reservation['reservationCode'] ?? '',
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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmée':
      case 'enregistré':
        return Colors.green;
      case 'en attente':
        return Colors.orange;
      case 'annulée':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmée':
        return Icons.check_circle;
      case 'enregistré':
        return Icons.hotel;
      case 'en attente':
        return Icons.hourglass_empty;
      case 'annulée':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes Réservations'),
          backgroundColor: const Color(0xFF1A237E),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Vous devez être connecté',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Mes Réservations'),
        backgroundColor: const Color(0xFF1A237E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
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
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReservations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reservations.length,
                    itemBuilder: (context, index) {
                      final reservation = _reservations[index];
                      return _buildReservationCard(reservation);
                    },
                  ),
                ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final status = reservation['status'] as String? ?? 'en attente';
    final checkInDate = reservation['checkInDate'] as DateTime?;
    final checkOutDate = reservation['checkOutDate'] as DateTime?;
    final numberOfNights = reservation['numberOfNights'] ?? 0;
    final totalPrice = reservation['totalPrice'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // En-tête avec statut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Réservation ${reservation['reservationCode'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Détails
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(Icons.hotel, 'Hôtel', reservation['hotelName'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.meeting_room, 'Chambre', 
                    'N° ${reservation['roomNumber']} - ${reservation['roomType']}'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.calendar_today, 'Arrivée',
                    checkInDate != null ? DateFormat('dd/MM/yyyy').format(checkInDate) : 'N/A'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.calendar_today, 'Départ',
                    checkOutDate != null ? DateFormat('dd/MM/yyyy').format(checkOutDate) : 'N/A'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.nights_stay, 'Nuits', '$numberOfNights'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.people, 'Personnes', '${reservation['numberOfGuests'] ?? 0}'),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${totalPrice.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          if (status.toLowerCase() != 'annulée' && status.toLowerCase() != 'cancelled' && 
              status.toLowerCase() != 'en attente' && status.toLowerCase() != 'pending')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _printReservationReceipt(reservation),
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimer le reçu'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A237E),
                        side: const BorderSide(color: Color(0xFF1A237E)),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$label:',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gesto/config/routes.dart';
import 'package:intl/intl.dart';

import '../widgets/side_menu.dart';

class OccupiedRoomsPage extends StatefulWidget {
  @override
  _OccupiedRoomsPageState createState() => _OccupiedRoomsPageState();
}

class _OccupiedRoomsPageState extends State<OccupiedRoomsPage> {
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
  bool _isLoading = true;
  List<Map<String, dynamic>> _occupiedRooms = [];
  String? _errorMessage;
  Map<String, bool> _processingRooms = {};

  @override
  void initState() {
    super.initState();
    _fetchOccupiedRooms();
  }

  Future<void> _fetchOccupiedRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Map<String, dynamic>> rooms = [];

      // Récupérer les chambres occupées de la collection 'bookings'
      QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', isEqualTo: 'enregistré')
          .where('userId', isEqualTo: _userId)
          .orderBy('roomNumber')
          .get();

      for (var doc in bookingSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['documentId'] = doc.id;
        data['collection'] = 'bookings'; // Ajouter le nom de la collection
        rooms.add(data);
      }

      // Récupérer les chambres occupées de la collection 'bookingshours'
      QuerySnapshot bookingsHoursSnapshot = await FirebaseFirestore.instance
          .collection('bookingshours')
          .where('status', isEqualTo: 'hourly')
          .where('userId', isEqualTo: _userId)
          .orderBy('roomNumber')
          .get();

      for (var doc in bookingsHoursSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['documentId'] = doc.id;
        data['collection'] = 'bookingshours'; // Ajouter le nom de la collection
        rooms.add(data);
      }

      // Trier toutes les chambres par numéro de chambre
      rooms.sort((a, b) => (a['roomNumber'] ?? '').compareTo(b['roomNumber'] ?? ''));

      setState(() {
        _occupiedRooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des chambres: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkoutRoom(Map<String, dynamic> roomData) async {
    String roomId = roomData['documentId'];

    // Vérifier si cette chambre est déjà en cours de traitement
    if (_processingRooms[roomId] == true) return;

    // Afficher une boîte de dialogue de confirmation
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation de check-out'),
        content: Text('Êtes-vous sûr de vouloir libérer la chambre ${roomData['roomNumber']} occupée par ${roomData['customerName']} ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _processingRooms[roomId] = true;
    });

    try {
      // Vérifier si roomData est null et contient les clés nécessaires
      if (roomData == null || !roomData.containsKey('documentId') ||
          !roomData.containsKey('roomId')) {
        _showErrorSnackBar('Les informations de réservation sont manquantes.');
        return;
      }

      String bookingDocId = roomData['documentId'];
      String roomId = roomData['roomId'];
      String? reservationId = roomData.containsKey('reservationId')
          ? roomData['reservationId']
          : null;
      String bookingCollection = roomData.containsKey('collection')
          ? roomData['collection']
          : 'bookings'; // Par défaut 'bookings' si non spécifié

      // Mettre à jour la réservation dans la collection appropriée
      if (bookingCollection == 'bookings') {
        await FirebaseFirestore.instance.collection('bookings').doc(bookingDocId).update({
          'status': 'terminé',
          'actualCheckOutDate': FieldValue.serverTimestamp(),
        });
      } else if (bookingCollection == 'bookingshours') {
        await FirebaseFirestore.instance.collection('bookingshours').doc(bookingDocId).update({
          'status': 'terminé',
          'actualCheckOutDate': FieldValue.serverTimestamp(),
        });
      } else {
        _showErrorSnackBar('Impossible de déterminer la collection de réservation pour la mise à jour.');
        return;
      }

      // Mettre à jour la réservation dans la collection 'reservations' si reservationId existe
      if (reservationId != null && reservationId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('reservations').doc(reservationId).update({
          'status': 'Terminé',
          'actualCheckOutDate': FieldValue.serverTimestamp(),
        });
      }

      // Libérer la chambre
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'status': 'disponible',
        'datedisponible': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Chambre ${roomData['roomNumber']} libérée avec succès');
      _fetchOccupiedRooms(); // Rafraîchir la liste
    } catch (e) {
      _showErrorSnackBar('Erreur lors du check-out: ${e.toString()}');
    } finally {
      setState(() {
        _processingRooms[roomId] = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 4),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chambres Occupées'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchOccupiedRooms,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des chambres occupées...'),
              ],
            ),
          )
              : _errorMessage != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade500,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchOccupiedRooms,
                  icon: Icon(Icons.refresh),
                  label: Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          )
              : _occupiedRooms.isEmpty
              ? _buildEmptyState()
              : _buildRoomsList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.checkoutPage);
        },
        label: Text('Check-out par numéro'),
        icon: Icon(Icons.logout),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hotel,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 24),
          Text(
            'Aucune chambre occupée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Toutes les chambres sont actuellement disponibles',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchOccupiedRooms,
            icon: Icon(Icons.refresh),
            label: Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList() {
    return RefreshIndicator(
      onRefresh: _fetchOccupiedRooms,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chambres Occupées',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Liste des chambres actuellement occupées',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16),
            // Résumé du nombre de chambres
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.deepPurple),
                  SizedBox(width: 12),
                  Text(
                    'Total: ${_occupiedRooms.length} chambre${_occupiedRooms.length > 1 ? 's' : ''} occupée${_occupiedRooms.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _occupiedRooms.length,
                itemBuilder: (context, index) {
                  final room = _occupiedRooms[index];
                  final isProcessing = _processingRooms[room['documentId']] == true;

                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 200,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    room['roomNumber'] ?? '-',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room['customerName'] ?? 'Client',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      room['customerPhone'] ?? 'Téléphone non renseigné',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(room),
                            ],
                          ),
                          SizedBox(height: 16),
                          Divider(),
                          SizedBox(height: 8),

                          // Dates d'arrivée et de départ prévue
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                              SizedBox(width: 8),
                              Text(
                                'Période de séjour:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Arrivée',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      room['checkInDate'] != null
                                          ? dateFormat.format((room['checkInDate'] as Timestamp).toDate())
                                          : 'Non renseigné',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward, size: 16, color: Colors.grey.shade400),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Départ prévu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      room['checkOutDate'] != null
                                          ? dateFormat.format((room['checkOutDate'] as Timestamp).toDate())
                                          : 'Non renseigné',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Informations supplémentaires
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                                  SizedBox(width: 4),
                                  Text(
                                    '${room['guestCount'] ?? 1} personne${(room['guestCount'] ?? 1) > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.payments_outlined, size: 16, color: Colors.grey.shade600),
                                  SizedBox(width: 4),
                                  Text(
                                    '${room['totalAmount'] ?? 0} FCFA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Bouton de check-out
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              icon: isProcessing
                                  ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Icon(Icons.logout),
                              label: Text(isProcessing ? 'Traitement...' : 'Libérer cette chambre'),
                              onPressed: isProcessing ? null : () => _checkoutRoom(room),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> room) {
    final paymentStatus = room['paymentStatus'];

    Color badgeColor;
    String statusText;

    if (paymentStatus == 'payé' || paymentStatus == 'Réglé') {
      badgeColor = Colors.green;
      statusText = 'Payé';
    } else if (paymentStatus == 'Partiel') {
      badgeColor = Colors.orange;
      statusText = 'Partiel';
    } else {
      badgeColor = Colors.red;
      statusText = 'En attente';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
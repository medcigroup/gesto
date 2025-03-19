import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../widgets/side_menu.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _roomNumberController = TextEditingController();
  Map<String, dynamic>? _bookingData;
  bool _isLoading = false;
  bool _isSearching = false;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

  Future<void> _fetchBookingDetails() async {
    FocusScope.of(context).unfocus();

    if (_roomNumberController.text.trim().isEmpty) {
      _showErrorSnackBar('Veuillez entrer un numéro de chambre');
      return;
    }

    setState(() {
      _isSearching = true;
      _bookingData = null;
    });

    try {
      String roomNumber = _roomNumberController.text.trim();
      QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('roomNumber', isEqualTo: roomNumber)
          .where('status', isEqualTo: 'enregistré')
          .where('userId', isEqualTo: _userId)
          .limit(1)
          .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        DocumentSnapshot bookingDoc = bookingSnapshot.docs.first;
        setState(() {
          _bookingData = bookingDoc.data() as Map<String, dynamic>;
          _bookingData!['documentId'] = bookingDoc.id;
        });
      } else {
        _showErrorSnackBar('Aucun enregistrement trouvé pour cette chambre.');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _checkoutClient() async {
    if (_bookingData == null) return;

    // Afficher une boîte de dialogue de confirmation
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation de check-out'),
        content: Text('Êtes-vous sûr de vouloir procéder au check-out du client ${_bookingData!['customerName']} ?'),
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

    setState(() => _isLoading = true);

    try {
      String bookingDocId = _bookingData!['documentId'];
      String roomId = _bookingData!['roomId'];
      String? reservationId = _bookingData!['reservationId']; // Récupérer l'ID de réservation s'il existe

      // Mettre à jour la réservation dans la collection 'bookings'
      await FirebaseFirestore.instance.collection('bookings').doc(bookingDocId).update({
        'status': 'terminé',
        'actualCheckOutDate': FieldValue.serverTimestamp(),
      });

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

      _showSuccessSnackBar('Client check-out effectué avec succès.');
      setState(() => _bookingData = null);
      _roomNumberController.clear();
    } catch (e) {
      _showErrorSnackBar('Erreur lors du check-out: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
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

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    MaterialColor? valueColor // Rendons ce paramètre optionnel
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: valueColor, // Utilisation de la couleur passée en paramètre
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateItem({
    required String title,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            date,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Check-out Client'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
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
    Text('Traitement en cours...'),
    ],
    ),
    )
        : SingleChildScrollView(
    padding: EdgeInsets.all(20),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Titre de la page
    Text(
    'Départ du client',
    style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: theme.primaryColor,
    ),
    ),
    SizedBox(height: 8),
    Text(
    'Entrez le numéro de chambre pour effectuer le check-out',
    style: TextStyle(
    fontSize: 16,
    color: Colors.grey.shade600,
    ),
    ),
    SizedBox(height: 32),

    // Section de recherche
    Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    ),
    shadowColor: Colors.black26,
    child: Padding(
    padding: EdgeInsets.all(20),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    'Rechercher une chambre',
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: theme.primaryColor,
    ),
    ),
    SizedBox(height: 16),
    TextField(
    controller: _roomNumberController,
    decoration: InputDecoration(
    labelText: 'Numéro de chambre',
    hintText: 'Ex: 101',
    prefixIcon: Icon(Icons.hotel),
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(width: 1),
    ),
    enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: theme.primaryColor, width: 2),
    ),
    filled: true,
    fillColor: Colors.grey.shade50,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    keyboardType: TextInputType.number,
    onSubmitted: (_) => _fetchBookingDetails(),
    ),
    SizedBox(height: 16),
    SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton.icon(
    icon: Icon(_isSearching ? null : Icons.search),
    label: _isSearching
    ? Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(
    color: Colors.white,
    strokeWidth: 3,
    ),
    ),
    SizedBox(width: 12),
    Text('Recherche en cours...'),
    ],
    )
        : Text('Rechercher'),
    onPressed: _isSearching ? null : _fetchBookingDetails,
    style: ElevatedButton.styleFrom(
    backgroundColor: theme.primaryColor,
    foregroundColor: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    ),
    ),
    ],
    ),
    ),
    ),

    SizedBox(height: 32),

    // Résultats de recherche
    if (_bookingData != null) ...[
    Text(
    'Détails de la réservation',
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: theme.primaryColor,
    ),
    ),
    SizedBox(height: 16),
    Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    ),
    shadowColor: Colors.black26,
    child: Padding(
    padding: EdgeInsets.all(20),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // En-tête avec nom et chambre
    Row(
    children: [
    CircleAvatar(
    radius: 30,
    backgroundColor: theme.primaryColor.withOpacity(0.1),
    child: Icon(
    Icons.person,
    size: 32,
    color: theme.primaryColor,
    ),
    ),
    SizedBox(width: 16),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    _bookingData!['customerName'] ?? 'Client',
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    ),
    ),
    SizedBox(height: 4),
    Text(
    'Chambre ${_bookingData!['roomNumber']}',
    style: TextStyle(
    fontWeight: FontWeight.w500,
    color: Colors.grey.shade700,
    ),
    ),
    ],
    ),
    ),
    ],
    ),
    SizedBox(height: 20),
    Divider(),
    SizedBox(height: 16),

    // Informations de contact
      _buildInfoItem(
        icon: Icons.email_outlined,
        title: 'Email',
        value: _bookingData!['customerEmail'] ?? 'Non renseigné',
      ),
      _buildInfoItem(
        icon: Icons.phone_outlined,
        title: 'Téléphone',
        value: _bookingData!['customerPhone'] ?? 'Non renseigné',
      ),
      _buildInfoItem(
        icon: Icons.people_outline,
        title: 'Nombre de personnes',
        value: '${_bookingData!['guestCount'] ?? 1}',
      ),
      SizedBox(height: 16),
      Divider(),
      SizedBox(height: 16),

      // Dates d'arrivée et de départ
      Text(
        'Période de séjour',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
      SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _buildDateItem(
              title: 'Arrivée',
              date: _bookingData!['checkInDate'] != null
                  ? dateFormat.format((_bookingData!['checkInDate'] as Timestamp).toDate())
                  : 'Non renseigné',
              icon: Icons.login,
              color: Colors.green,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildDateItem(
              title: 'Départ prévu',
              date: _bookingData!['checkOutDate'] != null
                  ? dateFormat.format((_bookingData!['checkOutDate'] as Timestamp).toDate())
                  : 'Non renseigné',
              icon: Icons.logout,
              color: Colors.red,
            ),
          ),
        ],
      ),
      SizedBox(height: 16),
      Divider(),
      SizedBox(height: 16),

      // Informations additionnelles
      Text(
        'Informations complémentaires',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
      SizedBox(height: 12),
      _buildInfoItem(
        icon: Icons.payments_outlined,
        title: 'Montant total',
        value: '${_bookingData!['totalAmount'] ?? 0} FCFA',
      ),
      _buildInfoItem(
        icon: Icons.credit_card_outlined,
        title: 'Statut de paiement',
        value: _bookingData!['paymentStatus'] ?? 'En attente',
        valueColor: (_bookingData!['paymentStatus'] == null || _bookingData!['paymentStatus'] == 'En attente')
            ? Colors.red
            : Colors.green,
      ),
      _buildInfoItem(
        icon: Icons.note_outlined,
        title: 'Notes',
        value: _bookingData!['notes'] ?? 'Aucune note',
      ),
      SizedBox(height: 24),

      // Bouton de check-out
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          icon: Icon(Icons.logout),
          label: Text('Procéder au check-out'),
          onPressed: _checkoutClient,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ],
    ),
    ),
    ),
    ],

      if (_bookingData == null && !_isSearching && _roomNumberController.text.isNotEmpty) ...[
        SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 16),
              Text(
                'Aucun enregistrement actif trouvé',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Vérifiez le numéro de chambre et réessayez',
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
    ),
    ),
    ),
      ),
    );
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    super.dispose();
  }
}



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../config/getConnectedUserAdminId.dart';
import '../../widgets/side_menu.dart';



class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> with SingleTickerProviderStateMixin {
  final TextEditingController _roomNumberController = TextEditingController();
  Map<String, dynamic>? _bookingData;
  bool _isLoading = false;
  bool _isSearching = false;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
  late String idadmin;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeData();
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _animationController.dispose();
    super.dispose();
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 4),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _initializeData() async {
    // Récupérer l'ID de l'administrateur connecté
    idadmin = (await getConnectedUserAdminId())!;
  }

  Future<void> _fetchBookingDetails() async {
    FocusScope.of(context).unfocus();

    if (_roomNumberController.text
        .trim()
        .isEmpty) {
      _showErrorSnackBar('Veuillez entrer un numéro de chambre');
      return;
    }

    setState(() {
      _isSearching = true;
      _bookingData = null;
    });

    try {
      String roomNumber = _roomNumberController.text.trim();
      String userId = idadmin;

      // Rechercher dans la collection 'bookings' (status == 'enregistré')
      QuerySnapshot bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('roomNumber', isEqualTo: roomNumber)
          .where('status', isEqualTo: 'enregistré')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      // Rechercher dans la collection 'bookingshours' (status == 'hourly')
      QuerySnapshot hourlyBookingSnapshot = await FirebaseFirestore.instance
          .collection('bookingshours')
          .where('roomNumber', isEqualTo: roomNumber)
          .where('status', isEqualTo: 'hourly')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (bookingSnapshot.docs.isNotEmpty) {
        DocumentSnapshot bookingDoc = bookingSnapshot.docs.first;
        setState(() {
          _bookingData = bookingDoc.data() as Map<String, dynamic>;
          _bookingData!['documentId'] = bookingDoc.id;
          _bookingData!['collection'] =
          'bookings'; // Ajouter le nom de la collection
        });
        _animationController.forward(from: 0.0);
      } else if (hourlyBookingSnapshot.docs.isNotEmpty) {
        DocumentSnapshot hourlyBookingDoc = hourlyBookingSnapshot.docs.first;
        setState(() {
          _bookingData = hourlyBookingDoc.data() as Map<String, dynamic>;
          _bookingData!['documentId'] = hourlyBookingDoc.id;
          _bookingData!['collection'] =
          'bookingshours'; // Ajouter le nom de la collection
        });
        _animationController.forward(from: 0.0);
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
      builder: (context) =>
          AlertDialog(
            title: Text('Confirmation de check-out'),
            content: Text(
                'Êtes-vous sûr de vouloir procéder au check-out du client ${_bookingData!['customerName']} ?'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Confirmer'),
              ),
            ],
          ),
    );


    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // Vérifier si _bookingData est null et contient les clés nécessaires
      if (_bookingData == null || !_bookingData!.containsKey('documentId') ||
          !_bookingData!.containsKey('roomId')) {
        _showErrorSnackBar('Les informations de réservation sont manquantes.');
        return;
      }

      String bookingDocId = _bookingData!['documentId'];
      String roomId = _bookingData!['roomId'];
      String? reservationId = _bookingData!.containsKey('reservationId')
          ? _bookingData!['reservationId']
          : null;
      String? bookingCollection = _bookingData!['collection']; // Récupérer le nom de la collection

      // Mettre à jour la réservation dans la collection appropriée
      if (bookingCollection == 'bookings') {
        await FirebaseFirestore.instance.collection('bookings').doc(
            bookingDocId).update({
          'status': 'terminé',
          'actualCheckOutDate': FieldValue.serverTimestamp(),
        });
      } else if (bookingCollection == 'bookingshours') {
        await FirebaseFirestore.instance.collection('bookingshours').doc(
            bookingDocId).update({
          'status': 'terminé',
          'actualCheckOutDate': FieldValue.serverTimestamp(),
        });
      } else {
        _showErrorSnackBar(
            'Impossible de déterminer la collection de réservation pour la mise à jour.');
        setState(() =>
        _isLoading =
        false); // Important to set loading to false in case of error
        return;
      }

      // Mettre à jour la réservation dans la collection 'reservations' si reservationId existe
      if (reservationId != null && reservationId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('reservations').doc(
            reservationId).update({
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

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    MaterialColor? valueColor // Rendons ce paramètre optionnel
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme
                      .of(context)
                      .primaryColor
                      .withOpacity(0.1),
                  Theme
                      .of(context)
                      .primaryColor
                      .withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme
                  .of(context)
                  .primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: valueColor ?? Colors.grey.shade800,
                  ),
                ),
              ],
            ),
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
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            date,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery
        .of(context)
        .size;
    final isTablet = size.width > 600;

    return Scaffold(
    
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.primaryColor,
        title: Text(
          'Départ du client',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(theme.primaryColor),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Traitement en cours...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête avec icône
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primaryColor.withOpacity(0.1),
                        theme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestion des départs',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Effectuez le check-out de vos clients rapidement',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Section de recherche
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  shadowColor: Colors.black12,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: theme.primaryColor,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Rechercher une chambre',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _roomNumberController,
                          decoration: InputDecoration(
                            labelText: 'Numéro de chambre',
                            hintText: 'Ex: 101',
                            prefixIcon: Icon(Icons.hotel_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onSubmitted: (_) => _fetchBookingDetails(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSearching
                                ? null
                                : _fetchBookingDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: _isSearching ? 0 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              disabledBackgroundColor:
                              theme.primaryColor.withOpacity(0.5),
                            ),
                            child: _isSearching
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Recherche en cours...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_rounded),
                                SizedBox(width: 8),
                                Text(
                                  'Rechercher',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 32),

                // Résultats de recherche avec animation
                if (_bookingData != null)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildBookingDetailsCard(theme),
                  ),

                if (_bookingData == null &&
                    !_isSearching &&
                    _roomNumberController.text.isNotEmpty)
                  _buildNoResultsWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_rounded,
              color: theme.primaryColor,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Détails de la réservation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadowColor: Colors.black12,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec nom et chambre
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primaryColor.withOpacity(0.1),
                        theme.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.primaryColor,
                              theme.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 36,
                          color: Colors.white,
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
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hotel_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Chambre ${_bookingData!['roomNumber']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Informations de contact
                Text(
                  'Informations de contact',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                _buildInfoItem(
                  icon: Icons.email_rounded,
                  title: 'Email',
                  value: _bookingData!['customerEmail'] ?? 'Non renseigné',
                ),
                _buildInfoItem(
                  icon: Icons.phone_rounded,
                  title: 'Téléphone',
                  value: _bookingData!['customerPhone'] ?? 'Non renseigné',
                ),
                _buildInfoItem(
                  icon: Icons.people_rounded,
                  title: 'Nombre de personnes',
                  value: '${_bookingData!['guestCount'] ?? 1}',
                ),
                SizedBox(height: 24),

                // Dates d'arrivée et de départ
                Text(
                  'Période de séjour',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateItem(
                        title: 'Arrivée',
                        date: _bookingData!['checkInDate'] != null
                            ? dateFormat.format(
                            (_bookingData!['checkInDate'] as Timestamp)
                                .toDate())
                            : 'Non renseigné',
                        icon: Icons.login_rounded,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildDateItem(
                        title: 'Départ prévu',
                        date: _bookingData!['checkOutDate'] != null
                            ? dateFormat.format(
                            (_bookingData!['checkOutDate'] as Timestamp)
                                .toDate())
                            : 'Non renseigné',
                        icon: Icons.logout_rounded,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Informations additionnelles
                Text(
                  'Informations complémentaires',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                _buildInfoItem(
                  icon: Icons.payments_rounded,
                  title: 'Montant total',
                  value: '${_bookingData!['totalAmount'] ?? 0} FCFA',
                ),
                _buildInfoItem(
                  icon: Icons.credit_card_rounded,
                  title: 'Statut de paiement',
                  value: _bookingData!['paymentStatus'] ?? 'En attente',
                  valueColor: (_bookingData!['paymentStatus'] == null ||
                      _bookingData!['paymentStatus'] == 'En attente')
                      ? Colors.red
                      : Colors.green,
                ),
                _buildInfoItem(
                  icon: Icons.note_rounded,
                  title: 'Notes',
                  value: _bookingData!['notes'] ?? 'Aucune note',
                ),
                SizedBox(height: 28),

                // Bouton de check-out
                Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.red, Colors.red.shade700],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _checkoutClient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Procéder au check-out',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsWidget() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Aucun enregistrement actif trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'Vérifiez le numéro de chambre et réessayez',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/checkin/options_package_section.dart';
import '../../components/reservation/ModernReservationPage.dart';
import '../../config/generationcode.dart';
import '../../config/getConnectedUserAdminId.dart';


class CheckInForm extends StatefulWidget {
  final Reservation reservation;

  const CheckInForm({super.key, required this.reservation});

  @override
  State<CheckInForm> createState() => _CheckInFormState();
}

class _CheckInFormState extends State<CheckInForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _idNumberController = TextEditingController();
  TextEditingController _nationalityController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  // Variables pour les options
  Map<String, bool> _selectedOptions = {};
  String? _userId;
  bool _isInitializing = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.reservation.customerName;
    _checkInDate = widget.reservation.checkInDate;
    _checkOutDate = widget.reservation.checkOutDate;
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _initializeUserId();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    _nationalityController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserId() async {
    try {
      _userId = await getConnectedUserAdminId();
      print('✅ UserId récupéré pour CheckInForm: $_userId');

      if (mounted) {
        setState(() => _isInitializing = false);
        _animationController.forward();
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'userId: $e');
      _userId = FirebaseAuth.instance.currentUser?.uid;
      if (mounted) {
        setState(() => _isInitializing = false);
        _animationController.forward();
      }
    }
  }

  void _onOptionsChanged(Map<String, bool> options) {
    setState(() {
      _selectedOptions = options;
    });
    print('🎛️ Options sélectionnées dans CheckInForm: ${options.toString()}');
  }

  Future<void> _selectCheckInDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
      });
    }
  }

  Future<void> _selectCheckOutDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  void _confirmCheckIn() async {
    if (_formKey.currentState!.validate()) {
      final numberOfNights = _checkOutDate?.difference(_checkInDate!).inDays;
      final numberOfNightsCorrected = numberOfNights! + (_checkOutDate!.isAfter(_checkInDate!) ? 1 : 0);

      final bookingData = {
        'customerName': _fullNameController.text,
        'idNumber': _idNumberController.text,
        'nationality': _nationalityController.text,
        'address': _addressController.text,
        'checkInDate': _checkInDate,
        'checkOutDate': _checkOutDate,
        'reservationId': widget.reservation.id,
        'roomId': widget.reservation.roomId,
        'roomNumber': widget.reservation.roomNumber,
        'roomType': widget.reservation.roomType,
        'customerEmail': widget.reservation.customerEmail,
        'customerPhone': widget.reservation.customerPhone,
        'numberOfGuests': widget.reservation.numberOfGuests,
        'specialRequests': widget.reservation.specialRequests,
        'nights': numberOfNightsCorrected,
        'pricePerNight': widget.reservation.pricePerNight,
        'totalAmount': widget.reservation.pricePerNight != null && _checkOutDate != null && _checkInDate != null
            ? widget.reservation.pricePerNight! * numberOfNightsCorrected
            : null,
        'userId': _userId ?? FirebaseAuth.instance.currentUser!.uid,
        'options': _selectedOptions,
      };

      await _saveBookingData(bookingData);
    }
  }

  Future<void> _saveBookingData(Map<String, dynamic> bookingData) async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('Enregistrement du client en cours...')
              ],
            ),
          );
        },
      );
    }

    try {
      final enregistrementCode = await CodeGenerator.generateRegistrationCode();

      final reservationDoc = await FirebaseFirestore.instance
          .collection('reservations')
          .doc(bookingData['reservationId'])
          .get();

      final depositAmount = reservationDoc.data()?['depositAmount'] ?? 0;
      final depositPercentage = reservationDoc.data()?['depositPercentage'] ?? 0;
      final depositPaid = reservationDoc.data()?['depositPaid'] ?? false;

      final totalAmount = bookingData['totalAmount'] ?? 0;
      final balanceDue = totalAmount - depositAmount;

      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
      await bookingRef.set({
        'EnregistrementCode': enregistrementCode,
        'reservationId': bookingData['reservationId'],
        'actualCheckOutDate': DateTime.now().toUtc(),
        'address': bookingData['address'],
        'checkInDate': bookingData['checkInDate'],
        'checkOutDate': bookingData['checkOutDate'],
        'createdAt': FieldValue.serverTimestamp(),
        'customerEmail': bookingData['customerEmail'],
        'customerName': bookingData['customerName'],
        'customerPhone': bookingData['customerPhone'],
        'idNumber': bookingData['idNumber'],
        'isWalkIn': false,
        'nationality': bookingData['nationality'],
        'nights': bookingData['nights'],
        'numberOfGuests': bookingData['numberOfGuests'],
        'paymentStatus': balanceDue > 0 ? 'Partiellement payé' : 'Payé',
        'roomId': bookingData['roomId'],
        'roomNumber': bookingData['roomNumber'],
        'roomPrice': bookingData['pricePerNight'],
        'roomType': bookingData['roomType'],
        'status': 'enregistré',
        'totalAmount': bookingData['totalAmount'],
        'userId': bookingData['userId'],
        'depositAmount': depositAmount,
        'depositPercentage': depositPercentage,
        'depositPaid': depositPaid,
        'balanceDue': balanceDue,
        'options': bookingData['options'],
      });

      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(bookingData['reservationId'])
          .update({'status': 'Enregistré'});

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(bookingData['roomId'])
          .update({
        'status': 'occupée',
        'datedisponible': Timestamp.fromDate(_checkOutDate!),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Client enregistré avec succès')),
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

      // CORRECTION : Ne fermer qu'une seule fois pour retourner au dashboard
      // Retourner true pour indiquer que des données ont été modifiées
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Enregistrement du Client',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initialisation...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Enregistrement du Client',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // En-tête moderne
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.how_to_reg_rounded,
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
                                    'Enregistrement de réservation',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Complétez les informations du client',
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

                      const SizedBox(height: 24),

                      // Informations de la réservation
                      _buildSectionCard(
                        context,
                        icon: Icons.info_rounded,
                        title: 'Informations de la Réservation',
                        children: [
                          _buildInfoRow(
                            icon: Icons.hotel_rounded,
                            label: 'Chambre',
                            value: 'N° ${widget.reservation.roomNumber}',
                            context: context,
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.category_rounded,
                            label: 'Type',
                            value: widget.reservation.roomType,
                            context: context,
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.people_rounded,
                            label: 'Personnes',
                            value: '${widget.reservation.numberOfGuests}',
                            context: context,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Informations Personnelles
                      _buildSectionCard(
                        context,
                        icon: Icons.person_rounded,
                        title: 'Informations Personnelles',
                        children: [
                          _buildModernTextField(
                            controller: _fullNameController,
                            label: 'Nom Complet*',
                            hint: 'Entrez le nom complet',
                            icon: Icons.person_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le nom complet';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _idNumberController,
                            label: 'Numéro de pièce d\'identité*',
                            hint: 'Entrez le numéro d\'identité',
                            icon: Icons.badge_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le numéro de pièce d\'identité';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _nationalityController,
                            label: 'Nationalité*',
                            hint: 'Entrez la nationalité',
                            icon: Icons.flag_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer la nationalité';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: _addressController,
                            label: 'Adresse*',
                            hint: 'Entrez l\'adresse complète',
                            icon: Icons.home_rounded,
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer l\'adresse';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Dates du Séjour
                      _buildSectionCard(
                        context,
                        icon: Icons.calendar_month_rounded,
                        title: 'Dates du Séjour',
                        children: [
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _buildDateSelector(
                                  context,
                                  label: 'Date d\'arrivée*',
                                  date: _checkInDate,
                                  icon: Icons.login_rounded,
                                  color: Colors.green,
                                  onTap: () => _selectCheckInDate(context),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDateSelector(
                                  context,
                                  label: 'Date de départ*',
                                  date: _checkOutDate,
                                  icon: Icons.logout_rounded,
                                  color: Colors.red,
                                  onTap: () => _selectCheckOutDate(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // SECTION OPTIONS GRATUITES
                      OptionsSection(
                        selectedOptions: _selectedOptions,
                        onOptionsChanged: _onOptionsChanged,
                        userId: _userId,
                      ),

                      const SizedBox(height: 30),

                      // Bouton de confirmation
                      Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate() && _checkInDate != null && _checkOutDate != null) {
                              if (_checkOutDate!.isBefore(_checkInDate!)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.white),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text('La date de départ doit être après la date d\'arrivée'),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              } else {
                                _confirmCheckIn();
                              }
                            } else if (_checkInDate == null || _checkOutDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.white),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text('Veuillez sélectionner les dates d\'arrivée et de départ'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          },
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
                              Icon(Icons.check_circle_rounded, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Confirmer l\'enregistrement',
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

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildDateSelector(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              date == null ? 'Sélectionner' : DateFormat('dd/MM/yyyy').format(date),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: date == null ? Theme.of(context).hintColor : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

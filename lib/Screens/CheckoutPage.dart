import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _roomNumberController = TextEditingController();
  Map<String, dynamic>? _bookingData;
  bool _isLoading = false;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> _fetchBookingDetails() async {
    setState(() => _isLoading = true);

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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkoutClient() async {
    if (_bookingData == null) return;
    setState(() => _isLoading = true);

    try {
      String bookingDocId = _bookingData!['documentId'];
      String roomId = _bookingData!['roomId'];

      // Mettre à jour la réservation
      await FirebaseFirestore.instance.collection('bookings').doc(bookingDocId).update({
        'status': 'terminé',
        'actualCheckOutDate': FieldValue.serverTimestamp(),
      });

      // Libérer la chambre
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'status': 'disponible',
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
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Check-out Client')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _roomNumberController,
              decoration: InputDecoration(
                labelText: 'Numéro de Chambre',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchBookingDetails,
              child: Text('Rechercher l\'enregistrement'),
            ),
            SizedBox(height: 20),
            if (_bookingData != null) ...[
              Text('Client: ${_bookingData!['customerName']}'),
              Text('Email: ${_bookingData!['customerEmail']}'),
              Text('Téléphone: ${_bookingData!['customerPhone']}'),
              Text('Date Check-in: ${(_bookingData!['checkInDate'] as Timestamp).toDate()}'),
              Text('Date Check-out prévue: ${(_bookingData!['checkOutDate'] as Timestamp).toDate()}'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkoutClient,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Confirmer le Check-out'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}



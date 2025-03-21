
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Modified function to handle the future properly
Future<void> printPaymentReceipt(DocumentSnapshot booking, double amount, String paymentMethod, Timestamp paymentDate) async {
  final data = booking.data() as Map<String, dynamic>;

  // Calculate the remaining amount before creating the PDF
  final double remainingAmount = await _calculateRemainingAmount(booking.id, data['totalAmount'], amount);

  // Récupérer les paramètres de l'hôtel depuis Firestore
  final hotelSettings = await _getHotelSettings();

  // Créer le document PDF
  final pdf = pw.Document();

  // Utiliser les paramètres de l'hôtel récupérés de Firestore
  final hotelName = hotelSettings['hotelName'] ?? "HOTEL";
  final hotelAddress = hotelSettings['address'] ?? "Adresse non spécifiée";
  final hotelPhone = hotelSettings['phoneNumber'] ?? "Téléphone non spécifié";
  final hotelEmail = hotelSettings['email'] ?? "Email non spécifié";

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      build: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(hotelName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(hotelAddress, style: pw.TextStyle(fontSize: 10)),
                    pw.Text('Tél: $hotelPhone', style: pw.TextStyle(fontSize: 10)),
                    pw.Text('Email: $hotelEmail', style: pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 8),
                    pw.Text('REÇU DE PAIEMENT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Divider(thickness: 1),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Informations client et réservation
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Numéro de reçu:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('REÇU-${DateFormat('yyyyMMdd').format(DateTime.now())}-${data['EnregistrementCode']}'),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(paymentDate.toDate())),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Client:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(data['customerName'] ?? 'Non spécifié'),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Téléphone:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(data['customerPhone'] ?? 'Non spécifié'),
                ],
              ),

              pw.SizedBox(height: 15),

              // Détails de la réservation
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  border: pw.Border.all(width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Détails de la réservation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Réservation:'),
                        pw.Text(data['EnregistrementCode'] ?? 'Non spécifié'),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Chambre:'),
                        pw.Text('${data['roomNumber']} (${data['roomType']})'),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Période:'),
                        pw.Text('${_formatDateShort(data['checkInDate'])} - ${_formatDateShort(data['checkOutDate'])}'),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Nuits:'),
                        pw.Text('${data['nights']}'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // Détails du paiement
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  border: pw.Border.all(width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Détails du paiement', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Montant total:'),
                        pw.Text(NumberFormat.currency(symbol: '${hotelSettings['currency'] ?? 'FCFA'} ', decimalDigits: 0).format(data['totalAmount'])),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Montant payé ce jour:'),
                        pw.Text(NumberFormat.currency(symbol: '${hotelSettings['currency'] ?? 'FCFA'} ', decimalDigits: 0).format(amount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Méthode de paiement:'),
                        pw.Text(paymentMethod),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    // Ajouter le solde restant (calculé avant la création du PDF)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Solde restant:'),
                        pw.Text(
                          NumberFormat.currency(symbol: '${hotelSettings['currency'] ?? 'FCFA'} ', decimalDigits: 0).format(remainingAmount),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: remainingAmount > 0 ? PdfColors.red : PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 150,
                        height: 40,
                      ),
                      pw.Text('Signature Client'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 150,
                        height: 40,
                      ),
                      pw.Text('Signature Caissier'),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Pied de page
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Divider(),
                    pw.SizedBox(height: 5),
                    pw.Text('Merci pour votre confiance !', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                    pw.SizedBox(height: 2),
                    pw.Text('Ce reçu est généré automatiquement et ne nécessite pas de cachet.', style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  // Imprimer le PDF
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name: 'Reçu_${data['EnregistrementCode']}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
  );

  // Optionnel: Sauvegarder le PDF
  // final output = await getTemporaryDirectory();
  // final file = File('${output.path}/Reçu_${data['EnregistrementCode']}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
  // await file.writeAsBytes(await pdf.save());
}

// Fonction auxiliaire pour calculer le montant restant
Future<double> _calculateRemainingAmount(String bookingId, double totalAmount, double currentPayment) async {
  final paymentsSnapshot = await FirebaseFirestore.instance
      .collection('transactions')
      .where('bookingId', isEqualTo: bookingId)
      .where('type', isEqualTo: 'payment')
      .get();

  double paidAmount = 0;
  for (var payment in paymentsSnapshot.docs) {
    paidAmount += (payment.data()['amount'] ?? 0).toDouble();
  }

  // Ne pas compter deux fois le paiement actuel
  paidAmount -= currentPayment;

  return totalAmount - paidAmount - currentPayment;
}

// Fonction pour récupérer les paramètres de l'hôtel
Future<Map<String, dynamic>> _getHotelSettings() async {
  try {
    final user = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid);
    final hotelSettings = await FirebaseFirestore.instance.collection('hotelSettings').doc(user.id).get();

    if (hotelSettings.exists) {
      return hotelSettings.data() ?? {};
    } else {
      return {
        'hotelName': 'HOTEL',
        'address': 'Adresse non spécifiée',
        'phoneNumber': 'Téléphone non spécifié',
        'email': 'Email non spécifié',
        'currency': 'FCFA'
      };
    }
  } catch (e) {
    print('Erreur lors de la récupération des paramètres de l\'hôtel : $e');
    return {
      'hotelName': 'HOTEL',
      'address': 'Adresse non spécifiée',
      'phoneNumber': 'Téléphone non spécifié',
      'email': 'Email non spécifié',
      'currency': 'FCFA'
    };
  }
}

// Ajoutez cette fonction si elle n'existe pas déjà dans votre code
String _formatDateShort(dynamic date) {
  if (date == null) return '';

  if (date is Timestamp) {
    return DateFormat('dd/MM/yyyy').format(date.toDate());
  }

  return '';
}
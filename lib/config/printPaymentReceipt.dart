import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Fonction modifiée pour prendre en compte les informations de réduction
Future<void> printPaymentReceipt(
    DocumentSnapshot booking,
    double amount,
    String paymentMethod,
    String transactionCodev,
    Timestamp paymentDate,
    [double discountRate = 0,
      double discountAmount = 0]) async {
  final data = booking.data() as Map<String, dynamic>;

  final paymentsSnapshot  = await FirebaseFirestore.instance
      .collection('transactions')
      .where('bookingId', isEqualTo: booking.id)
      .where('transactionCode', isEqualTo: transactionCodev)
      .where('type', isEqualTo: 'payment')
      .get();

  final roomsSnapshot = await FirebaseFirestore.instance
      .collection('rooms')
      .where('id', isEqualTo: data['roomId'])
      .get();

// Vérifier si des documents existent
  List<String> amenities = [];
  if (roomsSnapshot.docs.isNotEmpty) {
    // Récupérer les données du premier document
    var roomData = roomsSnapshot.docs.first.data();
    amenities = List<String>.from(roomData['amenities'] ?? []);
  }


  // D'abord, récupérez le code de transaction à partir du premier document dans le snapshot
  String transactionCode = 'NOCODE';
  if (paymentsSnapshot.docs.isNotEmpty) {
    var docData = paymentsSnapshot.docs.first.data();
    transactionCode = docData['transactionCode'] ?? 'NOCODE';
  }



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
  final currency = hotelSettings['currency'] ?? "FCFA";

  // Déterminer si une réduction a été appliquée
  final bool hasDiscount = discountRate > 0 || discountAmount > 0;
  // Calculer le montant brut (avant réduction)
  final double grossAmount = hasDiscount ? amount + discountAmount : amount;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,  // Format A4 au lieu de A5
      build: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(15),
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

              pw.SizedBox(height: 5),

              // Informations client et réservation
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Numéro de reçu:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                          'REÇU-${DateFormat('yyyyMMdd').format(DateTime.now())}-${data['EnregistrementCode']}-$transactionCode',
                  ),
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

              pw.SizedBox(height: 5),

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
                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Tarif par nuit:'),
                        pw.Text('${NumberFormat.currency(symbol: '$currency ', decimalDigits: 0).format(data['roomPrice'])}'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  border: pw.Border.all(width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Détails de la chambre', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Chambre:'),
                        pw.Text('N°${data['roomNumber']} (${data['roomType']})'),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text('Commodités:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 3),
                    // Utilisation de Wrap pour aligner horizontalement
                    pw.Wrap(
                      spacing: 8, // Espace entre les éléments
                      runSpacing: 4, // Espace entre les lignes
                      children: amenities.map((amenity) {
                        return pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey300,
                            borderRadius: pw.BorderRadius.circular(5),
                          ),
                          child: pw.Text(
                            amenity,
                            style: pw.TextStyle(color: PdfColors.black),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),


              pw.SizedBox(height: 5),
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
                        pw.Text(NumberFormat.currency(symbol: '$currency ', decimalDigits: 0).format(data['totalAmount'])),
                      ],
                    ),

                    // Afficher les détails de réduction si une réduction a été appliquée
                    if (hasDiscount) ...[
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Montant avant réduction:'),
                          pw.Text(
                            NumberFormat.currency(symbol: '$currency ', decimalDigits: 0).format(grossAmount),

                          ),
                        ],
                      ),
                      // Afficher le taux de réduction s'il est supérieur à zéro
                      if (discountRate > 0) ...[
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Réduction (${discountRate.toStringAsFixed(1)}%):'),
                            pw.Text(
                              '- ${NumberFormat.currency(symbol: '$currency ', decimalDigits: 0).format(discountAmount)}',
                              style: pw.TextStyle(color: PdfColors.green),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Sinon, afficher seulement le montant de réduction
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Réduction:'),
                            pw.Text(
                              '- ${NumberFormat.currency(symbol: '$currency ', decimalDigits: 0).format(discountAmount)}',
                              style: pw.TextStyle(color: PdfColors.green),
                            ),
                          ],
                        ),
                      ],
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Montant après réduction:'),
                          pw.Text(
                            NumberFormat.currency(symbol: '$currency ', decimalDigits: 0).format(grossAmount-discountAmount),

                          ),
                        ],
                      ),
                    ],

                    pw.SizedBox(height: 3),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Montant payé ce jour:'),
                        pw.Text(
                          NumberFormat.currency(symbol: '$currency ', decimalDigits: 0).format(amount),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
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
                          NumberFormat.currency(symbol: '$currency ', decimalDigits: 0).format(remainingAmount),
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

// Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Signature Client
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 150,
                        height: 40, // Légèrement augmenté pour faciliter la signature
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 1)), // Ligne pour la signature
                        ),
                      ),
                      pw.SizedBox(height: 3), // Moins d'espace après la ligne de signature
                      pw.Text(
                        'Signature Client',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),

                  // Signature Caissier
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 150,
                        height: 40,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 1)), // Ligne pour la signature
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Signature Caissier',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 5), // Réduit l'espace avant le pied de page

// Pied de page
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Divider(),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Merci pour votre confiance !',
                      style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                    ),
                    pw.SizedBox(height: 3), // Réduction de l’espace entre les textes
                    pw.Text(
                      'Ce reçu fait office de preuve de paiement.',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Pour toute annulation ou remboursement, veuillez consulter notre politique d\'annulation.',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Nous espérons vous revoir bientôt !',
                      style: pw.TextStyle(fontSize: 10),
                    ),

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
}

// Fonction auxiliaire pour calculer le montant restant
Future<double> _calculateRemainingAmount(String bookingId, double totalAmount, double currentPayment) async {
  // Récupération des paiements précédents
  final paymentsSnapshot = await FirebaseFirestore.instance
      .collection('transactions')
      .where('bookingId', isEqualTo: bookingId)
      .where('type', isEqualTo: 'payment')
      .get();

  // Récupération des réductions
  final discountsSnapshot = await FirebaseFirestore.instance
      .collection('transactions')
      .where('bookingId', isEqualTo: bookingId)
      .where('type', isEqualTo: 'discount')
      .get();

  // Calcul du montant total payé (hors paiement actuel)
  double paidAmount = 0;
  for (var payment in paymentsSnapshot.docs) {
    paidAmount += (payment.data()['amount'] ?? 0).toDouble();
  }
  // Ne pas compter deux fois le paiement actuel
  paidAmount -= currentPayment;

  // Calcul du montant total des réductions
  double discountAmount = 0;
  for (var discount in discountsSnapshot.docs) {
    discountAmount += (discount.data()['amount'] ?? 0).toDouble();
  }

  // Calcul du montant restant en prenant en compte totalAmount, paidAmount, discountAmount et currentPayment
  return totalAmount - paidAmount - discountAmount - currentPayment;
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
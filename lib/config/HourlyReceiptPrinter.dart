import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

class HourlyReceiptPrinter {
  // Méthode principale pour imprimer le reçu avec option de prévisualisation
  static Future<void> printHourlyReceipt(BuildContext context, String bookingId, {bool showPreview = true}) async {
    try {
      // Afficher le dialogue de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Récupérer les données de la réservation
      final bookingData = await _fetchBookingData(bookingId);

      // Récupérer les paramètres de l'hôtel
      final hotelInfo = await _fetchHotelInfo(bookingData['userId']);

      // Fermer le dialogue de chargement
      Navigator.of(context).pop();

      // Générer le PDF
      final pdf = await _generateReceipt(bookingData, hotelInfo);

      // Nom du document
      final documentName = 'Reçu_${bookingData['EnregistrementCode'] ?? 'Passage'}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';

      if (showPreview) {
        // Afficher la prévisualisation
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _PdfPreviewScreen(
              pdf: pdf,
              documentName: documentName,
            ),
          ),
        );
      } else {
        // Impression directe sans prévisualisation
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: documentName,
        );
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Afficher le message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'impression du reçu: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Récupérer les données de la réservation
  static Future<Map<String, dynamic>> _fetchBookingData(String bookingId) async {
    final doc = await FirebaseFirestore.instance.collection('bookingshours').doc(bookingId).get();

    if (!doc.exists) {
      throw Exception('Réservation non trouvée');
    }

    return doc.data() as Map<String, dynamic>;
  }

  // Récupérer les informations de l'hôtel
  static Future<Map<String, dynamic>> _fetchHotelInfo(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('hotelSettings').doc(userId).get();

    if (!doc.exists) {
      // Retourner des valeurs par défaut si les paramètres de l'hôtel n'existent pas
      return {
        'hotelName': 'Hôtel',
        'hotelAddress': '',
        'hotelPhone': '',
        'hotelEmail': '',
        'logoUrl': '',
        'currency': 'FCFA',
        'taxRate': 0.0,
      };
    }

    return doc.data() as Map<String, dynamic>;
  }

  // Générer le document PDF
  static Future<pw.Document> _generateReceipt(
      Map<String, dynamic> bookingData,
      Map<String, dynamic> hotelInfo
      ) async {
    // Créer le document PDF
    final pdf = pw.Document();

    // Formatter les dates
    final checkInDate = (bookingData['checkInDate'] as Timestamp).toDate();
    final checkOutDate = (bookingData['checkOutDate'] as Timestamp).toDate();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Calculer la durée en heures (différence entre checkIn et checkOut)
    final duration = bookingData['hours'] ?? 1;

    // Créer la page de reçu
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // En-tête avec le nom de l'hôtel
              pw.Text(
                hotelInfo['hotelName'] ?? 'HÔTEL',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),

              // Informations de l'hôtel
              if (hotelInfo['hotelAddress'] != null && hotelInfo['hotelAddress'].isNotEmpty)
                pw.Text(
                  hotelInfo['hotelAddress'],
                  style: pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),

              if (hotelInfo['hotelPhone'] != null && hotelInfo['hotelPhone'].isNotEmpty)
                pw.Text(
                  'Tél: ${hotelInfo['hotelPhone']}',
                  style: pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),

              pw.SizedBox(height: 10),

              // Titre du reçu
              pw.Text(
                'REÇU DE PASSAGE',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 5),

              // Ligne de séparation
              pw.Divider(thickness: 1),

              // Numéro de réservation
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('N° Reçu:'),
                  pw.Text(bookingData['EnregistrementCode'] ?? 'N/A'),
                ],
              ),

              // Date d'impression
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:'),
                  pw.Text(dateFormat.format(DateTime.now())),
                ],
              ),

              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),

              // Informations du client
              pw.Text(
                'INFORMATIONS CLIENT',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Nom:'),
                  pw.Text(bookingData['customerName'] ?? 'N/A'),
                ],
              ),

              if (bookingData['customerPhone'] != null && bookingData['customerPhone'].isNotEmpty)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tél:'),
                    pw.Text(bookingData['customerPhone']),
                  ],
                ),

              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),

              // Détails de la chambre
              pw.Text(
                'DÉTAILS DE LA CHAMBRE',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Chambre:'),
                  pw.Text('N° ${bookingData['roomNumber'] ?? 'N/A'}'),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Type:'),
                  pw.Text(bookingData['roomType'] ?? 'N/A'),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Prix horaire:'),
                  pw.Text('${bookingData['roomPrice']?.toStringAsFixed(0) ?? '0'} FCFA'),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Durée:'),
                  pw.Text('$duration ${duration > 1 ? "heures" : "heure"}'),
                ],
              ),

              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),

              // Détails de la réservation
              pw.Text(
                'DÉTAILS DU SÉJOUR',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Arrivée:'),
                  pw.Text(dateFormat.format(checkInDate)),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Départ:'),
                  pw.Text(dateFormat.format(checkOutDate)),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Personnes:'),
                  pw.Text('${bookingData['numberOfGuests'] ?? 1}'),
                ],
              ),

              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),

              // Récapitulatif du paiement
              pw.Text(
                'PAIEMENT',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Montant total:'),
                  pw.Text(
                    '${bookingData['totalAmount']?.toStringAsFixed(0) ?? '0'} FCFA',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Mode de paiement:'),
                  pw.Text('${bookingData['paymentMethod'] ?? 'Non préciser'}'),
                ],
              ),

              pw.SizedBox(height: 15),

              // Message de remerciement
              pw.Text(
                'Merci pour votre visite !',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 5),

              // Date et heure d'impression
              pw.Text(
                'Imprimé le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}

// Écran de prévisualisation du PDF
class _PdfPreviewScreen extends StatelessWidget {
  final pw.Document pdf;
  final String documentName;

  const _PdfPreviewScreen({
    Key? key,
    required this.pdf,
    required this.documentName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prévisualisation du reçu'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => pdf.save(),
                name: documentName,
              );
            },
            tooltip: 'Imprimer',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              // Résoudre le Future pour obtenir les données
              final Uint8List pdfBytes = await pdf.save();

              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: '$documentName.pdf',
              );
            },
            tooltip: 'Partager',
          ),
        ],
      ),
      body: PdfPreview(
        maxPageWidth: 700,
        build: (format) => pdf.save(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
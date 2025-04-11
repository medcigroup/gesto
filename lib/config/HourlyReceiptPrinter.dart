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
        builder: (context) => const Center(
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

    // Définir la taille du ticket 80x80mm
    // La largeur est fixée à 80mm (226.8 points à 72 DPI)
    // La hauteur est variable selon le contenu
    final ticketWidth = 226.8;
    final pageFormat = PdfPageFormat(
      ticketWidth,
      500, // Hauteur initial, sera ajustée automatiquement
      marginAll: 5,
    );

    // Formatter les dates
    final checkInDate = (bookingData['checkInDate'] as Timestamp).toDate();
    final checkOutDate = (bookingData['checkOutDate'] as Timestamp).toDate();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Calculer la durée en heures (différence entre checkIn et checkOut)
    final duration = bookingData['hours'] ?? 1;

    // Créer la page de reçu
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // En-tête avec le nom de l'hôtel
              pw.Text(
                hotelInfo['hotelName'] ?? 'HÔTEL',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),

              // Informations de l'hôtel
              if (hotelInfo['hotelAddress'] != null && hotelInfo['hotelAddress'].isNotEmpty)
                pw.Text(
                  hotelInfo['hotelAddress'],
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),

              if (hotelInfo['hotelPhone'] != null && hotelInfo['hotelPhone'].isNotEmpty)
                pw.Text(
                  'Tél: ${hotelInfo['hotelPhone']}',
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),

              pw.SizedBox(height: 8),

              // Titre du reçu
              pw.Text(
                'REÇU DE PASSAGE',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 3),

              // Ligne de séparation
              pw.Divider(thickness: 0.5),

              // Numéro de réservation
              _buildReceiptRow('N° Reçu:', bookingData['EnregistrementCode'] ?? 'N/A'),

              // Date d'impression
              _buildReceiptRow('Date:', dateFormat.format(DateTime.now())),

              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 3),

              // Informations du client
              pw.Text(
                'INFORMATIONS CLIENT',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              _buildReceiptRow('Nom:', bookingData['customerName'] ?? 'N/A'),

              if (bookingData['customerPhone'] != null && bookingData['customerPhone'].isNotEmpty)
                _buildReceiptRow('Tél:', bookingData['customerPhone']),

              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 3),

              // Détails de la chambre
              pw.Text(
                'DÉTAILS DE LA CHAMBRE',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              _buildReceiptRow('Chambre:', 'N° ${bookingData['roomNumber'] ?? 'N/A'}'),
              _buildReceiptRow('Type:', bookingData['roomType'] ?? 'N/A'),
              _buildReceiptRow('Prix horaire:', '${bookingData['roomPrice']?.toStringAsFixed(0) ?? '0'} FCFA'),
              _buildReceiptRow('Durée:', '$duration ${duration > 1 ? "heures" : "heure"}'),

              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 3),

              // Détails de la réservation
              pw.Text(
                'DÉTAILS DU SÉJOUR',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              _buildReceiptRow('Arrivée:', dateFormat.format(checkInDate)),
              _buildReceiptRow('Départ:', dateFormat.format(checkOutDate)),
              _buildReceiptRow('Personnes:', '${bookingData['numberOfGuests'] ?? 1}'),

              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 3),

              // Récapitulatif du paiement
              pw.Text(
                'PAIEMENT',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              _buildReceiptRow(
                'Montant total:',
                '${bookingData['totalAmount']?.toStringAsFixed(0) ?? '0'} FCFA',
                bold: true,
              ),

              _buildReceiptRow(
                'Mode de paiement:',
                '${bookingData['paymentMethod'] ?? 'Non précisé'}',
              ),

              pw.SizedBox(height: 10),

              // Message de remerciement
              pw.Text(
                'Merci pour votre visite !',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 5),

              // Date et heure d'impression
              pw.Text(
                'Imprimé le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 6),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Méthode utilitaire pour créer une ligne de reçu avec label et valeur
  static pw.Widget _buildReceiptRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: bold ? pw.FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
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
        title: const Text('Prévisualisation du reçu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              // Configurer pour impression de ticket
              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => pdf.save(),
                name: documentName,
                // Format optimisé pour les tickets
                format: PdfPageFormat(226.8, 0, marginAll: 5),
              );
            },
            tooltip: 'Imprimer',
          ),
          IconButton(
            icon: const Icon(Icons.share),
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
        maxPageWidth: 300, // Limite la largeur de prévisualisation
        build: (format) => pdf.save(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfPreviewPageDecoration: const BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }
}
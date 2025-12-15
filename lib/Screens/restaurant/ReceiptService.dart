import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
// Pour Flutter Web
import 'dart:html' as html;

import '../../config/restaurant_models.dart';

class ReceiptService {
  // Format ticket thermique 80mm
  static final PdfPageFormat ticketFormat = PdfPageFormat(
    80 * PdfPageFormat.mm,
    double.infinity, // Hauteur automatique
    marginAll: 5 * PdfPageFormat.mm,
  );

  /// Génère un reçu de facturation au format ticket thermique
  static Future<void> generateReceipt({
    required RestaurantOrder order,
    required String restaurantName,
    required String? restaurantAddress,
    required String? restaurantPhone,
    required String? staffName,
    bool autoPrint = false,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: ticketFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // En-tête Restaurant
              _buildHeader(restaurantName, restaurantAddress, restaurantPhone),

              pw.SizedBox(height: 10),
              _buildDivider(),
              pw.SizedBox(height: 10),

              // Informations commande
              _buildOrderInfo(order),

              pw.SizedBox(height: 10),
              _buildDivider(),
              pw.SizedBox(height: 10),

              // Articles
              _buildItemsList(order.items),

              pw.SizedBox(height: 10),
              _buildDivider(),
              pw.SizedBox(height: 10),

              // Totaux
              _buildTotals(order),

              pw.SizedBox(height: 10),
              _buildDivider(),
              pw.SizedBox(height: 10),

              // Paiement
              _buildPaymentInfo(order, staffName),

              pw.SizedBox(height: 15),

              // Pied de page
              _buildFooter(),
            ],
          );
        },
      ),
    );

    // Télécharger ou imprimer
    if (autoPrint) {
      await _printReceipt(pdf, order);
    } else {
      await _downloadReceipt(pdf, order);
    }
  }

  static pw.Widget _buildHeader(String name, String? address, String? phone) {
    return pw.Column(
      children: [
        pw.Text(
          name.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
          textAlign: pw.TextAlign.center,
        ),
        if (address != null) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            address,
            style: pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ],
        if (phone != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            'Tél: $phone',
            style: pw.TextStyle(fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Container(
      width: double.infinity,
      height: 1,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.black,
            width: 0.5,
            style: pw.BorderStyle.dashed,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildOrderInfo(RestaurantOrder order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Reçu N°:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text(
              order.id.substring(0, 8).toUpperCase(),
              style: pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Date:', style: pw.TextStyle(fontSize: 9)),
            pw.Text(
              DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
              style: pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Table:', style: pw.TextStyle(fontSize: 9)),
            pw.Text(
              order.tableNumber,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        if (order.guestName != null) ...[
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Client:', style: pw.TextStyle(fontSize: 9)),
              pw.Text(
                order.guestName!,
                style: pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],
        if (order.roomNumber != null) ...[
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Chambre:', style: pw.TextStyle(fontSize: 9)),
              pw.Text(
                order.roomNumber!,
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
        if (order.isRoomService == true) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            '** SERVICE EN CHAMBRE **',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildItemsList(List<OrderItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                'Article',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text(
                'Qté',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Prix',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 5),

        // Articles
        ...items.map((item) {
          return pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      item.name,
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      '${item.quantity}',
                      style: pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '${item.totalPrice.toStringAsFixed(0)} F',
                      style: pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              if (item.specialInstructions != null && item.specialInstructions!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Padding(
                  padding: pw.EdgeInsets.only(left: 5),
                  child: pw.Text(
                    '  → ${item.specialInstructions}',
                    style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
              pw.SizedBox(height: 4),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTotals(RestaurantOrder order) {
    return pw.Column(
      children: [
        // Sous-total
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Sous-total:', style: pw.TextStyle(fontSize: 9)),
            pw.Text(
              '${order.subtotal.toStringAsFixed(0)} FCFA',
              style: pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 3),

        // TVA
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TVA (${(order.tax / order.subtotal * 100).toStringAsFixed(0)}%):',
              style: pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              '${order.tax.toStringAsFixed(0)} FCFA',
              style: pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 3),

        // Service
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Service (${(order.serviceCharge / order.subtotal * 100).toStringAsFixed(0)}%):',
              style: pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              '${order.serviceCharge.toStringAsFixed(0)} FCFA',
              style: pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.SizedBox(height: 8),

        // Total
        pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: 5),
          decoration: pw.BoxDecoration(
            border: pw.Border.symmetric(
              horizontal: pw.BorderSide(width: 1, color: PdfColors.black),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL À PAYER:',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                '${order.total.toStringAsFixed(0)} F',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPaymentInfo(RestaurantOrder order, String? staffName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Mode de paiement:', style: pw.TextStyle(fontSize: 9)),
            pw.Text(
              order.paymentMethod.toUpperCase(),
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        if (order.completedAt != null) ...[
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Payé le:', style: pw.TextStyle(fontSize: 9)),
              pw.Text(
                DateFormat('dd/MM/yyyy HH:mm').format(order.completedAt!),
                style: pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],
        if (staffName != null) ...[
          pw.SizedBox(height: 3),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Servi par:', style: pw.TextStyle(fontSize: 9)),
              pw.Text(
                staffName,
                style: pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ],
        if (order.specialRequests != null && order.specialRequests!.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Text(
            'Note: ${order.specialRequests}',
            style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Text(
          '** MERCI DE VOTRE VISITE **',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'À bientôt !',
          style: pw.TextStyle(fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Document non contractuel',
          style: pw.TextStyle(fontSize: 7),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
          style: pw.TextStyle(fontSize: 7),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Imprime le reçu (pour Flutter Web, ouvre le dialogue d'impression)
  static Future<void> _printReceipt(pw.Document pdf, RestaurantOrder order) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Recu_${order.id.substring(0, 8)}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
        format: ticketFormat,
      );
    } catch (e) {
      print('❌ Erreur impression reçu: $e');
      throw Exception('Erreur lors de l\'impression du reçu');
    }
  }

  /// Télécharge le reçu (Flutter Web)
  static Future<void> _downloadReceipt(pw.Document pdf, RestaurantOrder order) async {
    try {
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute(
          'download',
          'Recu_${order.id.substring(0, 8)}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
        )
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('❌ Erreur téléchargement reçu: $e');
      throw Exception('Erreur lors du téléchargement du reçu');
    }
  }

  /// Génère un reçu avec informations du serveur
  static Future<void> generateReceiptWithStaff({
    required RestaurantOrder order,
    required String restaurantName,
    String? restaurantAddress,
    String? restaurantPhone,
    String? waiterId,
    bool autoPrint = false,
  }) async {
    String? staffName;

    // Récupérer le nom du serveur si waiterId fourni
    if (waiterId != null && waiterId.isNotEmpty) {
      try {
        final staffDoc = await RestaurantService.getStaffInfo(waiterId);
        if (staffDoc != null) {
          staffName = '${staffDoc['prenom']} ${staffDoc['nom']}';
        }
      } catch (e) {
        print('⚠️ Impossible de récupérer les infos du serveur: $e');
      }
    }

    await generateReceipt(
      order: order,
      restaurantName: restaurantName,
      restaurantAddress: restaurantAddress,
      restaurantPhone: restaurantPhone,
      staffName: staffName,
      autoPrint: autoPrint,
    );
  }
}

// Extension du RestaurantService pour récupérer les infos du personnel
extension RestaurantServiceStaffExtension on RestaurantService {
  static Future<Map<String, dynamic>?> getStaffInfo(String staffId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('staff')
          .doc(staffId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('❌ Erreur récupération info staff: $e');
    }
    return null;
  }
}
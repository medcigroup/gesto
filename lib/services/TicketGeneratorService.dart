import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/OptionPurchase.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class TicketGeneratorService {
  // Format 80mm x longueur variable
  static const double ticketWidth = 80 * PdfPageFormat.mm;
  
  /// Génère un ticket pour l'achat d'options
  static Future<Uint8List> generateOptionTicket(OptionPurchase purchase) async {
    final pdf = pw.Document();
    
    // Format 80mm de largeur
    final pageFormat = PdfPageFormat(
      ticketWidth,
      double.infinity, // Hauteur variable selon le contenu
      marginAll: 5 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête avec nom de l'hôtel
              _buildHeader(purchase),
              
              pw.SizedBox(height: 10),
              
              // Ligne de séparation
              pw.Divider(thickness: 2),
              
              pw.SizedBox(height: 10),
              
              // Titre
              pw.Center(
                child: pw.Text(
                  'TICKET D\'ACHAT',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 5),
              
              pw.Center(
                child: pw.Text(
                  'Options Hôtel',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              pw.Divider(),
              
              // Informations de transaction
              _buildTransactionInfo(purchase),
              
              pw.SizedBox(height: 10),
              
              // Informations client
              _buildClientInfo(purchase),
              
              pw.SizedBox(height: 10),
              
              pw.Divider(),
              
              // Liste des options
              _buildOptionsList(purchase),
              
              pw.SizedBox(height: 10),
              
              pw.Divider(thickness: 2),
              
              // Total
              _buildTotal(purchase),
              
              pw.SizedBox(height: 10),
              
              pw.Divider(),
              
              // Pied de page
              _buildFooter(purchase),
              
              pw.SizedBox(height: 15),
              
              // Code-barres ou QR code (optionnel)
              pw.Center(
                child: pw.BarcodeWidget(
                  data: purchase.id,
                  barcode: pw.Barcode.code128(),
                  width: ticketWidth - 20,
                  height: 40,
                ),
              ),
              
              pw.SizedBox(height: 5),
              
              pw.Center(
                child: pw.Text(
                  purchase.id.substring(0, 12).toUpperCase(),
                  style: pw.TextStyle(fontSize: 8),
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              // Message de remerciement
              pw.Center(
                child: pw.Text(
                  'Merci de votre confiance !',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 5),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(OptionPurchase purchase) {
    print('📄 Génération header avec hotelName: ${purchase.hotelName}');
    
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            purchase.hotelName?.toUpperCase() ?? 'GESTO HOTEL',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            'Système de gestion hôtelière',
            style: pw.TextStyle(fontSize: 9),
          ),
        ),
        pw.SizedBox(height: 8),
        // Afficher les options achetées en haut
        pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Options achetées:',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              ...purchase.purchasedOptions.map((option) {
                return pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(
                    '• ${option.packageName} (x${option.quantity})',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionInfo(OptionPurchase purchase) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INFORMATIONS DE TRANSACTION',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        _buildInfoRow('N° Transaction', purchase.id.substring(0, 8).toUpperCase()),
        _buildInfoRow('Date', dateFormat.format(purchase.purchaseDate)),
        _buildInfoRow('Statut', purchase.status.toUpperCase()),
        if (purchase.bookingId != null)
          _buildInfoRow('N° Réservation', purchase.bookingId!.substring(0, 8).toUpperCase()),
      ],
    );
  }

  static pw.Widget _buildClientInfo(OptionPurchase purchase) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INFORMATIONS CLIENT',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        _buildInfoRow('Nom', purchase.customerName),
        _buildInfoRow('Email', purchase.customerEmail),
        _buildInfoRow('Téléphone', purchase.customerPhone),
        if (purchase.roomNumber != null && purchase.roomNumber!.isNotEmpty)
          _buildInfoRow('Chambre', purchase.roomNumber!),
      ],
    );
  }

  static pw.Widget _buildOptionsList(OptionPurchase purchase) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'OPTIONS ACHETÉES',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        
        // En-tête du tableau
        pw.Container(
          padding: pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'Option',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Text(
                  'Prix',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        
        // Liste des options
        ...purchase.purchasedOptions.map((purchasedOption) {
          final option = purchasedOption.package;
          final periodLabel = _getPeriodLabel(purchasedOption.period);
          
          return pw.Container(
            padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        option.name,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (option.description.isNotEmpty)
                        pw.Text(
                          option.description,
                          style: pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.grey700,
                          ),
                          maxLines: 2,
                        ),
                      pw.Text(
                        '${purchasedOption.unitPrice.toStringAsFixed(0)} F/$periodLabel × ${purchasedOption.quantity}',
                        style: pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    '${purchasedOption.subtotal.toStringAsFixed(0)} F',
                    style: pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTotal(OptionPurchase purchase) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TOTAL',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              '${purchase.totalAmount.toStringAsFixed(0)} FCFA',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Mode de paiement',
              style: pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              purchase.paymentMethod,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(OptionPurchase purchase) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            'Ticket non fiscal',
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Center(
          child: pw.Text(
            'Conservez ce ticket',
            style: pw.TextStyle(fontSize: 8),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.Container(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _getPeriodLabel(String period) {
    switch (period) {
      case 'hour':
        return 'h';
      case 'day':
        return 'j';
      case 'week':
        return 'sem';
      case 'month':
        return 'mois';
      default:
        return 'j';
    }
  }

  /// Imprimer le ticket
  static Future<void> printTicket(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
    );
  }

  /// Sauvegarder et partager le ticket
  static Future<void> saveAndShareTicket(Uint8List pdfBytes, String purchaseId) async {
    try {
      // Obtenir le répertoire temporaire
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/ticket_${purchaseId.substring(0, 8)}.pdf';
      
      // Sauvegarder le fichier
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      // Partager le fichier
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Ticket d\'achat - Options Hôtel',
        text: 'Voici votre ticket d\'achat pour les options sélectionnées.',
      );
    } catch (e) {
      print('❌ Erreur lors du partage du ticket: $e');
      throw e;
    }
  }

  /// Afficher l'aperçu du ticket
  static Future<void> showTicketPreview(BuildContext context, Uint8List pdfBytes) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Aperçu du ticket'),
            actions: [
              IconButton(
                icon: Icon(Icons.print),
                onPressed: () => printTicket(pdfBytes),
              ),
            ],
          ),
          body: PdfPreview(
            build: (format) => pdfBytes,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
          ),
        ),
      ),
    );
  }

  /// Générer un ticket simple (format texte pour imprimantes thermiques)
  static String generateSimpleTextTicket(OptionPurchase purchase) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final buffer = StringBuffer();
    
    // En-tête
    buffer.writeln('================================');
    buffer.writeln('       GESTO HOTEL');
    buffer.writeln('  Système de gestion hôtelière');
    buffer.writeln('================================');
    buffer.writeln();
    buffer.writeln('     TICKET D\'ACHAT');
    buffer.writeln('      Options Hôtel');
    buffer.writeln();
    buffer.writeln('--------------------------------');
    
    // Transaction
    buffer.writeln('TRANSACTION');
    buffer.writeln('N°: ${purchase.id.substring(0, 8).toUpperCase()}');
    buffer.writeln('Date: ${dateFormat.format(purchase.purchaseDate)}');
    buffer.writeln('Statut: ${purchase.status.toUpperCase()}');
    if (purchase.bookingId != null) {
      buffer.writeln('Réservation: ${purchase.bookingId!.substring(0, 8).toUpperCase()}');
    }
    buffer.writeln();
    
    // Client
    buffer.writeln('CLIENT');
    buffer.writeln('Nom: ${purchase.customerName}');
    buffer.writeln('Email: ${purchase.customerEmail}');
    buffer.writeln('Tél: ${purchase.customerPhone}');
    if (purchase.roomNumber != null && purchase.roomNumber!.isNotEmpty) {
      buffer.writeln('Chambre: ${purchase.roomNumber}');
    }
    buffer.writeln();
    buffer.writeln('--------------------------------');
    
    // Options
    buffer.writeln('OPTIONS ACHETÉES');
    buffer.writeln('--------------------------------');
    for (var purchasedOption in purchase.purchasedOptions) {
      final option = purchasedOption.package;
      final periodLabel = _getPeriodLabel(purchasedOption.period);
      buffer.writeln(option.name);
      buffer.writeln('  ${purchasedOption.unitPrice.toStringAsFixed(0)} FCFA/$periodLabel × ${purchasedOption.quantity}');
      buffer.writeln('  Sous-total: ${purchasedOption.subtotal.toStringAsFixed(0)} FCFA');
      if (option.description.isNotEmpty) {
        buffer.writeln('  ${option.description}');
      }
      buffer.writeln();
    }
    buffer.writeln('--------------------------------');
    
    // Total
    buffer.writeln('TOTAL: ${purchase.totalAmount.toStringAsFixed(0)} FCFA');
    buffer.writeln('Paiement: ${purchase.paymentMethod}');
    buffer.writeln('================================');
    buffer.writeln();
    buffer.writeln('    Merci de votre confiance !');
    buffer.writeln('     Conservez ce ticket');
    buffer.writeln();
    buffer.writeln('================================');
    
    return buffer.toString();
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class LicencePrinter {
  // Fonction principale pour imprimer une licence
  static Future<void> printLicence(BuildContext context, Map<String, dynamic> licenceData) async {
    final pdf = await _generateLicencePdf(licenceData);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf,
      name: 'Licence_${licenceData['code']}.pdf',
    );
  }

  // Fonction pour générer le PDF de la licence
  static Future<Uint8List> _generateLicencePdf(Map<String, dynamic> licenceData) async {
    final pdf = pw.Document();

    // Utilisation des polices par défaut (pas besoin de charger des polices Google)
    final regularFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();
    final italicFont = pw.Font.helveticaOblique();

    // Formatage des dates
    final dateFormat = DateFormat('dd/MM/yyyy');
    final generationDate = licenceData['generationDate'] as DateTime;
    final expiryDate = licenceData['expiryDate'] as DateTime;

    // Déterminer si la licence est expirée
    final isExpired = DateTime.now().isAfter(expiryDate);
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;

    // Créer une image placeholder au lieu d'essayer de la charger depuis internet
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    // Si vous n'avez pas d'image locale, utilisez un placeholder
    // final logoBytes = await createImagePlaceholder();
    // final logoImage = pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Placeholder de texte au lieu d'image si vous n'avez pas d'image locale
                    pw.Container(
                      width: 150,
                      height: 75,
                      color: PdfColors.blue300,
                      alignment: pw.Alignment.center,
                      child: pw.Text('ARKADIA DEV', style: pw.TextStyle(color: PdfColors.white)),
                    ),
                    // Ou utilisez logoImage si vous en avez un
                    // pw.Image(logoImage, width: 150, height: 75),

                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('GESTO LICENCE', style: pw.TextStyle(font: boldFont, fontSize: 22, color: PdfColors.blue800)),
                        pw.SizedBox(height: 5),
                        pw.Text('ARKADIA DEV', style: pw.TextStyle(font: boldFont, fontSize: 14)),
                        pw.Text('Email: contact@app.gestoapp.cloud', style: pw.TextStyle(font: regularFont, fontSize: 10)),
                        pw.Text('Tel: 0701997478', style: pw.TextStyle(font: regularFont, fontSize: 10)),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Séparateur
                pw.Divider(color: PdfColors.blue200, thickness: 1),

                pw.SizedBox(height: 20),

                // Information sur le statut
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: isExpired ? PdfColors.red50 : PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        isExpired ? 'LICENCE EXPIRÉE' : 'LICENCE VALIDE',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 16,
                          color: isExpired ? PdfColors.red800 : PdfColors.green800,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      if (!isExpired)
                        pw.Text(
                          '($daysLeft jours restants)',
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 12,
                            color: PdfColors.green800,
                          ),
                        ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Informations principales
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue100),
                    borderRadius: pw.BorderRadius.circular(5),
                    color: PdfColors.blue50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Code de licence:', licenceData['code'], boldFont, regularFont),
                      pw.SizedBox(height: 15),
                      _buildInfoRow('Type de licence:', licenceData['licenceType']?.toUpperCase() ?? 'NON SPÉCIFIÉ', boldFont, regularFont),
                      pw.SizedBox(height: 10),
                      _buildInfoRow('Type de période:', _formatPeriodType(licenceData['periodeType'] ?? ''), boldFont, regularFont),
                      pw.SizedBox(height: 10),
                      _buildInfoRow('Date de génération:', dateFormat.format(generationDate), boldFont, regularFont),
                      pw.SizedBox(height: 10),
                      _buildInfoRow('Date d\'expiration:', dateFormat.format(expiryDate), boldFont, regularFont),
                      pw.SizedBox(height: 10),
                      _buildInfoRow('Durée totale:', '${expiryDate.difference(generationDate).inDays} jours', boldFont, regularFont),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Conditions d'utilisation
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CONDITIONS D\'UTILISATION', style: pw.TextStyle(font: boldFont, fontSize: 12)),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Cette licence est soumise aux termes et conditions d\'ARKADIA DEV. '
                            'La licence est transférable, cependant ne peut être utilisée que pour le produit spécifié. '
                            'Toute reproduction ou distribution non autorisée est strictement interdite.',
                        style: pw.TextStyle(font: italicFont, fontSize: 9),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Pied de page
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(font: italicFont, fontSize: 8, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Powered by ARKADIA DEV',
                      style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.blue800),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Fonction utilitaire pour formater les types de période
  static String _formatPeriodType(String periodeType) {
    switch (periodeType.toLowerCase()) {
      case 'month':
        return 'Mensuelle';
      case '6months':
        return 'Semestrielle';
      case 'year':
        return 'Annuelle';
      default:
        return periodeType;
    }
  }

  // Fonction utilitaire pour construire une ligne d'information
  static pw.Widget _buildInfoRow(String label, String value, pw.Font boldFont, pw.Font regularFont) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.blue900),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: regularFont, fontSize: 11),
          ),
        ),
      ],
    );
  }

}
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'HotelSettingsService.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final HotelSettingsService _hotelSettingsService = HotelSettingsService();

  // Méthode pour récupérer les transactions sur une période
  Future<List<Map<String, dynamic>>> loadTransactionsForDateRange(DateTime start, DateTime end) async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    try {
      // Créer les limites de début et fin de journée
      final DateTime startOfDay = DateTime(start.year, start.month, start.day);
      final DateTime endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

      print('Chargement des transactions entre $startOfDay et $endOfDay');

      // Récupérer toutes les transactions
      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('customerId', isEqualTo: currentUser.uid)
          .get();

      print('Nombre total de transactions récupérées: ${snapshot.docs.length}');

      List<Map<String, dynamic>> filteredTransactions = [];

      // Filtrer les transactions par date côté client
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ajouter l'ID du document

        // Vérifier si la transaction a une date
        if (data.containsKey('date') && data['date'] != null) {
          final DateTime transactionDate = (data['date'] as Timestamp).toDate();

          // Vérifier si la date est dans la plage
          if ((transactionDate.isAtSameMomentAs(startOfDay) || transactionDate.isAfter(startOfDay)) &&
              (transactionDate.isAtSameMomentAs(endOfDay) || transactionDate.isBefore(endOfDay))) {
            filteredTransactions.add(data);
            print('Transaction ajoutée: ${data['description']} - ${transactionDate}');
          }
        }
      }

      print('Nombre de transactions filtrées: ${filteredTransactions.length}');
      return filteredTransactions;
    } catch (e) {
      print('Erreur lors de la récupération des transactions pour la période: $e');
      throw e;
    }
  }

  // Méthode directe pour générer et imprimer le rapport
  Future<void> generateAndPrintReport(List<Map<String, dynamic>> transactions, DateTime startDate, DateTime endDate) async {
    try {
      print('Démarrage de la génération du rapport avec ${transactions.length} transactions');

      if (transactions.isEmpty) {
        print('Aucune transaction à imprimer');
        throw Exception('Aucune transaction disponible pour la période sélectionnée');
      }

      // Récupérer les informations de l'hôtel depuis HotelSettingsService
      final hotelSettings = await _hotelSettingsService.getHotelSettings();

      // Extraire les informations de l'hôtel avec des valeurs par défaut si non disponibles
      final hotelName = hotelSettings['hotelName'] ?? "DEPARU HOTEL";
      final hotelAddress = hotelSettings['address'] ?? "123 Rue Principale, Ville, Pays";
      final hotelPhone = hotelSettings['phoneNumber'] ?? "+123 456 7890";
      final hotelEmail = hotelSettings['email'] ?? "contact@deparuhotel.com";
      final currency = hotelSettings['currency'] ?? "FCFA";

      print('Informations de l\'hôtel récupérées: $hotelName, $hotelAddress, $hotelPhone');

      // Calculer les totaux pour le rapport
      double totalRevenue = 0;
      Set<String> uniqueRooms = {};

      for (var transaction in transactions) {
        if (transaction['type'] == 'payment' && transaction.containsKey('amount')) {
          totalRevenue += (transaction['amount'] as num).toDouble();
        }

        if (transaction.containsKey('roomId') &&
            transaction['roomId'] != null &&
            transaction['roomId'] != '') {
          uniqueRooms.add(transaction['roomId'] as String);
        }
      }

      double revenuePerRoom = uniqueRooms.isEmpty ? 0 : totalRevenue / uniqueRooms.length;
      print('Total des revenus: $totalRevenue $currency, Nombre de chambres: ${uniqueRooms.length}, Revenu par chambre: $revenuePerRoom $currency');

      // Créer le document PDF directement et l'imprimer en une étape
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();

          pdf.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(32),
              header: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(hotelName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text(hotelAddress, style: pw.TextStyle(fontSize: 10)),
                          pw.Text('Tél: $hotelPhone', style: pw.TextStyle(fontSize: 10)),
                          pw.Text('Email: $hotelEmail', style: pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 8),
                          pw.Text('RAPPORT FINANCIER', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Période: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.Divider(),
                  ],
                );
              },
              build: (pw.Context context) {
                return [
                  // Résumé financier
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Résumé Financier', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Revenu Total:'),
                            pw.Text('${NumberFormat.currency(symbol: '$currency ', decimalDigits: 0).format(totalRevenue)}',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Chambres Occupées:'),
                            pw.Text('${uniqueRooms.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Revenu par Chambre:'),
                            pw.Text('${NumberFormat.currency(symbol: '$currency ', decimalDigits: 0).format(revenuePerRoom)}',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Liste des transactions
                  pw.Text('Liste des Transactions', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),

                  // En-têtes de table
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey700),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      // En-tête
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Client', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Montant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),

                      // Lignes de données
                      ...transactions.map((transaction) {
                        final DateTime date = (transaction['date'] as Timestamp).toDate();
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(transaction['description'] ?? 'N/A'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(date)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(transaction['customerName'] ?? 'N/A'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                NumberFormat.currency(symbol: '$currency ', decimalDigits: 0).format(transaction['amount'] ?? 0),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ];
              },
              footer: (pw.Context context) {
                return pw.Column(
                  children: [
                    pw.Divider(),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Rapport généré le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 8)),
                        pw.Text('Page ${context.pageNumber} sur ${context.pagesCount}', style: pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Center(
                      child: pw.Text('Ce document est généré automatiquement et ne nécessite pas de signature.', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                    ),
                  ],
                );
              },
            ),
          );

          print('Génération du PDF terminée, envoi vers l\'impression...');
          return pdf.save();
        },
        name: 'Rapport_Financier_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}',
      );

      print('Impression terminée avec succès');
    } catch (e) {
      print('Erreur lors de la génération ou de l\'impression du rapport: $e');
      // On relance l'erreur pour que l'interface puisse la gérer
      throw e;
    }
  }
}
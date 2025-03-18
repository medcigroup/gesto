import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PrinterService {
  Future<void> printReservationReceipt({
    required Map<String, dynamic> reservationData,
    required String reservationCode,
    required Map<String, dynamic> hotelSettings,
  }) async {
    try {
      final pdf = pw.Document();

      // Récupérer le nom et le logo de l'hôtel depuis les paramètres
      final hotelName = hotelSettings['hotelName'] ?? 'Hôtel';
      final hotelAddress = hotelSettings['address'] ?? '';
      final hotelPhone = hotelSettings['phoneNumber'] ?? '';
      final hotelEmail = hotelSettings['email'] ?? '';
      final hotelcurrency = hotelSettings['currency'] ?? '';

      // Formater les dates pour l'affichage
      final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

      // Vérifier que les dates ne sont pas null avant d'appeler toDate()
      final checkInFormatted = reservationData['checkInDate'] != null
          ? dateFormatter.format(reservationData['checkInDate'])
          : 'Non spécifiée';

      final checkOutFormatted = reservationData['checkOutDate'] != null
          ? dateFormatter.format(reservationData['checkOutDate'])
          : 'Non spécifiée';

      // Créer le PDF du reçu
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(hotelName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text(hotelAddress),
                      pw.Text('Tél: $hotelPhone | Email: $hotelEmail'),
                      pw.SizedBox(height: 20),
                      pw.Text('REÇU DE RÉSERVATION', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text('Code de réservation: $reservationCode', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                    ],
                  ),
                ),

                // Informations client
                pw.Text('Informations du client:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Nom:'),
                      pw.Text(reservationData['customerName'] ?? 'Non spécifié'),
                    ]
                ),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Email:'),
                      pw.Text(reservationData['customerEmail'] ?? 'Non spécifié'),
                    ]
                ),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Téléphone:'),
                      pw.Text(reservationData['customerPhone'] ?? 'Non spécifié'),
                    ]
                ),
                pw.SizedBox(height: 20),

                // Détails de la réservation
                pw.Text('Détails de la réservation:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Numéro de chambre:'),
                      pw.Text((reservationData['roomNumber'] ?? 'Non spécifié').toString()),
                    ]
                ),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Type de chambre:'),
                      pw.Text(reservationData['roomType'] ?? 'Non spécifié'),
                    ]
                ),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Date d\'arrivée:'),
                      pw.Text(checkInFormatted),
                    ]
                ),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Date de départ:'),
                      pw.Text(checkOutFormatted),
                    ]
                ),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Nombre de nuits:'),
                      pw.Text((reservationData['numberOfNights'] ?? 0).toString()),
                    ]
                ),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Nombre de personnes:'),
                      pw.Text((reservationData['numberOfGuests'] ?? 0).toString()),
                    ]
                ),
                pw.SizedBox(height: 20),

                // Détails du prix
                pw.Text('Détails du prix:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Prix par nuit:'),
                      pw.Text('${reservationData['pricePerNight'] ?? 0} $hotelcurrency'),
                    ]
                ),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Prix total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${reservationData['totalPrice'] ?? 0} $hotelcurrency', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ]
                ),
                pw.SizedBox(height: 20),

                // Demandes spéciales
                if (reservationData['specialRequests'] != null && reservationData['specialRequests'].toString().isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Demandes spéciales:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Divider(),
                      pw.Text(reservationData['specialRequests']),
                      pw.SizedBox(height: 20),
                    ],
                  ),

                // Pied de page
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('Merci d\'avoir choisi $hotelName!'),
                      pw.SizedBox(height: 5),
                      pw.Text('Date d\'émission: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Imprimer le PDF ou le sauvegarder selon les besoins
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Reservation_${reservationCode}_${reservationData['customerName'] ?? "client"}.pdf',
      );

    } catch (e) {
      print('Erreur lors de l\'impression du reçu: ${e.toString()}');
      // Vous pouvez également propager l'erreur ou utiliser un service de logging
      rethrow;
    }
  }
}
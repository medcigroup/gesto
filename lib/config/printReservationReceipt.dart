import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrinterService {
  Future<void> printReservationReceipt({
    required Map<String, dynamic> reservationData,
    required String reservationCode,
    required Map<String, dynamic> hotelSettings,
  }) async {
    try {
      // Vérifier la présence de l'ID de chambre et récupérer les commodités
      String? roomId = reservationData['roomId'] as String?;
      List<String> amenities = [];

      if (roomId != null && roomId.isNotEmpty) {
        amenities = await _fetchRoomAmenities(roomId);
      } else {
        print('Attention: roomId est null ou vide');
        print('Type of roomId: ${reservationData['roomId']?.runtimeType}');
        print('Value of roomId: ${reservationData['roomId']}');
        print('All reservationData keys: ${reservationData.keys.toList()}');
      }

      final pdf = pw.Document();

      // Récupérer les informations de l'hôtel avec des valeurs par défaut
      final hotelName = hotelSettings['hotelName'] ?? 'Hôtel';
      final hotelAddress = hotelSettings['address'] ?? '';
      final hotelPhone = hotelSettings['phoneNumber'] ?? '';
      final hotelEmail = hotelSettings['email'] ?? '';
      final hotelCurrency = hotelSettings['currency'] ?? 'FCFA';
      final depositPercentage = hotelSettings['depositPercentage'] ?? 30;

      // Formater les dates avec gestion des nulls
      final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
      final dateFormatterShort = DateFormat('dd/MM/yyyy');

      final checkInDate = reservationData['checkInDate'];
      final checkOutDate = reservationData['checkOutDate'];

      final checkInFormatted = checkInDate != null
          ? dateFormatter.format(checkInDate)
          : 'Non spécifiée';

      final checkOutFormatted = checkOutDate != null
          ? dateFormatter.format(checkOutDate)
          : 'Non spécifiée';

      // Format court pour l'affichage dans les détails
      final checkInShort = checkInDate != null
          ? dateFormatterShort.format(checkInDate)
          : 'Non spécifiée';

      final checkOutShort = checkOutDate != null
          ? dateFormatterShort.format(checkOutDate)
          : 'Non spécifiée';

      // Convertir toutes les valeurs en types sûrs pour éviter les erreurs null
      final roomNumber = reservationData['roomNumber']?.toString() ?? 'N/A';
      final roomType = reservationData['roomType']?.toString() ?? 'N/A';
      final customerName = reservationData['customerName']?.toString() ?? 'Non spécifié';
      final customerPhone = reservationData['customerPhone']?.toString() ?? 'Non spécifié';
      final customerEmail = reservationData['customerEmail']?.toString() ?? 'Non spécifié';
      final numberOfNights = reservationData['numberOfNights'] ?? 0;
      final numberOfGuests = reservationData['numberOfGuests'] ?? 0;
      final pricePerNight = reservationData['pricePerNight'] ?? 0;
      final totalPrice = reservationData['totalPrice'] ?? 0;

      // Vérifier si les demandes spéciales existent et ne sont pas vides
      final specialRequests = reservationData['specialRequests'];
      final hasSpecialRequests = specialRequests != null &&
          specialRequests.toString().trim().isNotEmpty;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
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
                        pw.Text(hotelName,
                            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(hotelAddress, style: pw.TextStyle(fontSize: 10)),
                        pw.Text('Tél: $hotelPhone', style: pw.TextStyle(fontSize: 10)),
                        pw.Text('Email: $hotelEmail', style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 8),
                        pw.Text('REÇU DE RÉSERVATION',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Divider(thickness: 1),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 5),

                  // Informations de base
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Code de réservation:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(reservationCode),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Date d\'émission:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Client:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(customerName),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Téléphone:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(customerPhone),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Email:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(customerEmail),
                    ],
                  ),

                  pw.SizedBox(height: 10),

                  // Détails de la réservation (dans un conteneur avec bordure)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      border: pw.Border.all(width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Détails de la réservation',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Période:'),
                            pw.Text('$checkInShort - $checkOutShort'),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Nombre de nuits:'),
                            pw.Text('$numberOfNights'),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Nombre de personnes:'),
                            pw.Text('$numberOfGuests'),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Tarif par nuit:'),
                            pw.Text(
                                NumberFormat.currency(
                                    symbol: '$hotelCurrency ',
                                    decimalDigits: 0
                                ).format(pricePerNight)
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // Détails de la chambre
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      border: pw.Border.all(width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Détails de la chambre',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Chambre:'),
                            pw.Text('N°$roomNumber ($roomType)'),
                          ],
                        ),
                        if (amenities.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text('Commodités:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 3),
                          // Wrap pour présenter les commodités horizontalement
                          pw.Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: amenities.map((amenity) {
                              return pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.grey300,
                                  borderRadius: pw.BorderRadius.circular(5),
                                ),
                                child: pw.Text(
                                  amenity,
                                  style: pw.TextStyle(color: PdfColors.black, fontSize: 9),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  // Détails du prix
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      border: pw.Border.all(width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Détails du prix',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Prix par nuit:'),
                            pw.Text(
                                NumberFormat.currency(
                                    symbol: '$hotelCurrency ',
                                    decimalDigits: 0
                                ).format(pricePerNight)
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        // Ajouter d'autres détails de prix si nécessaire (taxes, etc.)
                        // ...
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Prix total:',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text(
                              NumberFormat.currency(
                                  symbol: '$hotelCurrency ',
                                  decimalDigits: 0
                              ).format(totalPrice),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),

                  // Demandes spéciales
                  if (hasSpecialRequests) ...[
                    pw.SizedBox(height: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                        border: pw.Border.all(width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Demandes spéciales:',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 5),
                          pw.Text(specialRequests.toString()),
                        ],
                      ),
                    ),
                  ],

                  pw.SizedBox(height: 15),

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
                            height: 40,
                            decoration: pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(width: 1)),
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Signature Client',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),

                      // Signature Réceptionniste
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 150,
                            height: 40,
                            decoration: pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(width: 1)),
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Signature Réceptionniste',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 15),

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
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Ce reçu fait office de confirmation de réservation.',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Pour toute annulation ou modification, veuillez consulter notre politique d\'annulation.',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Nous vous souhaitons un agréable séjour !',
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
        name: 'Reservation_${reservationCode}_${customerName}.pdf',
      );

    } catch (e) {
      print('Erreur lors de l\'impression du reçu: ${e.toString()}');
      rethrow;
    }
  }

  // Méthode privée pour récupérer les commodités de la chambre depuis Firestore
  Future<List<String>> _fetchRoomAmenities(String roomId) async {
    if (roomId.isEmpty) {
      return [];
    }

    try {
      final roomsSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('id', isEqualTo: roomId)
          .get();

      // Vérifier si des documents existent
      List<String> amenities = [];
      if (roomsSnapshot.docs.isNotEmpty) {
        // Récupérer les données du premier document
        var roomData = roomsSnapshot.docs.first.data();
        if (roomData.containsKey('amenities') && roomData['amenities'] != null) {
          // Convertir en List<String> de manière sécurisée
          amenities = (roomData['amenities'] as List?)
              ?.map((item) => item.toString())
              ?.toList() ?? [];
        }
      }

      return amenities;
    } catch (e) {
      print('Erreur lors de la récupération des commodités: ${e.toString()}');
      return [];
    }
  }
}
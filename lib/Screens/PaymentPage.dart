import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../config/printPaymentReceipt.dart';
import '../widgets/side_menu.dart';

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isLoading = true;
  List<DocumentSnapshot> bookings = [];
  String? filterStatus;
  TextEditingController searchController = TextEditingController();

  final List<String> statusOptions = ['reservé', 'enregistré', 'terminé', 'annulé', 'tous'];

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  String formatStatus(String? status) {
    if (status == null || status.isEmpty) return '';
    return capitalizeFirst(status);
  }

  Future<void> fetchBookings() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Récupérer l'utilisateur actuellement connecté
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        print('Aucun utilisateur connecté');
        setState(() {
          bookings = [];
          isLoading = false;
        });
        return;
      }

      print('ID de l\'utilisateur connecté: ${currentUser.uid}');

      // Commencer la requête en filtrant par userId
      Query query = FirebaseFirestore.instance.collection('bookings')
          .where('userId', isEqualTo: currentUser.uid);

      // Ajout d'un log pour voir combien de documents ont été trouvés
      final testSnapshot = await query.get();
      print('Nombre de réservations trouvées avec ce userId: ${testSnapshot.docs.length}');

      // Si aucun document n'est trouvé, essayons de récupérer tous les documents pour vérifier
      if (testSnapshot.docs.isEmpty) {
        print('Test: récupération de toutes les réservations pour vérification');
        final allDocs = await FirebaseFirestore.instance.collection('bookings').get();
        print('Nombre total de réservations dans la collection: ${allDocs.docs.length}');

        // Vérifier les userId stockés dans les documents
        for (var doc in allDocs.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final docUserId = data['userId'];
          print('Document ID: ${doc.id} - userId: $docUserId');
        }
      }

      // Appliquer le filtre de statut s'il est défini
      if (filterStatus != null && filterStatus != 'tous') {
        query = query.where('status', isEqualTo: filterStatus);
      }

      // Chercher par nom de client ou code d'enregistrement si une recherche est effectuée
      String searchTerm = searchController.text.trim().toLowerCase();
      if (searchTerm.isNotEmpty) {
        final snapshot = await query.get();
        setState(() {
          bookings = snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final customerName = (data['customerName'] ?? '').toString().toLowerCase();
            final code = (data['EnregistrementCode'] ?? '').toString().toLowerCase();
            return customerName.contains(searchTerm) || code.contains(searchTerm);
          }).toList();
          isLoading = false;
        });
        return;
      }

      // Tri par date de check-in (du plus récent au plus ancien)
      query = query.orderBy('checkInDate', descending: true);

      final snapshot = await query.get();
      setState(() {
        bookings = snapshot.docs;
        isLoading = false;
      });

    } catch (e) {
      print('Erreur lors de la récupération des réservations: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> makePayment(DocumentSnapshot booking) async {
    final data = booking.data() as Map<String, dynamic>;

    // Variables pour le paiement
    double amountToPay = 0;
    String paymentMethod = 'Espèces';
    String description = '';
    bool isFullPayment = true;

    // Calculer le montant restant dû
    double totalAmount = (data['totalAmount'] ?? 0).toDouble();

    // Récupérer les paiements existants
    final paymentsSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('bookingId', isEqualTo: booking.id)
        .where('type', isEqualTo: 'payment')
        .get();

    double paidAmount = 0;
    for (var payment in paymentsSnapshot.docs) {
      paidAmount += (payment.data()['amount'] ?? 0).toDouble();
    }

    double remainingAmount = totalAmount - paidAmount;
    amountToPay = remainingAmount;

    // Si déjà payé complètement
    if (remainingAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cette réservation est déjà entièrement payée')),
      );
      return;
    }

    // Afficher le dialogue de paiement
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
        title: Text('Paiement pour ${data['customerName']}'),
        content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      return SingleChildScrollView(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
          Text('Montant total: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(totalAmount)}'),
    Text('Déjà payé: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(paidAmount)}'),
    Text('Montant restant: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(remainingAmount)}'),
    const SizedBox(height: 16),

    // Option de paiement complet ou partiel
    CheckboxListTile(
    title: const Text('Paiement complet'),
    value: isFullPayment,
    onChanged: (value) {
    setState(() {
    isFullPayment = value ?? true;
    if (isFullPayment) {
    amountToPay = remainingAmount;
    }
    });
    },
    ),

    // Montant à payer (éditable si paiement partiel)
                // Montant à payer (éditable si paiement partiel)
                if (!isFullPayment)
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Montant à payer',
                      prefixText: 'FCFA ',
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: amountToPay.toStringAsFixed(0),
                    onChanged: (value) {
                      amountToPay = double.tryParse(value) ?? 0;
                    },
                  ),

                // Méthode de paiement
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Méthode de paiement'),
                  value: paymentMethod,
                  items: ['Espèces', 'Carte bancaire', 'Mobile Money', 'Virement', 'Autre']
                      .map((method) => DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  ))
                      .toList(),
                  onChanged: (value) {
                    paymentMethod = value ?? 'Espèces';
                  },
                ),

                // Description du paiement
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description (optionnel)'),
                  maxLines: 2,
                  onChanged: (value) {
                    description = value;
                  },
                ),
              ],
          ),
      );
        },
        ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validation du montant
                if (amountToPay <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer un montant valide')),
                  );
                  return;
                }

                if (amountToPay > remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le montant ne peut pas dépasser le solde restant')),
                  );
                  return;
                }

                // Effectuer l'enregistrement du paiement
                try {
                  // Date du paiement
                  final paymentDate = Timestamp.now();

                  // Créer la transaction
                  final transactionRef = await FirebaseFirestore.instance.collection('transactions').add({
                    'bookingId': booking.id,
                    'roomId': data['roomId'],
                    'customerId': data['userId'],
                    'customerName': data['customerName'],
                    'amount': amountToPay,
                    'date': paymentDate,
                    'type': 'payment',
                    'paymentMethod': paymentMethod,
                    'description': description.isEmpty
                        ? 'Paiement pour la réservation ${data['EnregistrementCode']}'
                        : description,
                    'createdAt': paymentDate,
                    'createdBy': 'currentUser', // À remplacer par l'ID de l'utilisateur connecté
                  });

                  // Mettre à jour le statut de paiement si payé complètement
                  if (paidAmount + amountToPay >= totalAmount) {
                    await FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(booking.id)
                        .update({'paymentStatus': 'payé'});
                  }

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Paiement enregistré avec succès')),
                  );

                  // Imprimer le reçu de paiement
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Impression du reçu'),
                      content: const Text('Voulez-vous imprimer un reçu pour ce paiement?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Non'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            // Imprimer le reçu
                            await printPaymentReceipt(booking, amountToPay, paymentMethod, paymentDate);
                          },
                          child: const Text('Oui, imprimer'),
                        ),
                      ],
                    ),
                  );

                  // Rafraîchir la liste
                  fetchBookings();

                } catch (e) {
                  print('Erreur lors de l\'enregistrement du paiement: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              },
              child: const Text('Enregistrer le paiement'),
            ),
          ],
        ),
    );
  }

  void showBookingDetails(DocumentSnapshot booking) {
    final data = booking.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de la réservation ${data['EnregistrementCode']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Client', data['customerName'] ?? ''),
              _buildDetailRow('Téléphone', data['customerPhone'] ?? ''),
              _buildDetailRow('Email', data['customerEmail'] ?? ''),
              _buildDetailRow('Chambre', '${data['roomNumber']} (${data['roomType']})'),
              _buildDetailRow('Arrivée', _formatDate(data['checkInDate'])),
              _buildDetailRow('Départ', _formatDate(data['checkOutDate'])),
              _buildDetailRow('Nuits', '${data['nights']}'),
              _buildDetailRow('Prix/nuit', '${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(data['roomPrice'])}'),
              _buildDetailRow('Montant total', '${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(data['totalAmount'])}'),
              _buildDetailRow('Statut', data['status'] ?? ''),
              const Divider(),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('bookingId', isEqualTo: booking.id)
                    .where('type', isEqualTo: 'payment')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('Aucun paiement enregistré');
                  }

                  double totalPaid = 0;
                  for (var doc in snapshot.data!.docs) {
                    totalPaid += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Historique des paiements:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...snapshot.data!.docs.map((doc) {
                        final paymentData = doc.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${_formatDate(paymentData['date'])} - ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(paymentData['amount'])} (${paymentData['paymentMethod']})',
                                ),
                              ),
                              // Bouton pour imprimer le reçu spécifique
                              IconButton(
                                icon: const Icon(Icons.receipt, size: 18),
                                onPressed: () async {
                                  // Fermer ce dialogue pour éviter la confusion
                                  Navigator.of(context).pop();
                                  // Imprimer le reçu pour ce paiement spécifique
                                  await printPaymentReceipt(
                                      booking,
                                      paymentData['amount'],
                                      paymentData['paymentMethod'],
                                      paymentData['date']
                                  );
                                },
                                tooltip: 'Imprimer ce reçu',
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(),
                      Text(
                        'Total payé: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(totalPaid)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Reste à payer: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(data['totalAmount'] - totalPaid)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Non défini';

    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date.toDate());
    }

    return 'Format inconnu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
      ),
      drawer: const SideMenu(),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom ou code',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onSubmitted: (_) => fetchBookings(),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: filterStatus ?? 'tous',
                  hint: const Text('Statut'),
                  items: statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(capitalizeFirst(status)),  // Utiliser la fonction au lieu de l'extension
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      filterStatus = value;
                    });
                    fetchBookings();
                  },
                ),
              ],
            ),
          ),

          // Liste des réservations
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : bookings.isEmpty
                ? const Center(child: Text('Aucune réservation trouvée'))
                : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final data = booking.data() as Map<String, dynamic>;

                // Calculer le solde à payer
                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('bookingId', isEqualTo: booking.id)
                      .where('type', isEqualTo: 'payment')
                      .get(),
                  builder: (context, snapshot) {
                    double paidAmount = 0;
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        paidAmount += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
                      }
                    }

                    double totalAmount = (data['totalAmount'] ?? 0).toDouble();
                    double remainingAmount = totalAmount - paidAmount;
                    String paymentStatus = remainingAmount <= 0 ? 'Payé' : 'En attente';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        onTap: () => showBookingDetails(booking),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                data['customerName'] ?? 'Client inconnu',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(data['status']),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                formatStatus(data['status']),  // Utiliser la fonction formatStatus
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      'Code: ${data['EnregistrementCode'] ?? ''} - Chambre: ${data['roomNumber'] ?? ''}'
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: paymentStatus == 'Payé' ? Colors.green : Colors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    paymentStatus,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                                'Arrivée: ${_formatDateShort(data['checkInDate'])} - Départ: ${_formatDateShort(data['checkOutDate'])}'
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'Total: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(totalAmount)}'
                                ),
                                if (remainingAmount > 0)
                                  Text(
                                    'Reste: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(remainingAmount)}',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: data['status'] == 'annulé' ? null : IconButton(
                          icon: const Icon(Icons.payment),
                          onPressed: remainingAmount <= 0 ? null : () => makePayment(booking),
                          tooltip: 'Effectuer un paiement',
                          color: remainingAmount <= 0 ? Colors.grey : Colors.green,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'réservé':
        return Colors.blue;
      case 'enregistré':
        return Colors.green;
      case 'terminé':
        return Colors.purple;
      case 'annulé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateShort(dynamic date) {
    if (date == null) return '';

    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(date.toDate());
    }

    return '';
  }
}


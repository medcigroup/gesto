import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../config/generationcode.dart';
import '../../config/getConnectedUserAdminId.dart';
import '../../config/printPaymentReceipt.dart';
import '../../widgets/side_menu.dart';
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
  String? idadmin;
  final List<String> statusOptions = ['reservé', 'enregistré', 'terminé', 'annulé', 'tous'];

  @override
  void initState() {
    super.initState();
    _initializeData();

  }
  Future<void> _initializeData() async {
    // Récupérer l'ID de l'administrateur connecté
    idadmin = await getConnectedUserAdminId();
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

  final transactionCode = CodeGenerator.generateTransactionCode();

  Future<void> fetchBookings() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Récupérer l'ID de l'administrateur
      final currentUser = idadmin;

      if (currentUser == null) {
        print('Aucun utilisateur connecté');
        setState(() {
          bookings = [];
          isLoading = false;
        });
        return;
      }

      print('ID de l\'utilisateur connecté: $currentUser');

      // Commencer la requête en filtrant par userId
      Query query = FirebaseFirestore.instance.collection('bookings')
          .where('userId', isEqualTo: currentUser);

      // Appliquer le filtre de statut s'il est défini
      if (filterStatus != null && filterStatus != 'tous') {
        query = query.where('status', isEqualTo: filterStatus);
      }

      // Important: toujours appliquer l'ordre avant d'exécuter la requête
      query = query.orderBy('createdAt', descending: true);

      // Exécuter la requête
      final snapshot = await query.get();
      print('Nombre de réservations trouvées: ${snapshot.docs.length}');

      // Chercher par nom de client ou code d'enregistrement si une recherche est effectuée
      String searchTerm = searchController.text.trim().toLowerCase();
      if (searchTerm.isNotEmpty) {
        setState(() {
          bookings = snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final customerName = (data['customerName'] ?? '').toString().toLowerCase();
            final code = (data['EnregistrementCode'] ?? '').toString().toLowerCase();
            return customerName.contains(searchTerm) || code.contains(searchTerm);
          }).toList();
          isLoading = false;
        });
      } else {
        // Si pas de recherche, utiliser tous les résultats
        setState(() {
          bookings = snapshot.docs;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération des réservations: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Dans la fonction makePayment, après les variables pour le paiement
  Future<void> makePayment(DocumentSnapshot booking) async {
    final data = booking.data() as Map<String, dynamic>;

    final bool depositPaid = data['depositPaid'] ?? false;
    final double depositAmount = (data['depositAmount'] ?? 0).toDouble();
    final double balanceDue = (data['balanceDue'] ?? 0).toDouble();
    final double depositPercentage = (data['depositPercentage'] ?? 0).toDouble();



    // Variables pour le paiement
    double amountToPay = 0;
    String paymentMethod = 'Espèces';
    String description = '';
    bool isFullPayment = true;

    // Variables pour la réduction
    bool applyDiscount = false;
    double discountRate = 0;
    double discountAmount = 0;

    // Calculer le montant restant dû
    double totalAmount = (data['totalAmount'] ?? 0).toDouble();
    int nights = (data['nights'] ?? 1).toInt();

    // Récupérer les paiements existants
    final paymentsSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('bookingId', isEqualTo: booking.id)
        .where('type', isEqualTo: 'payment')
        .get();

    double paidAmount = depositPaid ? depositAmount : 0;
    for (var payment in paymentsSnapshot.docs) {
      paidAmount += (payment.data()['amount'] ?? 0).toDouble();
    }

    // Récupérer les réductions déjà appliquées
    final discountsSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('bookingId', isEqualTo: booking.id)
        .where('type', isEqualTo: 'discount')
        .get();

    double totalDiscountApplied = 0;
    for (var discount in discountsSnapshot.docs) {
      totalDiscountApplied += (discount.data()['amount'] ?? 0).toDouble();
    }

    // Calculer le montant réellement restant à payer (après réductions précédentes)
    double remainingAmount = totalAmount - paidAmount - totalDiscountApplied;
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
            // Calculer le montant de la réduction
            void calculateDiscount() {
              if (applyDiscount && discountRate > 0) {
                // Calculer le montant de la réduction basé sur le montant à payer
                discountAmount = isFullPayment
                    ? (remainingAmount * discountRate / 100)
                    : (amountToPay * discountRate / 100);
              } else {
                discountAmount = 0;
              }
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Montant total: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(totalAmount)}'),
                  Text('Acompte: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(depositAmount)} (${depositPaid ? 'Payé' : 'En attente'})'),
                  Text('Déjà payé: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(paidAmount)}'),
                  if (totalDiscountApplied > 0)
                    Text('Réductions précédentes: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(totalDiscountApplied)}'),
                  Text('Montant restant: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(remainingAmount)}'),
                  Text('Nombre de nuits: $nights'),
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
                        calculateDiscount(); // Recalculer la réduction
                      });
                    },
                  ),

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
                        setState(() {
                          amountToPay = double.tryParse(value) ?? 0;
                          calculateDiscount(); // Recalculer la réduction
                        });
                      },
                    ),

                  // Option d'application de réduction
                  CheckboxListTile(
                    title: const Text('Appliquer une réduction'),
                    value: applyDiscount,
                    onChanged: (value) {
                      setState(() {
                        applyDiscount = value ?? false;
                        calculateDiscount(); // Recalculer la réduction
                      });
                    },
                  ),

                  // Taux de réduction (visible si réduction activée)
                  if (applyDiscount)
                    Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Taux de réduction',
                            suffixText: '%',
                          ),
                          keyboardType: TextInputType.number,
                          initialValue: discountRate.toString(),
                          onChanged: (value) {
                            setState(() {
                              discountRate = double.tryParse(value) ?? 0;
                              calculateDiscount(); // Recalculer la réduction
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Réduction: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(discountAmount)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Montant après réduction: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(isFullPayment ? (remainingAmount - discountAmount) : (amountToPay - discountAmount))}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
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
              double cashAmount = isFullPayment ? remainingAmount : amountToPay;
              double finalAmount = cashAmount;

              // Appliquer la réduction si activée
              if (applyDiscount && discountRate > 0) {
                finalAmount -= discountAmount;
              }

              if (finalAmount <= 0 && !applyDiscount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un montant valide')),
                );
                return;
              }

              if (!isFullPayment && cashAmount > remainingAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le montant ne peut pas dépasser le solde restant')),
                );
                return;
              }

              // Effectuer l'enregistrement du paiement
              try {
                // Date du paiement
                final paymentDate = Timestamp.now();
                final transactionCode = await CodeGenerator.generateTransactionCode();
                // Créer la transaction pour le paiement en espèces
                if (finalAmount > 0) {
                  await FirebaseFirestore.instance.collection('transactions').add({
                    'transactionCode': transactionCode,
                    'bookingId': booking.id,
                    'roomId': data['roomId'],
                    'customerId': data['userId'],
                    'customerName': data['customerName'],
                    'amount': finalAmount,
                    'originalAmount': cashAmount,
                    'discountRate': applyDiscount ? discountRate : 0,
                    'discountAmount': discountAmount,
                    'date': paymentDate,
                    'type': 'payment',
                    'paymentMethod': paymentMethod,
                    'description': description.isEmpty
                        ? 'Paiement pour l\'enregistrement ${data['EnregistrementCode']}'
                        : description,
                    'createdAt': paymentDate,
                    'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
                  });
                }

                // Si une réduction est appliquée, créer une transaction séparée pour la réduction
                if (applyDiscount && discountAmount > 0) {
                  await FirebaseFirestore.instance.collection('transactions').add({
                    'transactionCode': transactionCode,
                    'bookingId': booking.id,
                    'roomId': data['roomId'],
                    'customerId': data['userId'],
                    'customerName': data['customerName'],
                    'amount': discountAmount,
                    'date': paymentDate,
                    'type': 'discount',
                    'discountRate': discountRate,
                    'description': 'Réduction ${discountRate}% sur l\'enregistrement ${data['EnregistrementCode']}',
                    'createdAt': paymentDate,
                    'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
                  });
                }

                // Mettre à jour le statut de paiement si payé complètement
                if (paidAmount + finalAmount + discountAmount + totalDiscountApplied >= totalAmount) {
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
                          // Modifier la fonction printPaymentReceipt pour inclure les informations de réduction
                          await printPaymentReceipt(
                              booking,
                              finalAmount,
                              paymentMethod,
                              transactionCode as String,
                              paymentDate,
                              (applyDiscount ? discountRate : 0) as double,
                              discountAmount,

                          );
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
              _buildDetailRow('Acompte', '${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(data['depositAmount'])} ''(${data['depositPaid'] ? 'Payé' : 'En attente'})'),
              _buildDetailRow('Solde dû', NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(data['balanceDue'])),
              _buildDetailRow('Statut', formatStatus(data['status'] ?? '')),
              const Divider(),

              // Historique des paiements et réductions
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('bookingId', isEqualTo: booking.id)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('Aucun paiement enregistré');
                  }

                  // Séparer les paiements et les réductions
                  final payments = snapshot.data!.docs
                      .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'payment')
                      .toList();

                  final discounts = snapshot.data!.docs
                      .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'discount')
                      .toList();

                  // Calculer les totaux
                  double totalPaid = 0;
                  for (var doc in payments) {
                    totalPaid += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
                  }

                  double totalDiscounted = 0;
                  for (var doc in discounts) {
                    totalDiscounted += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
                  }

                  double totalAmount = (data['totalAmount'] ?? 0).toDouble();
                  double depositAmount = (data['depositAmount'] ?? 0).toDouble();
                  double remainingAmount = totalAmount - totalPaid - totalDiscounted-depositAmount;;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Historique des paiements:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // Afficher les paiements
                      if (payments.isNotEmpty)
                        ...payments.map((doc) {
                          final paymentData = doc.data() as Map<String, dynamic>;
                          final double discountRate = (paymentData['discountRate'] ?? 0).toDouble();
                          final double discountAmount = (paymentData['discountAmount'] ?? 0).toDouble();
                          final double amount = (paymentData['amount'] ?? 0).toDouble();
                          final double originalAmount = (paymentData['originalAmount'] ?? amount).toDouble();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${_formatDate(paymentData['date'])} - ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(amount)} (${paymentData['paymentMethod']})',
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
                                            amount,
                                            paymentData['paymentMethod'],
                                            paymentData['transactionCode'],
                                            paymentData['date'],
                                            discountRate,
                                            discountAmount,

                                        );
                                      },
                                      tooltip: 'Imprimer ce reçu',
                                    ),
                                  ],
                                ),
                                // Afficher les informations de réduction si une réduction a été appliquée
                                if (discountRate > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
                                    child: Text(
                                      'Réduction: ${discountRate.toStringAsFixed(1)}% (${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(discountAmount)})',
                                      style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList()
                      else
                        const Text('Aucun paiement enregistré'),

                      // Afficher les réductions séparées
                      if (discounts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Réductions appliquées:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...discounts.map((doc) {
                          final discountData = doc.data() as Map<String, dynamic>;
                          final double amount = (discountData['amount'] ?? 0).toDouble();
                          final double rate = (discountData['discountRate'] ?? 0).toDouble();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${_formatDate(discountData['date'])} - ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(amount)} (${rate.toStringAsFixed(1)}%)',
                              style: TextStyle(color: Colors.green),
                            ),
                          );
                        }).toList(),
                      ],

                      const Divider(),
                      Text(
                        'Total payé (Acompte + Paiements) : ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(totalPaid+depositAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (totalDiscounted > 0)
                        Text(
                          'Total réductions: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(totalDiscounted)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      Text(
                        'Reste à payer: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(remainingAmount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: remainingAmount <= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  );
                },
              )
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
      backgroundColor: const Color(0xFFF5F7FA),

      body: Column(
        children: [
          // Carte de recherche et filtres
          Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom ou code',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onSubmitted: (_) => fetchBookings(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: filterStatus ?? 'tous',
                              hint: const Text('Statut'),
                              icon: const Icon(Icons.arrow_drop_down_rounded),
                              items: statusOptions.map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(
                                    capitalizeFirst(status),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  filterStatus = value;
                                });
                                fetchBookings();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: fetchBookings,
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Filtrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Liste des réservations
          Expanded(
            child: isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
                : bookings.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hotel_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune réservation trouvée',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final data = booking.data() as Map<String, dynamic>;

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('transactions')
                      .where('bookingId', isEqualTo: booking.id)
                      .get(),
                  builder: (context, snapshot) {
                    double paidAmount = (data['depositPaid'] ?? false)
                        ? (data['depositAmount'] ?? 0).toDouble()
                        : 0;
                    double discountAmount = 0;

                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['type'] == 'payment') {
                          paidAmount += (data['amount'] ?? 0).toDouble();
                        } else if (data['type'] == 'discount') {
                          discountAmount += (data['amount'] ?? 0).toDouble();
                        }
                      }
                    }

                    final double totalAmount = (data['totalAmount'] ?? 0).toDouble();
                    final double remainingAmount = totalAmount - paidAmount - discountAmount;
                    final String paymentStatus = remainingAmount <= 0 ? 'Payé' : 'En attente';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => showBookingDetails(booking),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _getStatusColor(data['status']).withOpacity(0.1),
                                      radius: 20,
                                      child: Icon(
                                        Icons.person,
                                        color: _getStatusColor(data['status']),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['customerName'] ?? 'Client inconnu',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Code: ${data['EnregistrementCode'] ?? ''} - Chambre: ${data['roomNumber'] ?? ''}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(data['status']).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        formatStatus(data['status']),
                                        style: TextStyle(
                                          color: _getStatusColor(data['status']),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.calendar_today_outlined,
                                        title: 'Arrivée',
                                        value: _formatDateShort(data['checkInDate']),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.calendar_today,
                                        title: 'Départ',
                                        value: _formatDateShort(data['checkOutDate']),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.attach_money_outlined,
                                        title: 'Total',
                                        value: NumberFormat.currency(
                                          symbol: 'FCFA ',
                                          decimalDigits: 0,
                                        ).format(totalAmount),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: remainingAmount <= 0
                                            ? Icons.check_circle_outline
                                            : Icons.warning_amber_outlined,
                                        title: remainingAmount <= 0 ? 'Payé' : 'Reste à payer',
                                        value: remainingAmount <= 0
                                            ? 'Complet'
                                            : NumberFormat.currency(
                                          symbol: 'FCFA ',
                                          decimalDigits: 0,
                                        ).format(remainingAmount),
                                        valueColor: remainingAmount <= 0
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                if ((data['depositAmount'] ?? 0) > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          data['depositPaid'] ? Icons.check : Icons.access_time,
                                          size: 16,
                                          color: data['depositPaid'] ? Colors.green : Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Acompte: ${NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(data['depositAmount'])} '
                                              '(${data['depositPaid'] ? 'Payé' : 'En attente'})',
                                          style: TextStyle(
                                            color: data['depositPaid'] ? Colors.green : Colors.orange,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (data['status'] != 'annulé' && remainingAmount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => makePayment(booking),
                                          icon: const Icon(
                                            Icons.payment,
                                            size: 18,
                                          ),
                                          label: const Text('Effectuer un paiement'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
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

// Widget d'aide pour afficher les informations avec icône
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
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


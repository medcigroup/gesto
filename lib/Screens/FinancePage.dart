import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/ReportService.dart';
import '../widgets/side_menu.dart';

// Service pour récupérer les données de paiement
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Récupérer les transactions pour l'utilisateur courant
  Future<List<Map<String, dynamic>>> getTransactionsForCurrentUser() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
      // Ajuster si vous filtrez par un champ différent pour l'utilisateur
      // Si c'est l'utilisateur qui a créé la transaction et non pas le client
          .where('customerId', isEqualTo: currentUser.uid)
      // Alternativement, vérifiez si le problème est que vous filtrez par customerId
      // .where('customerId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(
          20) // Limitez le nombre de résultats pour des performances optimales
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ajouter l'ID du document aux données
        return data;
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des transactions: $e');
      return [];
    }
  }

  // Calculer le revenu total pour une date spécifique
  Future<double> getTotalRevenueForDate(DateTime date) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    try {
      // Créer les limites de début et fin de journée
      final DateTime startOfDay = DateTime(date.year, date.month, date.day);
      final DateTime endOfDay = DateTime(
          date.year, date.month, date.day, 23, 59, 59);

      print('Recherche des revenus entre $startOfDay et $endOfDay');

      // Récupérer toutes les transactions de type payment
      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('customerId', isEqualTo: currentUser.uid)
          .where('type', isEqualTo: 'payment')
          .get();

      print('Nombre total de transactions de type payment: ${snapshot.docs
          .length}');

      double totalRevenue = 0;
      int matchingTransactions = 0;

      // Filtrer les transactions par date côté client
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Vérifier si la transaction a une date
        if (data.containsKey('date') && data['date'] != null) {
          final DateTime transactionDate = (data['date'] as Timestamp).toDate();

          // Vérifier si la date correspond à la plage recherchée
          if (transactionDate.isAtSameMomentAs(startOfDay) ||
              transactionDate.isAtSameMomentAs(endOfDay) ||
              (transactionDate.isAfter(startOfDay) &&
                  transactionDate.isBefore(endOfDay))) {
            // Ajouter au total si amount est présent
            if (data.containsKey('amount') && data['amount'] != null) {
              totalRevenue += (data['amount'] as num).toDouble();
              matchingTransactions++;
              print(
                  'Transaction trouvée: ${data['amount']} FCFA - ${data['description']} - ${transactionDate}');
            }
          }
        }
      }

      print(
          'Nombre de transactions correspondant à la date: $matchingTransactions');
      print('Revenu total calculé: $totalRevenue');
      return totalRevenue;
    } catch (e) {
      print('Erreur lors du calcul du revenu: $e');
      return 0;
    }
  }

  // Calculer le revenu par chambre occupée
  Future<double> getRevenuePerOccupiedRoom(DateTime date) async {
    try {
      final double totalRevenue = await getTotalRevenueForDate(date);

      // Si aucun revenu, pas besoin d'aller plus loin
      if (totalRevenue == 0) return 0;

      // Créer les limites de début et fin de journée
      final DateTime startOfDay = DateTime(date.year, date.month, date.day);
      final DateTime endOfDay = DateTime(
          date.year, date.month, date.day, 23, 59, 59);

      print('Recherche des chambres occupées entre $startOfDay et $endOfDay');

      // Récupérer toutes les transactions de type payment
      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('type', isEqualTo: 'payment')
          .get();

      print('Nombre total de transactions de type payment: ${snapshot.docs
          .length}');

      // Compter les chambres uniques
      final Set<String> uniqueRooms = {};
      int matchingTransactions = 0;

      // Filtrer les transactions par date côté client
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Vérifier si la transaction a une date
        if (data.containsKey('date') && data['date'] != null) {
          final DateTime transactionDate = (data['date'] as Timestamp).toDate();

          // Vérifier si la date correspond à la plage recherchée
          if (transactionDate.isAtSameMomentAs(startOfDay) ||
              transactionDate.isAtSameMomentAs(endOfDay) ||
              (transactionDate.isAfter(startOfDay) &&
                  transactionDate.isBefore(endOfDay))) {
            matchingTransactions++;

            // Ajouter l'ID de la chambre à notre ensemble s'il existe
            if (data.containsKey('roomId') && data['roomId'] != null &&
                data['roomId'] != '') {
              uniqueRooms.add(data['roomId'] as String);
              print(
                  'Chambre trouvée: ${data['roomId']} - ${data['description']}');
            }
          }
        }
      }

      final int occupiedRooms = uniqueRooms.length;

      print(
          'Nombre de transactions correspondant à la date: $matchingTransactions');
      print('Nombre de chambres uniques: $occupiedRooms');

      // Éviter la division par zéro
      if (occupiedRooms == 0) return 0;

      final double revenuePerRoom = totalRevenue / occupiedRooms;
      print('Revenu par chambre: $revenuePerRoom');

      return revenuePerRoom;
    } catch (e) {
      print('Erreur lors du calcul du revenu par chambre: $e');
      return 0;
    }
  }

  // Calculer le changement de pourcentage par rapport à la veille
  Future<double> getRevenueChangePercentage(DateTime date) async {
    try {
      final double todayRevenue = await getTotalRevenueForDate(date);
      final double yesterdayRevenue = await getTotalRevenueForDate(
          date.subtract(const Duration(days: 1))
      );

      print('Revenu aujourd\'hui: $todayRevenue');
      print('Revenu hier: $yesterdayRevenue');

      // Éviter la division par zéro
      if (yesterdayRevenue == 0) {
        // Si hier était 0 et aujourd'hui > 0, c'est une augmentation de 100%
        return todayRevenue > 0 ? 100 : 0;
      }

      return ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
    } catch (e) {
      print('Erreur lors du calcul du pourcentage de changement: $e');
      return 0;
    }
  }
}
class FinancePage extends StatefulWidget {
  const FinancePage({Key? key}) : super(key: key);

  @override
  _FinancePageState createState() => _FinancePageState();
}
// Widget de page Finance modifié pour utiliser les données Firebase
class _FinancePageState extends State<FinancePage> {
  final PaymentService _paymentService = PaymentService();
  final ReportService _reportService = ReportService(); // Ajouter le service de rapport
  DateTime selectedDate = DateTime.now();

  // Variables pour la plage de dates du rapport
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();
  bool isLoading = true;
  double totalDailyRevenue = 0;
  double revenuePerOccupiedRoom = 0;
  double revenueChangePercentage = 0;

  // Variable pour stocker les transactions pour le rapport
  List<Map<String, dynamic>> reportTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    setState(() => isLoading = true);

    try {
      print('Chargement des données pour ${DateFormat('dd/MM/yyyy').format(
          selectedDate)}');

      final double revenue = await _paymentService.getTotalRevenueForDate(
          selectedDate);
      print('Revenu journalier récupéré: $revenue');

      final double revenuePerRoom = await _paymentService
          .getRevenuePerOccupiedRoom(selectedDate);
      print('Revenu par chambre récupéré: $revenuePerRoom');

      final double changePercentage = await _paymentService
          .getRevenueChangePercentage(selectedDate);
      print('Pourcentage de changement récupéré: $changePercentage');

      setState(() {
        totalDailyRevenue = revenue;
        revenuePerOccupiedRoom = revenuePerRoom;
        revenueChangePercentage = changePercentage;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        // Définir des valeurs par défaut en cas d'erreur
        totalDailyRevenue = 0;
        revenuePerOccupiedRoom = 0;
        revenueChangePercentage = 0;
        isLoading = false;
      });

      // Afficher un message d'erreur à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement des données: $e')),
      );
    }
  }

  // Méthode pour sélectionner la plage de dates
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme
                  .of(context)
                  .primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      _loadReportData();
    }
  }

  // Méthode pour charger les données du rapport
  Future<void> _loadReportData() async {
    setState(() => isLoading = true);

    try {
      // Charger les transactions entre les dates sélectionnées
      reportTransactions =
      await _reportService.loadTransactionsForDateRange(startDate, endDate);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données pour le rapport: $e');
      setState(() {
        isLoading = false;
        reportTransactions = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur de chargement des données du rapport: $e')),
      );
    }
  }

  // Méthode pour générer et imprimer le rapport
  // Modifiez votre méthode _generateAndPrintReport pour ajouter plus de journalisation
  Future<void> _generateAndPrintReport() async {
    try {
      setState(() => isLoading = true);

      if (reportTransactions.isEmpty) {
        // Charger les données si elles ne sont pas déjà chargées
        print('Aucune transaction chargée, chargement des données...');
        await _loadReportData();

        if (reportTransactions.isEmpty) {
          print('Aucune transaction disponible après chargement');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune transaction à imprimer pour cette période')),
          );
          setState(() => isLoading = false);
          return;
        }
      }

      print('Début de l\'impression du rapport avec ${reportTransactions.length} transactions');
      print('Plage de dates: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}');

      // Utiliser directement la fonction d'impression (comme dans printPaymentReceipt)
      await _reportService.generateAndPrintReport(reportTransactions, startDate, endDate);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapport imprimé avec succès')),
      );
    } catch (e) {
      print('Erreur lors de l\'impression du rapport: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'impression du rapport: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadFinanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          // Bouton pour imprimer le rapport financier
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              await _selectDateRange(context);
              await _generateAndPrintReport();

            },
            tooltip: 'Imprimer le bilan financier',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinanceData,
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadFinanceData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              RevenueSection(
                totalDailyRevenue: totalDailyRevenue,
                revenuePerOccupiedRoom: revenuePerOccupiedRoom,
                selectedDate: selectedDate,
                revenueChangePercentage: revenueChangePercentage,
              ),
              // Espace pour d'autres sections
              const SizedBox(height: 16),
              _buildRecentTransactionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _paymentService.getTransactionsForCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Force rebuild
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 48),
                  SizedBox(height: 16),
                  Text('Aucune transaction trouvée'),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions récentes',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleLarge,
                  ),
                  Text(
                    '${transactions.length} transaction(s)',
                    style: Theme
                        .of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length > 10 ? 10 : transactions.length,
              // Limiter à 10 transactions
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final DateTime date = (transaction['date'] as Timestamp)
                    .toDate();

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  child: ListTile(
                    leading: const Icon(Icons.payment, color: Colors.blue),
                    title: Text(transaction['description'] ?? 'Paiement'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateFormat('dd/MM/yyyy HH:mm').format(
                              date)} - ${transaction['paymentMethod']}',
                        ),
                        Text(
                          'Client: ${transaction['customerName'] ?? "N/A"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${NumberFormat.currency(
                          symbol: 'FCFA ', decimalDigits: 0).format(
                          transaction['amount'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      _showTransactionDetails(context, transaction);
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Afficher les détails d'une transaction
  void _showTransactionDetails(BuildContext context,
      Map<String, dynamic> transaction) {
    final DateTime date = (transaction['date'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Détails de la transaction'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                      'Description', transaction['description'] ?? 'N/A'),
                  _buildDetailRow('Montant',
                      NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                          .format(transaction['amount'])),
                  _buildDetailRow(
                      'Date', DateFormat('dd/MM/yyyy HH:mm').format(date)),
                  _buildDetailRow('Mode de paiement',
                      transaction['paymentMethod'] ?? 'N/A'),
                  _buildDetailRow(
                      'Client', transaction['customerName'] ?? 'N/A'),
                  _buildDetailRow(
                      'ID Réservation', transaction['bookingId'] ?? 'N/A'),
                  _buildDetailRow('ID Chambre', transaction['roomId'] ?? 'N/A'),
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// Widget RevenueSection mis à jour pour inclure le pourcentage de changement
class RevenueSection extends StatelessWidget {
  final double totalDailyRevenue;
  final double revenuePerOccupiedRoom;
  final String currencySymbol;
  final DateTime selectedDate;
  final double revenueChangePercentage;

  const RevenueSection({
    Key? key,
    required this.totalDailyRevenue,
    required this.revenuePerOccupiedRoom,
    this.currencySymbol = 'FCFA ',
    required this.selectedDate,
    this.revenueChangePercentage = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Revenus - ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRevenueCard(
                context,
                'Revenus journaliers',
                totalDailyRevenue,
                Icons.monetization_on,
                Colors.green.shade800,
              ),
            ),
            Expanded(
              child: _buildRevenueCard(
                context,
                'Revenus par chambre occupée',
                revenuePerOccupiedRoom,
                Icons.hotel,
                Colors.blue.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueCard(
      BuildContext context,
      String title,
      double amount,
      IconData icon,
      Color color,
      ) {
    final NumberFormat formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              formatter.format(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            if (title == 'Revenus journaliers')
              _buildTrendIndicator(context, revenueChangePercentage),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, double percentChange) {
    final isPositive = percentChange >= 0;

    return Row(
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: isPositive ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'vs hier',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
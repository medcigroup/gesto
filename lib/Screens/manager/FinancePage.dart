import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../config/ReportService.dart';
import '../../widgets/side_menu.dart';



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
      // Récupérer toutes les transactions où l'hôtel est le customerId
      // Cela inclut les paiements de réservation ET les achats d'options
      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('customerId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
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

      // Récupérer toutes les transactions (paiements + achats d'options)
      // Les types possibles : 'payment' et 'option_purchase'
      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('customerId', isEqualTo: currentUser.uid)
          .where('type', whereIn: ['payment', 'option_purchase'])
          .get();

      print('Nombre total de transactions: ${snapshot.docs.length}');

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
              final type = data['type'] == 'option_purchase' ? 'Option' : 'Paiement';
              print('Transaction $type trouvée: ${data['amount']} FCFA - ${data['description']} - $transactionDate');
            }
          }
        }
      }

      print('Nombre de transactions correspondant à la date: $matchingTransactions');
      print('Revenu total calculé: $totalRevenue');
      return totalRevenue;
    } catch (e) {
      print('Erreur lors du calcul du revenu: $e');
      return 0;
    }
  }

  // Calculer les revenus par type (chambres vs options)
  Future<Map<String, double>> getRevenueByType(DateTime date) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    try {
      final DateTime startOfDay = DateTime(date.year, date.month, date.day);
      final DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('customerId', isEqualTo: currentUser.uid)
          .where('type', whereIn: ['payment', 'option_purchase'])
          .get();

      double roomRevenue = 0;
      double optionRevenue = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('date') && data['date'] != null) {
          final DateTime transactionDate = (data['date'] as Timestamp).toDate();

          if (transactionDate.isAtSameMomentAs(startOfDay) ||
              transactionDate.isAtSameMomentAs(endOfDay) ||
              (transactionDate.isAfter(startOfDay) && transactionDate.isBefore(endOfDay))) {

            if (data.containsKey('amount') && data['amount'] != null) {
              final amount = (data['amount'] as num).toDouble();
              final type = data['type'] as String;

              if (type == 'option_purchase') {
                optionRevenue += amount;
              } else if (type == 'payment') {
                roomRevenue += amount;
              }
            }
          }
        }
      }

      return {
        'rooms': roomRevenue,
        'options': optionRevenue,
      };
    } catch (e) {
      print('Erreur lors du calcul des revenus par type: $e');
      return {'rooms': 0, 'options': 0};
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
  double revPAR = 0;
  double adr = 0;
  double paiementsEnAttente = 0;

  // Variables pour les revenus par type
  double roomRevenue = 0;
  double optionRevenue = 0;

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
      print('Chargement des données pour ${DateFormat('dd/MM/yyyy').format(selectedDate)}');

      // Charger toutes les données en parallèle pour optimiser les performances
      final results = await Future.wait([
        _paymentService.getTotalRevenueForDate(selectedDate),
        _paymentService.getRevenuePerOccupiedRoom(selectedDate),
        _paymentService.getRevenueChangePercentage(selectedDate),
        _calculerRevPAR(selectedDate),
        _calculerADR(selectedDate),
        _calculerPaiementsEnAttente(),
        _paymentService.getRevenueByType(selectedDate),
      ]);

      final revenueByType = results[6] as Map<String, double>;

      setState(() {
        totalDailyRevenue = results[0] as double;
        revenuePerOccupiedRoom = results[1] as double;
        revenueChangePercentage = results[2] as double;
        revPAR = results[3] as double;
        adr = results[4] as double;
        paiementsEnAttente = results[5] as double;
        roomRevenue = revenueByType['rooms'] ?? 0;
        optionRevenue = revenueByType['options'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        totalDailyRevenue = 0;
        revenuePerOccupiedRoom = 0;
        revenueChangePercentage = 0;
        revPAR = 0;
        adr = 0;
        paiementsEnAttente = 0;
        roomRevenue = 0;
        optionRevenue = 0;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement des données: $e')),
      );
    }
  }

  Future<double> _calculerRevPAR(DateTime jour) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 0.0;

      final snapshotChambres = await FirebaseFirestore.instance
          .collection('rooms')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final nombreTotalChambres = snapshotChambres.docs.length;
      if (nombreTotalChambres <= 0) return 0.0;

      final revenuJour = await _paymentService.getTotalRevenueForDate(jour);
      return revenuJour / nombreTotalChambres;
    } catch (e) {
      print('Erreur calcul RevPAR: $e');
      return 0.0;
    }
  }

  Future<double> _calculerADR(DateTime jour) async {
    try {
      final DateTime startOfDay = DateTime(jour.year, jour.month, jour.day);
      final DateTime endOfDay = DateTime(jour.year, jour.month, jour.day, 23, 59, 59);
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 0.0;

      final snapshotReservations = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: currentUser.uid)
          .where('checkInDate', isLessThanOrEqualTo: endOfDay)
          .where('checkOutDate', isGreaterThanOrEqualTo: startOfDay)
          .get();

      final nombreChambresOccupees = snapshotReservations.docs.length;
      if (nombreChambresOccupees <= 0) return 0.0;

      final revenuJour = await _paymentService.getTotalRevenueForDate(jour);
      return revenuJour / nombreChambresOccupees;
    } catch (e) {
      print('Erreur calcul ADR: $e');
      return 0.0;
    }
  }

  Future<double> _calculerPaiementsEnAttente() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 0.0;

      // Récupérer toutes les réservations et transactions en parallèle
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', whereIn: ['reservé', 'enregistré', 'terminé'])
          .get();

      if (bookingsSnapshot.docs.isEmpty) return 0.0;

      final bookingIds = bookingsSnapshot.docs.map((doc) => doc.id).toList();

      // Récupérer toutes les transactions en une seule requête
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('bookingId', whereIn: bookingIds)
          .get();

      // Organiser les transactions par bookingId
      Map<String, List<Map<String, dynamic>>> transactionsByBooking = {};
      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final bookingId = data['bookingId'] as String;
        if (!transactionsByBooking.containsKey(bookingId)) {
          transactionsByBooking[bookingId] = [];
        }
        transactionsByBooking[bookingId]!.add(data);
      }

      double totalEnAttente = 0.0;

      // Calculer le montant restant pour chaque réservation
      for (var booking in bookingsSnapshot.docs) {
        final data = booking.data();
        final double totalAmount = (data['totalAmount'] ?? 0).toDouble();
        final bool depositPaid = data['depositPaid'] ?? false;
        final double depositAmount = (data['depositAmount'] ?? 0).toDouble();

        double paidAmount = depositPaid ? depositAmount : 0;
        double totalDiscountApplied = 0;

        final bookingTransactions = transactionsByBooking[booking.id] ?? [];
        for (var transaction in bookingTransactions) {
          if (transaction['type'] == 'payment') {
            paidAmount += (transaction['amount'] ?? 0).toDouble();
          } else if (transaction['type'] == 'discount') {
            totalDiscountApplied += (transaction['amount'] ?? 0).toDouble();
          }
        }

        double remainingAmount = totalAmount - paidAmount - totalDiscountApplied;
        if (remainingAmount > 0) {
          totalEnAttente += remainingAmount;
        }
      }

      return totalEnAttente;
    } catch (e) {
      print('Erreur calcul paiements en attente: $e');
      return 0.0;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadFinanceData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Modern App Bar avec effets
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Finances',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
                          : [Colors.white, const Color(0xFFF5F7FA)],
                    ),
                  ),
                ),
              ),
              actions: [
                // Sélecteur de date moderne
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F51B5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF3F51B5)),
                    onPressed: () => _selectDate(context),
                    tooltip: 'Sélectionner une date',
                  ),
                ),
                // Bouton pour imprimer le rapport financier
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.print_rounded, color: Colors.green),
                    onPressed: () async {
                      await _selectDateRange(context);
                      await _generateAndPrintReport();
                    },
                    tooltip: 'Imprimer le bilan financier',
                  ),
                ),
                // Bouton refresh moderne
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.orange),
                    onPressed: _loadFinanceData,
                    tooltip: 'Actualiser',
                  ),
                ),
              ],
            ),

            // Contenu principal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec date
                    _buildDateHeader(context, isDark),
                    const SizedBox(height: 20),

                    // Section des revenus modernisée
                    ModernRevenueSection(
                      totalDailyRevenue: totalDailyRevenue,
                      revenuePerOccupiedRoom: revenuePerOccupiedRoom,
                      selectedDate: selectedDate,
                      revenueChangePercentage: revenueChangePercentage,
                    ),

                    const SizedBox(height: 24),

                    // Graphique de répartition des revenus
                    _buildRevenueDistributionChart(),

                    const SizedBox(height: 24),

                    // Nouvelles cartes statistiques
                    _buildAdditionalStatsCards(),

                    const SizedBox(height: 24),

                    // Liste des transactions récentes
                    _buildRecentTransactionsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueDistributionChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalRevenue = roomRevenue + optionRevenue;

    // Calculer les pourcentages
    final roomPercentage = totalRevenue > 0 ? (roomRevenue / totalRevenue * 100).toDouble() : 0.0;
    final optionPercentage = totalRevenue > 0 ? (optionRevenue / totalRevenue * 100).toDouble() : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
              : [Colors.white, const Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFF3F51B5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Répartition des revenus',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contenu responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 600;

              if (isWideScreen) {
                // Layout horizontal pour grands écrans
                return Row(
                  children: [
                    // Graphique circulaire
                    Expanded(
                      flex: 2,
                      child: _buildPieChart(totalRevenue),
                    ),
                    const SizedBox(width: 32),
                    // Légende et détails
                    Expanded(
                      flex: 3,
                      child: _buildRevenueLegend(roomPercentage, optionPercentage, isDark),
                    ),
                  ],
                );
              } else {
                // Layout vertical pour petits écrans
                return Column(
                  children: [
                    _buildPieChart(totalRevenue),
                    const SizedBox(height: 24),
                    _buildRevenueLegend(roomPercentage, optionPercentage, isDark),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(double totalRevenue) {
    if (totalRevenue == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune donnée',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 60,
          sections: [
            // Section Chambres
            PieChartSectionData(
              value: roomRevenue,
              title: '${(roomRevenue / totalRevenue * 100).toStringAsFixed(0)}%',
              color: const Color(0xFF4CAF50),
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Section Options
            PieChartSectionData(
              value: optionRevenue,
              title: '${(optionRevenue / totalRevenue * 100).toStringAsFixed(0)}%',
              color: const Color(0xFFE91E63),
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueLegend(double roomPercentage, double optionPercentage, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Revenus des chambres
        _buildLegendItem(
          'Revenus Chambres',
          roomRevenue,
          roomPercentage,
          const Color(0xFF4CAF50),
          Icons.hotel_rounded,
          isDark,
        ),
        const SizedBox(height: 16),
        // Revenus des options
        _buildLegendItem(
          'Revenus Options',
          optionRevenue,
          optionPercentage,
          const Color(0xFFE91E63),
          Icons.shopping_bag_rounded,
          isDark,
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  color: const Color(0xFF3F51B5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(roomRevenue + optionRevenue),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3F51B5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    String label,
    double amount,
    double percentage,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0).format(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalStatsCards() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 900;
        
        if (isWideScreen) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'RevPAR',
                  revPAR,
                  Icons.hotel,
                  const Color(0xFFFF9800),
                  'Par chambre disponible',
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Prix moyen (ADR)',
                  adr,
                  Icons.attach_money,
                  const Color(0xFF9C27B0),
                  'Par nuit occupée',
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Paiements en attente',
                  paiementsEnAttente,
                  Icons.pending_actions,
                  const Color(0xFFF44336),
                  'À recouvrer',
                  isDark,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildStatCard(
                'RevPAR',
                revPAR,
                Icons.hotel,
                const Color(0xFFFF9800),
                'Par chambre disponible',
                isDark,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Prix moyen (ADR)',
                adr,
                Icons.attach_money,
                const Color(0xFF9C27B0),
                'Par nuit occupée',
                isDark,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Paiements en attente',
                paiementsEnAttente,
                Icons.pending_actions,
                const Color(0xFFF44336),
                'À recouvrer',
                isDark,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    IconData icon,
    Color color,
    String subtitle,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
              : [Colors.white, const Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              NumberFormat.currency(symbol: '', decimalDigits: 0).format(value),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'FCFA',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
              : [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3F51B5).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Période sélectionnée',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _paymentService.getTransactionsForCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: const Color(0xFF3F51B5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement des transactions...',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {}); // Force rebuild
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: const Color(0xFF3F51B5).withValues(alpha: 0.5),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune transaction',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune transaction trouvée pour cette période',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF3F51B5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Transactions récentes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${transactions.length > 10 ? 10 : transactions.length} / ${transactions.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Liste des transactions
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length > 10 ? 10 : transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final DateTime date = (transaction['date'] as Timestamp).toDate();

                return _buildModernTransactionCard(
                  context,
                  transaction,
                  date,
                  isDark,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernTransactionCard(
    BuildContext context,
    Map<String, dynamic> transaction,
    DateTime date,
    bool isDark,
  ) {
    final paymentMethod = transaction['paymentMethod'] ?? 'N/A';
    final amount = transaction['amount'] ?? 0;
    final transactionType = transaction['type'] ?? 'payment';

    // Icône et couleur selon le type de transaction
    IconData paymentIcon;
    Color iconColor;

    // Si c'est un achat d'option, utiliser une icône spécifique
    if (transactionType == 'option_purchase') {
      paymentIcon = Icons.shopping_bag_rounded;
      iconColor = const Color(0xFFE91E63); // Rose pour les achats d'options
    } else {
      // Sinon, utiliser l'icône selon la méthode de paiement
      switch (paymentMethod.toLowerCase()) {
        case 'espèces':
        case 'cash':
          paymentIcon = Icons.money_rounded;
          iconColor = const Color(0xFF4CAF50);
          break;
        case 'carte':
        case 'card':
        case 'carte bancaire':
          paymentIcon = Icons.credit_card_rounded;
          iconColor = const Color(0xFF2196F3);
          break;
        case 'mobile':
        case 'mobile money':
          paymentIcon = Icons.phone_android_rounded;
          iconColor = const Color(0xFFFF9800);
          break;
        default:
          paymentIcon = Icons.payment_rounded;
          iconColor = const Color(0xFF9C27B0);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
              : [Colors.white, const Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTransactionDetails(context, transaction),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icône de paiement
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(paymentIcon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),

                // Détails de la transaction
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['description'] ?? 'Paiement',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              transaction['customerName'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Montant
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(symbol: '', decimalDigits: 0).format(amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'FCFA',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Afficher les détails d'une transaction - Version modernisée
  void _showTransactionDetails(BuildContext context, Map<String, dynamic> transaction) {
    final DateTime date = (transaction['date'] as Timestamp).toDate();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentMethod = transaction['paymentMethod'] ?? 'N/A';
    final transactionType = transaction['type'] ?? 'payment';

    // Icône selon le type de transaction
    IconData paymentIcon;
    Color iconColor;

    // Si c'est un achat d'option, utiliser une icône spécifique
    if (transactionType == 'option_purchase') {
      paymentIcon = Icons.shopping_bag_rounded;
      iconColor = const Color(0xFFE91E63); // Rose pour les achats d'options
    } else {
      // Sinon, utiliser l'icône selon la méthode de paiement
      switch (paymentMethod.toLowerCase()) {
        case 'espèces':
        case 'cash':
          paymentIcon = Icons.money_rounded;
          iconColor = const Color(0xFF4CAF50);
          break;
        case 'carte':
        case 'card':
        case 'carte bancaire':
          paymentIcon = Icons.credit_card_rounded;
          iconColor = const Color(0xFF2196F3);
          break;
        case 'mobile':
        case 'mobile money':
          paymentIcon = Icons.phone_android_rounded;
          iconColor = const Color(0xFFFF9800);
          break;
        default:
          paymentIcon = Icons.payment_rounded;
          iconColor = const Color(0xFF9C27B0);
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
                  : [Colors.white, const Color(0xFFF5F7FA)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête avec gradient
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [iconColor, iconColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(paymentIcon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Détails de la transaction',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(date),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenu
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Montant principal
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: iconColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Montant',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            NumberFormat.currency(symbol: 'FCFA ', decimalDigits: 0)
                                .format(transaction['amount']),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Détails de la transaction
                    _buildModernDetailRow(
                      Icons.description_rounded,
                      'Description',
                      transaction['description'] ?? 'N/A',
                      isDark,
                    ),
                    _buildModernDetailRow(
                      Icons.payment_rounded,
                      'Mode de paiement',
                      paymentMethod,
                      isDark,
                    ),
                    _buildModernDetailRow(
                      Icons.person_rounded,
                      'Client',
                      transaction['customerName'] ?? 'N/A',
                      isDark,
                    ),
                    _buildModernDetailRow(
                      Icons.confirmation_number_rounded,
                      'ID Réservation',
                      transaction['bookingId'] ?? 'N/A',
                      isDark,
                    ),
                    _buildModernDetailRow(
                      Icons.hotel_rounded,
                      'ID Chambre',
                      transaction['roomId'] ?? 'N/A',
                      isDark,
                    ),
                    // Afficher l'ID de l'achat d'option si c'est une transaction d'achat d'option
                    if (transactionType == 'option_purchase')
                      _buildModernDetailRow(
                        Icons.receipt_long_rounded,
                        'ID Achat Option',
                        transaction['optionPurchaseId'] ?? 'N/A',
                        isDark,
                      ),
                    // Afficher le type de transaction
                    _buildModernDetailRow(
                      Icons.category_rounded,
                      'Type de transaction',
                      transactionType == 'option_purchase' ? 'Achat d\'options' :
                      transactionType == 'payment' ? 'Paiement de réservation' :
                      transactionType == 'discount' ? 'Réduction' : transactionType,
                      isDark,
                    ),
                  ],
                ),
              ),

              // Boutons d'action
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Fermer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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
    );
  }

  Widget _buildModernDetailRow(IconData icon, String label, String value, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget ModernRevenueSection - Version modernisée et améliorée
class ModernRevenueSection extends StatelessWidget {
  final double totalDailyRevenue;
  final double revenuePerOccupiedRoom;
  final String currencySymbol;
  final DateTime selectedDate;
  final double revenueChangePercentage;

  const ModernRevenueSection({
    Key? key,
    required this.totalDailyRevenue,
    required this.revenuePerOccupiedRoom,
    this.currencySymbol = 'FCFA ',
    required this.selectedDate,
    this.revenueChangePercentage = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF3F51B5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Vue d\'ensemble financière',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grille de cartes de revenus
        LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 600;

            if (isWideScreen) {
              return Row(
                children: [
                  Expanded(
                    child: _buildModernRevenueCard(
                      context,
                      'Revenus journaliers',
                      totalDailyRevenue,
                      Icons.trending_up_rounded,
                      const Color(0xFF4CAF50),
                      showTrend: true,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernRevenueCard(
                      context,
                      'Revenu par chambre',
                      revenuePerOccupiedRoom,
                      Icons.hotel_rounded,
                      const Color(0xFF2196F3),
                      showTrend: false,
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildModernRevenueCard(
                    context,
                    'Revenus journaliers',
                    totalDailyRevenue,
                    Icons.trending_up_rounded,
                    const Color(0xFF4CAF50),
                    showTrend: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildModernRevenueCard(
                    context,
                    'Revenu par chambre',
                    revenuePerOccupiedRoom,
                    Icons.hotel_rounded,
                    const Color(0xFF2196F3),
                    showTrend: false,
                    isDark: isDark,
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildModernRevenueCard(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    Color color,
    {bool showTrend = false,
    required bool isDark}
  ) {
    final NumberFormat formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 0,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
              : [Colors.white, const Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Montant principal
            Text(
              formatter.format(amount),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -0.5,
              ),
            ),

            // Indicateur de tendance
            if (showTrend) ...[
              const SizedBox(height: 12),
              _buildModernTrendIndicator(context, revenueChangePercentage, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernTrendIndicator(BuildContext context, double percentChange, bool isDark) {
    final isPositive = percentChange >= 0;
    final trendColor = isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: trendColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: trendColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: trendColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'vs hier',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
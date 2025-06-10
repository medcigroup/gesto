import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../../config/theme.dart';
import '../../../components/dashboard/recent_bookings.dart';
import '../../../components/reservation/ModernReservationPage.dart';
import '../../../config/getConnectedUserAdminId.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? idadmin;
  List<Reservation> reservationsList = [];
  List<RecentBooking> bookings = [];
  bool isLoading = true;
  int arrivalsCount = 0;
  int departuresCount = 0;
  int totalReservations = 0;
  int tasksCount = 0;
  double tasksProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAdminId();
    _loadTasksData();
    _fetchRecentBookings();
  }

  Future<void> _loadAdminId() async {
    idadmin = await getConnectedUserAdminId();
    if (idadmin != null) {
      fetchReservations();
    } else {
      _showErrorSnackBar('Erreur: Impossible de récupérer l\'ID administrateur');
    }
  }

  Future<void> _loadTasksData() async {
    try {
      // Obtenir l'ID de l'utilisateur connecté
      String? userId = await getConnectedUserAdminId();
      if (userId == null) {
        _showErrorSnackBar('Erreur: Impossible de récupérer l\'ID utilisateur');
        return;
      }

      // Obtenir la date du jour à minuit
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Récupérer les tâches assignées à l'utilisateur pour aujourd'hui
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('createdBy', isEqualTo: idadmin)
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('dueDate', isLessThan: Timestamp.fromDate(tomorrow))
          .get();

      // Calculer le nombre de tâches terminées
      int completedTasks = 0;
      for (var doc in snapshot.docs) {
        if (doc.data()['status'] == 'completed') {
          completedTasks++;
        }
      }

      // Mettre à jour l'état
      setState(() {
        tasksCount = snapshot.docs.length;
        tasksProgress = tasksCount > 0 ? completedTasks / tasksCount : 0.0;
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des tâches: ${e.toString()}');
      setState(() {
        tasksCount = 0;
        tasksProgress = 0.0;
      });
    }
  }

  Future<void> fetchReservations() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Obtenir la date du jour à minuit
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('userId', isEqualTo: idadmin)
          .where('status', isEqualTo: 'réservée')
          .orderBy('checkInDate')
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          reservationsList = [];
          isLoading = false;
        });
        return;
      }

      final List<Reservation> allReservations = [];
      int todayArrivals = 0;
      int todayDepartures = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Conversion des dates en DateTime avec vérification
        DateTime? checkInDate = data['checkInDate'] is Timestamp
            ? (data['checkInDate'] as Timestamp).toDate()
            : null;
        DateTime? checkOutDate = data['checkOutDate'] is Timestamp
            ? (data['checkOutDate'] as Timestamp).toDate()
            : null;

        // Assurez-vous que les dates sont valides
        if (checkInDate == null || checkOutDate == null) {
          continue; // Ignorer cette réservation si les dates sont invalides
        }

        // Créer l'objet réservation
        final reservation = Reservation(
          id: doc.id,
          customerName: data['customerName'] ?? 'Inconnu',
          roomNumber: data['roomNumber'] ?? 'Inconnu',
          roomType: data['roomType'] ?? 'Type inconnu',
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
          status: data['status'] ?? 'Inconnu',
          roomId: data['roomId'] ?? '',
          reservationCode: data['reservationCode'] ?? 'Code inconnu',
          customerEmail: data['customerEmail'] ?? '',
          customerPhone: data['customerPhone'] ?? '',
          numberOfGuests: data['numberOfGuests'] ?? 1,
          specialRequests: data['specialRequests'] ?? '',
          numberOfNights: data['numberOfNights'] as int?,
          pricePerNight: data['pricePerNight'] as double?,
          totalPrice: data['totalPrice'] as double?,
          depositPercentage: data['depositPercentage'] as int?,
          depositAmount: data['depositAmount'] as double?,
          paymentMethod: data['paymentMethod'] as String?,
          depositPaid: data['depositPaid'] as bool? ?? false,
        );

        // Vérifier si c'est une arrivée d'aujourd'hui
        if (isSameDay(checkInDate, today)) {
          todayArrivals++;
        }

        // Vérifier si c'est un départ d'aujourd'hui
        if (isSameDay(checkOutDate, today)) {
          todayDepartures++;
        }

        allReservations.add(reservation);
      }

      setState(() {
        // Filtrer pour les réservations futures ou aujourd'hui
        reservationsList = allReservations
            .where((res) => res.checkInDate.isAfter(today.subtract(const Duration(days: 1))))
            .toList();

        // Trier par date d'arrivée (les plus proches en premier)
        reservationsList.sort((a, b) => a.checkInDate.compareTo(b.checkInDate));

        arrivalsCount = todayArrivals;
        departuresCount = todayDepartures;
        totalReservations = allReservations.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement des réservations: ${e.toString()}');
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          fetchReservations(),
          _loadTasksData(),
          _fetchRecentBookings(),
        ]);
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du dashboard
            Text(
              'Tableau de Bord',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: GestoTheme.navyBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bienvenue sur votre espace de travail',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Résumé statistique
            SizedBox(
              height: 180,
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Tâches du jour',
                    value: tasksCount.toString(),
                    icon: Icons.task_alt,
                    color: Colors.blue,
                    progress: tasksProgress,
                    onTap: () {
                      // Navigation vers la liste des tâches
                      // Navigator.push(...);
                    },
                  ),
                  _buildStatCard(
                    context,
                    title: 'Réservations',
                    value: totalReservations.toString(),
                    icon: Icons.book_online,
                    color: Colors.orange,
                    onTap: () {
                      // Navigation vers la liste des réservations
                      // Navigator.push(...);
                    },
                  ),
                  _buildStatCard(
                    context,
                    title: 'Arrivées prévues',
                    value: arrivalsCount.toString(),
                    icon: Icons.login,
                    color: Colors.green,
                    onTap: () {
                      // Filtrer les arrivées du jour
                      // Navigator.push(...);
                    },
                  ),
                  _buildStatCard(
                    context,
                    title: 'Départs prévus',
                    value: departuresCount.toString(),
                    icon: Icons.logout,
                    color: Colors.purple,
                    onTap: () {
                      // Filtrer les départs du jour
                      // Navigator.push(...);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section des réservations à venir
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prochaines réservations',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: GestoTheme.navyBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Liste des réservations
            Expanded(
              child: reservationsList.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune réservation à venir',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: reservationsList.length,
                itemBuilder: (context, index) {
                  final reservation = reservationsList[index];
                  return _buildReservationCard(context, reservation);
                },
              ),
            ),

            // Section des entrées et sorties récentes
            if (bookings.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Entrées & Sorties',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: GestoTheme.navyBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    return _buildBookingCard(bookings[index]);
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        required Color color,
        double? progress,
        VoidCallback? onTap,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, color: color),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}% complété',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(RecentBooking booking) {
    final isCheckIn = booking.status.toLowerCase().contains('check-in') ||
        booking.status.toLowerCase().contains('enregistré');
    final isCheckOut = booking.status.toLowerCase().contains('check-out') ||
        booking.status.toLowerCase().contains('terminé');

    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCheckIn
                          ? Colors.green.withOpacity(0.1)
                          : isCheckOut
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCheckIn
                          ? Icons.login
                          : isCheckOut
                          ? Icons.logout
                          : Icons.hotel,
                      color: isCheckIn
                          ? Colors.green
                          : isCheckOut
                          ? Colors.red
                          : Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.guestName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chambre ${booking.roomNumber}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildBookingInfoRow(
                icon: Icons.calendar_today,
                text: isCheckIn ? 'Arrivée: ${booking.checkIn}' : 'Départ: ${booking.checkOut}',
                color: isCheckIn ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 8),
              _buildBookingInfoRow(
                icon: Icons.confirmation_number,
                text: 'Réf: ${booking.bookingId}',
                color: Colors.grey[700]!,
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: booking.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: booking.statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingInfoRow({required IconData icon, required String text, required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }



  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'confirmée':
      case 'confirmé':
      case 'confirmee':
        return Colors.green;
      case 'pending':
      case 'en attente':
        return Colors.orange;
      case 'canceled':
      case 'cancelled':
      case 'annulée':
      case 'annulé':
      case 'annulee':
        return Colors.red;
      case 'checked-in':
      case 'check-in':
      case 'enregistré':
      case 'enregistre':
        return Colors.blue;
      case 'terminé':
      case 'check-out':
      case 'sorti':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }


  Future<void> _fetchRecentBookings() async {
    try {
      String? userId = await getConnectedUserAdminId();
      if (userId == null) {
        _showErrorSnackBar('Erreur: Impossible de récupérer l\'ID administrateur');
        return;
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('checkInDate', descending: true)
          .limit(5)
          .get();

      List<RecentBooking> fetchedBookings = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return RecentBooking(
          guestName: data['customerName'] ?? 'Unknown',
          roomNumber: data['roomNumber'] ?? 'N/A',
          checkIn: DateFormat('yyyy-MM-dd').format((data['checkInDate'] as Timestamp).toDate()),
          checkOut: DateFormat('yyyy-MM-dd').format((data['checkOutDate'] as Timestamp).toDate()),
          status: data['status'] ?? 'Unknown',
          statusColor: _getStatusColor(data['status']),
          bookingId: data['EnregistrementCode'] ?? 'N/A',
          phoneNumber: data['customerPhone'] ?? 'N/A',
        );
      }).toList();

      setState(() {
        bookings = fetchedBookings;
      });
    } catch (e) {
      print('Erreur lors du chargement des réservations: $e');
    }
  }


  Widget _buildReservationCard(BuildContext context, Reservation reservation) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final bool isArrivalToday = isSameDay(
        reservation.checkInDate, DateTime.now());
    final bool isDepartureToday = isSameDay(
        reservation.checkOutDate, DateTime.now());

    // Déterminer la couleur de statut
    Color statusColor;
    switch (reservation.status.toLowerCase()) {
      case 'Enregistré':
        statusColor = Colors.green;
        break;
      case 'en attente':
        statusColor = Colors.orange;
        break;
      case 'annulée':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigation vers les détails de la réservation
          // Navigator.push(...);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar du client ou icône
                  CircleAvatar(
                    backgroundColor: GestoTheme.navyBlue.withOpacity(0.1),
                    child: Text(
                      reservation.customerName.isNotEmpty
                          ? reservation.customerName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: GestoTheme.navyBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nom du client et numéro de chambre
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Chambre ${reservation.roomNumber} • ${reservation.roomType}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reservation.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Dates de séjour
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.login, size: 16, color: isArrivalToday ? Colors.green : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Arrivée',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(reservation.checkInDate),
                          style: TextStyle(
                            fontWeight: isArrivalToday ? FontWeight.bold : FontWeight.normal,
                            color: isArrivalToday ? Colors.green : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.logout, size: 16, color: isDepartureToday ? Colors.purple : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Départ',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(reservation.checkOutDate),
                          style: TextStyle(
                            fontWeight: isDepartureToday ? FontWeight.bold : FontWeight.normal,
                            color: isDepartureToday ? Colors.purple : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Personnes',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reservation.numberOfGuests ?? 1} personne${reservation.numberOfGuests != null && reservation.numberOfGuests! > 1 ? 's' : ''}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
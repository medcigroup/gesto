import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/dashboard/occupancy_chart.dart';

/// Cette fonction récupère les réservations depuis Firebase et calcule
/// le taux d'occupation pour chaque jour de la semaine
Future<List<FlSpot>> calculerOccupationChambres(
    DateTime dateDebut, {
      int nombreTotalChambres = 0,
    }) async {
  // Vérifier que le nombre total de chambres est valide
  if (nombreTotalChambres <= 0) {
    // Récupérer le nombre total de chambres depuis Firebase si non fourni
    final snapshotChambres = await FirebaseFirestore.instance
        .collection('rooms')
        .get();

    nombreTotalChambres = snapshotChambres.docs.length;

    // Si toujours 0, utiliser une valeur par défaut
    if (nombreTotalChambres <= 0) {
      nombreTotalChambres = 1; // Pour éviter division par zéro
    }
  }

  // Calculer la date de fin (7 jours après la date de début)
  final dateFin = dateDebut.add(const Duration(days: 6));
  final User? user = FirebaseAuth.instance.currentUser;
  // Récupérer toutes les réservations qui chevauchent la période
  final snapshotReservations = await FirebaseFirestore.instance
      .collection('bookings')
      .where('userId', isEqualTo: user?.uid) // Utiliser user.uid pour l'I
      .where('checkInDate', isLessThanOrEqualTo: dateFin)
      .where('checkOutDate', isGreaterThanOrEqualTo: dateDebut)
      .get();

  // Initialiser les compteurs pour chaque jour (0 = lundi, 6 = dimanche)
  final List<int> chambresOccupees = List.filled(7, 0);

  // Pour chaque réservation, compter les chambres occupées par jour
  for (var doc in snapshotReservations.docs) {
    final reservation = doc.data();

    // Convertir les timestamps Firestore en DateTime
    final dateArrivee = (reservation['checkInDate'] as Timestamp).toDate();
    final dateDepart = (reservation['checkOutDate'] as Timestamp).toDate();

    // Pour chaque jour entre l'arrivée et le départ
    for (var jour = dateDebut; jour.isBefore(dateFin.add(const Duration(days: 1))); jour = jour.add(const Duration(days: 1))) {
      // Vérifier si le jour est entre la date d'arrivée et la date de départ
      if (jour.isAfter(dateArrivee.subtract(const Duration(days: 1))) &&
          jour.isBefore(dateDepart)) {
        // Calculer l'index du jour (0 pour lundi, 6 pour dimanche)
        final indexJour = jour.weekday - 1;
        // Incrémenter le compteur pour ce jour
        if (indexJour >= 0 && indexJour < 7) {
          chambresOccupees[indexJour]++;
        }
      }
    }
  }

  // Convertir en pourcentage d'occupation et en FlSpot pour le graphique
  final List<FlSpot> donneesTauxOccupation = [];

  for (int i = 0; i < 7; i++) {
    final pourcentage = (chambresOccupees[i] / nombreTotalChambres) * 100;
    donneesTauxOccupation.add(FlSpot(i.toDouble(), pourcentage));
  }

  return donneesTauxOccupation;
}

/// Fonction pour mettre à jour le widget OccupancyChart avec les données
/// de la semaine actuelle
Future<void> mettreAJourGraphiqueOccupation(
    Function(List<FlSpot>) onDonneesChargees,
    ) async {
  // Trouver le lundi de la semaine actuelle
  final aujourdhui = DateTime.now();
  final debutSemaine = aujourdhui.subtract(Duration(days: aujourdhui.weekday - 1));

  // Récupérer les données d'occupation
  final donnees = await calculerOccupationChambres(debutSemaine);

  // Appeler le callback avec les données
  onDonneesChargees(donnees);
}

/// Exemple d'utilisation dans votre widget OccupancyChart
class OccupancyChartAvecDonnees extends StatefulWidget {
  const OccupancyChartAvecDonnees({Key? key}) : super(key: key);

  @override
  State<OccupancyChartAvecDonnees> createState() => _OccupancyChartAvecDonneesState();
}

class _OccupancyChartAvecDonneesState extends State<OccupancyChartAvecDonnees> {
  List<FlSpot> occupancyData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Trouver le lundi de la semaine actuelle
      final aujourdhui = DateTime.now();
      final debutSemaine = aujourdhui.subtract(Duration(days: aujourdhui.weekday - 1));

      // Récupérer les données d'occupation
      final donnees = await calculerOccupationChambres(debutSemaine);

      setState(() {
        occupancyData = donnees;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser votre OccupancyChart existant mais avec les données chargées
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : OccupancyChart(occupancyData: occupancyData);
  }
}
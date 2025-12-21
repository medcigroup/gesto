import 'package:flutter/material.dart';
import '../help_models.dart';

/// ===============================
/// Widgets Modernes pour Gestion des Chambres
/// ===============================

class _DisplayModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isActive;

  const _DisplayModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
        color: isActive ? color.withOpacity(0.05) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomStatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final IconData icon;

  const _RoomStatusBadge({
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const _EquipmentChip({
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _RoomTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.grey.shade700,
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

class _CalendarDay extends StatelessWidget {
  final int day;
  final String status;
  final Color color;
  final bool isToday;

  const _CalendarDay({
    required this.day,
    required this.status,
    required this.color,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 60,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: isToday ? 2 : 0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddRoomStepWidget extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _AddRoomStepWidget({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numéro d'étape
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Contenu
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style:
                          Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// Gestion des Chambres – Aide (Modernisé)
/// ===============================

HelpCategory getRoomsHelp() {
  return HelpCategory(
    title: 'Gestion des chambres',
    icon: Icons.hotel_rounded,
    sections: [
      /// Section 1 : Vue d'ensemble et types d'affichage
      HelpSection(
        title: 'Vue d\'ensemble et types d\'affichage',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La page de gestion des chambres est le cœur de votre inventaire. Trois modes d\'affichage sont disponibles :',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Modes d'affichage
            Column(
              children: [
                _DisplayModeCard(
                  icon: Icons.grid_view_rounded,
                  title: 'Vue Grille (Grid)',
                  description:
                  'Affichage en cartes visuelles avec photos. Idéal pour avoir un aperçu rapide du statut de toutes les chambres.',
                  color: Colors.blue,
                  isActive: true,
                ),
                const SizedBox(height: 16),
                _DisplayModeCard(
                  icon: Icons.list_rounded,
                  title: 'Vue Liste',
                  description:
                  'Affichage tabulaire détaillé. Parfait pour trier, filtrer et comparer les chambres.',
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                _DisplayModeCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Vue Calendrier',
                  description:
                  'Vue temporelle montrant l\'occupation de chaque chambre dans le temps.',
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Statuts des chambres
            Text(
              'Statuts des chambres :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _RoomStatusBadge(
                  status: 'Disponible',
                  color: Colors.green,
                  icon: Icons.check_circle_rounded,
                ),
                _RoomStatusBadge(
                  status: 'Occupée',
                  color: Colors.red,
                  icon: Icons.person_rounded,
                ),
                _RoomStatusBadge(
                  status: 'Maintenance',
                  color: Colors.orange,
                  icon: Icons.build_rounded,
                ),
                _RoomStatusBadge(
                  status: 'Réservée',
                  color: Colors.purple,
                  icon: Icons.bookmark_rounded,
                ),
                _RoomStatusBadge(
                  status: 'Hors service',
                  color: Colors.grey.shade700,
                  icon: Icons.block_rounded,
                ),
              ],
            ),
          ],
        ),
        steps: [
          'Accédez au menu "Chambres" pour voir votre inventaire complet',
          'Changez le mode d\'affichage selon vos besoins : Grille, Liste ou Calendrier',
          'Utilisez les filtres en haut de page : Statut, Type, Équipements',
          'La barre de recherche vous permet de trouver rapidement une chambre par son numéro',
          'Triez la liste par numéro croissant ou décroissant',
          'Chaque chambre affiche son taux d\'occupation mensuel',
          'Cliquez sur une chambre pour voir tous ses détails et son historique',
        ],
      ),

      /// Section 2 : Ajouter une nouvelle chambre (COMPLÈTE AVEC ÉTAPES VISUELLES)
      HelpSection(
        title: 'Ajouter une nouvelle chambre',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L\'ajout de chambres se fait via un formulaire complet qui enregistre toutes les caractéristiques importantes.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Types de chambres
            Text(
              'Types de chambre disponibles :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _RoomTypeCard(
                  title: 'Chambre simple',
                  description: '1 lit simple, 1 personne',
                  icon: Icons.single_bed_rounded,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _RoomTypeCard(
                  title: 'Chambre Standard',
                  description: '1 lit double, 2 personnes',
                  icon: Icons.king_bed_rounded,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                _RoomTypeCard(
                  title: 'Chambre twin',
                  description: '2 lits simples, 2 personnes',
                  icon: Icons.bedroom_parent_rounded,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                _RoomTypeCard(
                  title: 'Suite junior',
                  description: 'Chambre spacieuse avec coin salon',
                  icon: Icons.weekend_rounded,
                  color: Colors.purple,
                ),
                const SizedBox(height: 12),
                _RoomTypeCard(
                  title: 'Suite présidentielle',
                  description: 'Plus grand standing avec services VIP',
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Équipements
            Text(
              'Équipements et services :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              children: [
                _EquipmentChip(
                  label: 'WiFi',
                  icon: Icons.wifi_rounded,
                  isSelected: true,
                ),
                _EquipmentChip(
                  label: 'Climatisation',
                  icon: Icons.ac_unit_rounded,
                ),
                _EquipmentChip(
                  label: 'TV',
                  icon: Icons.tv_rounded,
                ),
                _EquipmentChip(
                  label: 'Minibar',
                  icon: Icons.kitchen_rounded,
                ),
                _EquipmentChip(
                  label: 'Coffre-fort',
                  icon: Icons.lock_rounded,
                ),
                _EquipmentChip(
                  label: 'Balcon',
                  icon: Icons.balcony_rounded,
                ),
                _EquipmentChip(
                  label: 'Vue mer',
                  icon: Icons.water_rounded,
                ),
                _EquipmentChip(
                  label: 'Baignoire',
                  icon: Icons.bathtub_rounded,
                ),
                _EquipmentChip(
                  label: 'Douche',
                  icon: Icons.shower_rounded,
                ),
                _EquipmentChip(
                  label: 'Sèche-cheveux',
                  icon: Icons.dry_cleaning_rounded,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Étapes d'ajout de chambre
            Text(
              'Étapes d\'ajout d\'une chambre :',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            Column(
              children: [
                _AddRoomStepWidget(
                  stepNumber: 1,
                  title: 'Accéder au formulaire',
                  description:
                  'Dans la page Chambres, cliquez sur le bouton "+" ou "Ajouter une chambre"',
                  icon: Icons.add_circle_rounded,
                  color: Colors.blue,
                ),
                _AddRoomStepWidget(
                  stepNumber: 2,
                  title: 'Numéro de chambre',
                  description:
                  'Remplissez le numéro de chambre (requis, doit être unique)',
                  icon: Icons.numbers_rounded,
                  color: Colors.green,
                ),
                _AddRoomStepWidget(
                  stepNumber: 3,
                  title: 'Type et capacité',
                  description:
                  'Sélectionnez le type de chambre et indiquez la capacité maximale',
                  icon: Icons.type_specimen_rounded,
                  color: Colors.orange,
                ),
                _AddRoomStepWidget(
                  stepNumber: 4,
                  title: 'Prix et équipements',
                  description:
                  'Saisissez le prix par nuit et cochez tous les équipements disponibles',
                  icon: Icons.attach_money_rounded,
                  color: Colors.purple,
                ),
                _AddRoomStepWidget(
                  stepNumber: 5,
                  title: 'Étage et description',
                  description:
                  'Indiquez l\'étage et ajoutez une description détaillée',
                  icon: Icons.description_rounded,
                  color: Colors.teal,
                ),
                _AddRoomStepWidget(
                  stepNumber: 6,
                  title: 'Photos de la chambre',
                  description:
                  'Téléchargez une ou plusieurs photos de la chambre (formats: JPG, PNG)',
                  icon: Icons.photo_library_rounded,
                  color: Colors.pink,
                ),
                _AddRoomStepWidget(
                  stepNumber: 7,
                  title: 'Validation et enregistrement',
                  description:
                  'Vérifiez toutes les informations et cliquez sur "Enregistrer"',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Note informative
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.lightBlue.shade50,
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bon à savoir :',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• La chambre apparaît immédiatement dans votre inventaire avec le statut "Disponible"\n'
                              '• Les informations renseignées sont utilisées pour le matching avec les demandes clients\n'
                              '• Vous pouvez modifier les informations à tout moment\n'
                              '• Le prix de base sert de référence pour les variations saisonnières',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Conseil de numérotation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_rounded,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Conseil : Utilisez une numérotation logique (ex: 101, 102 pour le 1er étage, 201, 202 pour le 2e étage)',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Dans la page Chambres, cliquez sur le bouton "+" ou "Ajouter une chambre"',
          'Un formulaire bottom sheet apparaît depuis le bas de l\'écran',
          'Remplissez le numéro de chambre (requis, doit être unique)',
          'Sélectionnez le type de chambre dans la liste déroulante',
          'Indiquez l\'étage où se trouve la chambre',
          'Définissez la capacité maximale de personnes',
          'Saisissez le prix par nuit en FCFA',
          'Cochez tous les équipements disponibles dans la chambre',
          'Ajoutez une description détaillée (facultatif mais recommandé)',
          'Téléchargez une ou plusieurs photos de la chambre',
          'Vérifiez que toutes les informations sont correctes',
          'Cliquez sur "Enregistrer" pour créer la chambre',
          'La chambre apparaît immédiatement dans votre inventaire avec le statut "Disponible"',
        ],
      ),

      /// Section 3 : Calendrier d'occupation
      HelpSection(
        title: 'Calendrier d\'occupation des chambres',
        customWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chaque chambre dispose de son propre calendrier d\'occupation. Cet outil visuel vous montre en un coup d\'œil les périodes occupées, disponibles et réservées.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Exemple de calendrier
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // En-tête du calendrier
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left_rounded,
                            color: Colors.grey.shade700),
                        onPressed: () {},
                      ),
                      Text(
                        'Décembre 2024',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right_rounded,
                            color: Colors.grey.shade700),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Jours de la semaine
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                        .map(
                          (day) => SizedBox(
                        width: 40,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Grille de dates
                  Wrap(
                    children: [
                      // Semaine 1
                      for (int i = 1; i <= 7; i++) ...[
                        _CalendarDay(
                          day: i,
                          status: i == 3 ? 'Occupé' : 'Disponible',
                          color: i == 3 ? Colors.red : Colors.green,
                          isToday: i == DateTime.now().day,
                        ),
                      ],
                      // Semaine 2
                      for (int i = 8; i <= 14; i++) ...[
                        _CalendarDay(
                          day: i,
                          status: i >= 10 && i <= 12 ? 'Réservé' : 'Disponible',
                          color: i >= 10 && i <= 12
                              ? Colors.purple
                              : i == 14
                              ? Colors.orange
                              : Colors.green,
                          isToday: i == DateTime.now().day,
                        ),
                      ],
                      // Semaine 3
                      for (int i = 15; i <= 21; i++) ...[
                        _CalendarDay(
                          day: i,
                          status: i == 20 ? 'Maintenance' : 'Disponible',
                          color: i == 20 ? Colors.orange : Colors.green,
                          isToday: i == DateTime.now().day,
                        ),
                      ],
                      // Semaine 4
                      for (int i = 22; i <= 28; i++) ...[
                        _CalendarDay(
                          day: i,
                          status: i >= 24 && i <= 27 ? 'Occupé' : 'Disponible',
                          color:
                          i >= 24 && i <= 27 ? Colors.red : Colors.green,
                          isToday: i == DateTime.now().day,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Légende
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Légende :',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _RoomStatusBadge(
                            status: 'Disponible',
                            color: Colors.green,
                            icon: Icons.circle_rounded,
                          ),
                          _RoomStatusBadge(
                            status: 'Occupé',
                            color: Colors.red,
                            icon: Icons.circle_rounded,
                          ),
                          _RoomStatusBadge(
                            status: 'Réservé',
                            color: Colors.purple,
                            icon: Icons.circle_rounded,
                          ),
                          _RoomStatusBadge(
                            status: 'Maintenance',
                            color: Colors.orange,
                            icon: Icons.circle_rounded,
                          ),
                          _RoomStatusBadge(
                            status: 'Jour actuel',
                            color: Colors.blue,
                            icon: Icons.circle_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Utilité du calendrier :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Anticiper les périodes de disponibilité\n• Planifier les maintenances\n• Visualiser la rentabilité de chaque chambre\n• Identifier les chambres sous-utilisées\n• Optimiser le planning de nettoyage',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        steps: [
          'Cliquez sur une chambre puis sur "Voir le calendrier"',
          'Le calendrier mensuel s\'affiche avec toutes les occupations',
          'Naviguez entre les mois avec les flèches < et >',
          'Survolez une date pour voir les détails de l\'occupation',
          'Cliquez sur une réservation pour ouvrir sa fiche complète',
          'Identifiez les périodes creuses pour planifier la maintenance',
          'Utilisez ce calendrier lors des appels de clients pour confirmer rapidement les disponibilités',
        ],
      ),
    ],
  );
}
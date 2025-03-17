import 'package:flutter/material.dart';

import '../config/routes.dart';
import '../config/theme.dart';

class AppLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const AppLayout({
    Key? key,
    required this.child,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return Scaffold(
      appBar: isMobile
          ? AppBar(
        title: const Text('Gesto'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _isSidebarExpanded = !_isSidebarExpanded;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Show profile
            },
          ),
        ],
      )
          : null,
      drawer: isMobile ? _buildSidebar(context) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;
    final theme = Theme.of(context);

    return Container(
      width: _isSidebarExpanded ? 250 : 70,
      color: GestoTheme.navyBlue,
      child: Column(
        children: [
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: _isSidebarExpanded
                  ? Text(
                'GESTO',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: GestoTheme.white,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : const Icon(
                Icons.home_work,
                color: GestoTheme.white,
                size: 32,
              ),
            ),
          if (!isMobile)
            IconButton(
              icon: Icon(
                _isSidebarExpanded
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: GestoTheme.white,
              ),
              onPressed: () {
                setState(() {
                  _isSidebarExpanded = !_isSidebarExpanded;
                });
              },
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Tableau de bord',
                  route: AppRoutes.dashboard,
                  isSelected: widget.currentRoute == AppRoutes.dashboard,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.king_bed,
                  title: 'Chambres',
                  route: AppRoutes.rooms,
                  isSelected: widget.currentRoute == AppRoutes.rooms,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.restaurant,
                  title: 'Restaurant',
                  route: AppRoutes.restaurant,
                  isSelected: widget.currentRoute == AppRoutes.restaurant,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.people,
                  title: 'Clients',
                  route: AppRoutes.clients,
                  isSelected: widget.currentRoute == AppRoutes.clients,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.badge,
                  title: 'Employés',
                  route: AppRoutes.employees,
                  isSelected: widget.currentRoute == AppRoutes.employees,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.euro,
                  title: 'Finances',
                  route: AppRoutes.finance,
                  isSelected: widget.currentRoute == AppRoutes.finance,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.settings,
                  title: 'Paramètres',
                  route: AppRoutes.settingspage,
                  isSelected: widget.currentRoute == AppRoutes.settingspage,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: _isSidebarExpanded
                ? Row(
              children: [
                const CircleAvatar(
                  backgroundColor: GestoTheme.gold,
                  child: Icon(
                    Icons.person,
                    color: GestoTheme.navyBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: GestoTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'admin@gesto.com',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: GestoTheme.white.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: GestoTheme.white,
                    size: 20,
                  ),
                  onPressed: () {
                    // Logout logic
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                ),
              ],
            )
                : IconButton(
              icon: const Icon(
                Icons.logout,
                color: GestoTheme.white,
              ),
              onPressed: () {
                // Logout logic
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String route,
        required bool isSelected,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? GestoTheme.gold : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? GestoTheme.navyBlue : GestoTheme.white,
        ),
        title: _isSidebarExpanded
            ? Text(
          title,
          style: TextStyle(
            color: isSelected ? GestoTheme.navyBlue : GestoTheme.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        )
            : null,
        onTap: () {
          if (widget.currentRoute != route) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
        dense: true,
        minLeadingWidth: 20,
        horizontalTitleGap: 12,
      ),
    );
  }
}
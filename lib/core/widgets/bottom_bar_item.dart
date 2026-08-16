import 'package:material_ui/material_ui.dart';

class BottomBarItem {
  const BottomBarItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  static const home = BottomBarItem(
    label: 'Home',
    icon: Icons.receipt_long,
    route: '/home',
  );

  static const charts = BottomBarItem(
    label: 'Charts',
    icon: Icons.pie_chart_outline,
    route: '/charts',
  );

  static const reports = BottomBarItem(
    label: 'Reports',
    icon: Icons.article_outlined,
    route: '/reports',
  );

  static const settings = BottomBarItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    route: '/settings',
  );

  static const values = [
    home,
    charts,
    reports,
    settings,
  ];

  static BottomBarItem fromLocation(String location) {
    return values.firstWhere(
      (item) => location.startsWith(item.route),
      orElse: () => home,
    );
  }
}

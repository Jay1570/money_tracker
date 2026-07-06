import 'package:flutter/material.dart';

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

  static const profile = BottomBarItem(
    label: 'Profile',
    icon: Icons.person_outline,
    route: '/profile',
  );

  static const values = [
    home,
    charts,
    reports,
    profile,
  ];

  static BottomBarItem fromLocation(String location) {
    return values.firstWhere(
      (item) => location.startsWith(item.route),
      orElse: () => home,
    );
  }
}

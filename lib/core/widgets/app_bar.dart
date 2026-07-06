import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onMenuTap,
    this.onSearchTap,
    this.onCalendarTap,
    required this.showMenu,
    required this.showSearch,
    required this.showCalendar,
  });

  final String title;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onCalendarTap;
  final bool showMenu;
  final bool showSearch;
  final bool showCalendar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: colors.surfaceContainer,
      leading: showMenu
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuTap,
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
      ),
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchTap,
          ),
        if (showCalendar)
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: onCalendarTap,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

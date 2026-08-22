import 'package:material_ui/material_ui.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onMenuTap,
    this.onSearchTap,
    this.onCalendarTap,
  });

  final String title;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onCalendarTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: colors.surfaceContainer,
      leading: onMenuTap != null
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
        if (onSearchTap != null)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchTap,
          ),
        if (onCalendarTap != null)
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

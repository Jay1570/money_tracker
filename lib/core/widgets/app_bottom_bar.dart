import 'package:material_ui/material_ui.dart';
import 'package:money_tracker/core/widgets/bottom_bar_item.dart';

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentItem,
    required this.onTap,
  });

  final BottomBarItem currentItem;
  final ValueChanged<BottomBarItem> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 70,
        child: Row(
          children: [
            _buildItem(theme, BottomBarItem.home),
            _buildItem(theme, BottomBarItem.reports),
            _buildItem(theme, BottomBarItem.settings),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(ColorScheme scheme, BottomBarItem item) {
    final selected = item == currentItem;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(item),
        borderRadius: BorderRadius.circular(1000),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: selected ? scheme.primary : scheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

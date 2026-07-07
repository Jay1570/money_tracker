import 'package:flutter/material.dart';

/// Maps a category's stored `icon` key (a short snake_case string, e.g.
/// "shopping", "food") to a Material icon for display in the category
/// grid. Falls back to a generic icon for keys that aren't recognized —
/// which will be the case until category seed data actually populates the
/// `icon` column with matching keys.
IconData categoryIconFromKey(String? key) {
  return _iconsByKey[key] ?? Icons.category_outlined;
}

const Map<String, IconData> _iconsByKey = {
  // Expense
  'shopping': Icons.shopping_cart,
  'food': Icons.restaurant,
  'phone': Icons.smartphone,
  'entertainment': Icons.sports_esports,
  'education': Icons.school,
  'beauty': Icons.content_cut,
  'sports': Icons.directions_run,
  'social': Icons.groups,
  'transportation': Icons.directions_bus,
  'clothing': Icons.checkroom,
  'car': Icons.directions_car,
  'alcohol': Icons.wine_bar,
  'cigarettes': Icons.smoking_rooms,
  'electronics': Icons.tv,
  'travel': Icons.flight,
  'health': Icons.favorite,
  'pets': Icons.pets,
  'repairs': Icons.build,
  'housing': Icons.home,
  'home': Icons.weekend,
  'gifts': Icons.card_giftcard,
  'donations': Icons.volunteer_activism,
  'lottery': Icons.casino,
  'snacks': Icons.icecream,
  'kids': Icons.child_care,
  'vegetables': Icons.eco,
  'fruits': Icons.apple,
  // Income
  'salary': Icons.work,
  'bonus': Icons.emoji_events,
  'cashback': Icons.emoji_events,
  'others': Icons.paid,
  'investment': Icons.show_chart,
};

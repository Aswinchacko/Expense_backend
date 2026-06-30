import 'package:flutter/material.dart';

import '../../core/theme/folio_theme.dart';

/// Maps stored category icon keys (and legacy emojis) to theme icons.
class CategoryIcons {
  static const emojiMap = {
    '🍔': Icons.restaurant_outlined,
    '🚗': Icons.directions_car_outlined,
    '🛍️': Icons.shopping_bag_outlined,
    '📄': Icons.receipt_long_outlined,
    '🎬': Icons.movie_outlined,
    '💊': Icons.medical_services_outlined,
    '✈️': Icons.flight_outlined,
    '💰': Icons.payments_outlined,
    '📦': Icons.inventory_2_outlined,
  };

  static const nameMap = {
    'restaurant': Icons.restaurant_outlined,
    'transport': Icons.directions_car_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'bills': Icons.receipt_long_outlined,
    'entertainment': Icons.movie_outlined,
    'health': Icons.medical_services_outlined,
    'travel': Icons.flight_outlined,
    'salary': Icons.payments_outlined,
    'other': Icons.inventory_2_outlined,
    'category': Icons.category_outlined,
    'home': Icons.home_outlined,
    'work': Icons.work_outline,
    'gift': Icons.card_giftcard_outlined,
    'pets': Icons.pets_outlined,
    'fitness': Icons.fitness_center_outlined,
    'coffee': Icons.coffee_outlined,
    'education': Icons.school_outlined,
  };

  static IconData resolve(String? raw) {
    if (raw == null || raw.isEmpty) return Icons.category_outlined;
    if (raw.startsWith('ic:')) {
      final key = raw.substring(3);
      return nameMap[key] ?? Icons.category_outlined;
    }
    return emojiMap[raw] ?? Icons.category_outlined;
  }

  static IconData iconData(String raw) => resolve(raw);

  static String storageKey(IconData icon) {
    for (final entry in nameMap.entries) {
      if (entry.value == icon) return 'ic:${entry.key}';
    }
    return 'ic:category';
  }

  static const pickerIcons = [
    Icons.restaurant_outlined,
    Icons.directions_car_outlined,
    Icons.shopping_bag_outlined,
    Icons.receipt_long_outlined,
    Icons.movie_outlined,
    Icons.medical_services_outlined,
    Icons.flight_outlined,
    Icons.payments_outlined,
    Icons.home_outlined,
    Icons.work_outline,
    Icons.coffee_outlined,
    Icons.school_outlined,
    Icons.fitness_center_outlined,
    Icons.pets_outlined,
    Icons.card_giftcard_outlined,
    Icons.inventory_2_outlined,
    Icons.category_outlined,
  ];
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.icon,
    this.size = 26,
    this.color = FolioColors.foreground,
  });

  final String icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(CategoryIcons.resolve(icon), size: size, color: color);
  }
}

class CategoryIconTile extends StatelessWidget {
  const CategoryIconTile({
    super.key,
    required this.icon,
    this.size = 64,
    this.iconSize = 26,
  });

  final String icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: FolioColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: CategoryIcon(icon: icon, size: iconSize)),
    );
  }
}

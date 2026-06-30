import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/folio_theme.dart';
import '../../features/data/providers.dart';

class FolioShell extends ConsumerWidget {
  const FolioShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: FolioBottomBar(
        currentIndex: navigationShell.currentIndex,
        onSelect: (index) {
          markTabVisited(ref, index);
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class FolioBottomBar extends StatelessWidget {
  const FolioBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: FolioColors.foreground,
        borderRadius: BorderRadius.circular(FolioRadii.card),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(
            icon: Icons.menu_book_outlined,
            selected: currentIndex == 0,
            onTap: () => onSelect(0),
          ),
          _NavIcon(
            icon: Icons.grid_view_rounded,
            selected: currentIndex == 1,
            onTap: () => onSelect(1),
          ),
          _FabButton(onTap: () => context.push('/add')),
          _NavIcon(
            icon: Icons.show_chart_outlined,
            selected: currentIndex == 2,
            onTap: () => onSelect(2),
          ),
          _NavIcon(
            icon: Icons.settings_outlined,
            selected: currentIndex == 3,
            onTap: () => onSelect(3),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: selected ? FolioColors.background : FolioColors.background.withValues(alpha: 0.5),
        size: 22,
      ),
    );
  }
}

class _FabButton extends StatelessWidget {
  const _FabButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: FolioColors.background,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: FolioColors.foreground, size: 28),
      ),
    );
  }
}

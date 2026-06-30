import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/folio_theme.dart';

class FolioShell extends StatelessWidget {
  const FolioShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  final Widget child;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: FolioBottomBar(currentIndex: currentIndex),
    );
  }
}

class FolioBottomBar extends StatelessWidget {
  const FolioBottomBar({super.key, required this.currentIndex});

  final int currentIndex;

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
            onTap: () => context.go('/home'),
          ),
          _NavIcon(
            icon: Icons.grid_view_rounded,
            selected: currentIndex == 1,
            onTap: () => context.go('/categories'),
          ),
          _FabButton(onTap: () => context.push('/add')),
          _NavIcon(
            icon: Icons.show_chart_outlined,
            selected: currentIndex == 2,
            onTap: () => context.go('/insights'),
          ),
          _NavIcon(
            icon: Icons.settings_outlined,
            selected: currentIndex == 3,
            onTap: () => context.go('/settings'),
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

class _FabButton extends StatefulWidget {
  const _FabButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FabButton> createState() => _FabButtonState();
}

class _FabButtonState extends State<_FabButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: FolioColors.background,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: FolioColors.foreground, size: 28),
        ),
      ),
    );
  }
}

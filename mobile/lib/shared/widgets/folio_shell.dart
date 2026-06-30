import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/folio_theme.dart';
import '../../features/data/providers.dart';

/// Bridges tab bar taps with the swipeable [FolioPager] without Riverpod churn.
class TabPagerHandle {
  TabPagerHandle(this.animateTo);
  final Future<void> Function(int index) animateTo;
}

class TabPagerBridge {
  static TabPagerHandle? handle;
}

class FolioShell extends ConsumerStatefulWidget {
  const FolioShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<FolioShell> createState() => _FolioShellState();
}

class _FolioShellState extends ConsumerState<FolioShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      prefetchAppData(ref);
    });
  }

  Future<void> _selectTab(int index) async {
    if (index == widget.navigationShell.currentIndex) return;
    HapticFeedback.selectionClick();
    await TabPagerBridge.handle?.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: FolioBottomBar(
        currentIndex: widget.navigationShell.currentIndex,
        onSelect: _selectTab,
      ),
    );
  }
}

class FolioPager extends StatefulWidget {
  const FolioPager({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  State<FolioPager> createState() => _FolioPagerState();
}

class _FolioPagerState extends State<FolioPager> {
  static const _duration = Duration(milliseconds: 320);
  static const _curve = Curves.easeOutCubic;

  late final PageController _controller;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.navigationShell.currentIndex;
    _controller = PageController(initialPage: _lastIndex);
    TabPagerBridge.handle = TabPagerHandle(_animateTo);
  }

  @override
  void dispose() {
    if (TabPagerBridge.handle?.animateTo == _animateTo) {
      TabPagerBridge.handle = null;
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FolioPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.navigationShell.currentIndex;
    if (index != _lastIndex && _controller.hasClients) {
      _animateTo(index);
    }
  }

  Future<void> _animateTo(int index) {
    if (!mounted) return Future.value();
    _lastIndex = index;
    if (!_controller.hasClients) return Future.value();
    return _controller.animateToPage(index, duration: _duration, curve: _curve);
  }

  void _onPageChanged(int index) {
    if (index == widget.navigationShell.currentIndex) {
      _lastIndex = index;
      return;
    }
    HapticFeedback.selectionClick();
    _lastIndex = index;
    widget.navigationShell.goBranch(index, initialLocation: false);
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      onPageChanged: _onPageChanged,
      children: [
        for (final child in widget.children) RepaintBoundary(child: child),
      ],
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
    return AnimatedScale(
      scale: selected ? 1.08 : 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: IconButton(
        onPressed: onTap,
        icon: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: selected ? 1 : 0.45,
          child: Icon(icon, color: FolioColors.background, size: 22),
        ),
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
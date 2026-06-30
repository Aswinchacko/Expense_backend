import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/folio_messenger.dart';
import '../../core/theme/folio_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/category_icon.dart';
import '../data/providers.dart';

class CategoryPickerScreen extends ConsumerWidget {
  const CategoryPickerScreen({super.key, this.pickerMode = false});

  final bool pickerMode;

  double _sheetBottom(BuildContext ctx) =>
      24 + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 110;

  void _showCategorySheet(
    BuildContext context,
    WidgetRef ref, {
    Category? existing,
  }) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    var selectedIcon = existing != null
        ? CategoryIcons.iconData(existing.icon)
        : Icons.category_outlined;
    final isEdit = existing != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, _sheetBottom(ctx)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'Edit category' : 'New category',
                  style: FolioTheme.labelStyle(ctx, size: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Name'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 124,
                  child: GridView.builder(
                    scrollDirection: Axis.horizontal,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: CategoryIcons.pickerIcons.length,
                    itemBuilder: (_, i) {
                      final icon = CategoryIcons.pickerIcons[i];
                      final picked = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedIcon = icon),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: picked ? FolioColors.foreground : FolioColors.border,
                              width: picked ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            color: picked ? FolioColors.surfaceMuted : null,
                          ),
                          child: Icon(icon, color: FolioColors.foreground, size: 22),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final icon = CategoryIcons.storageKey(selectedIcon);
                    Navigator.pop(ctx);

                    final notifier = ref.read(categoriesProvider.notifier);
                    final action = isEdit
                        ? notifier.updateOptimistic(id: existing.id, name: name, icon: icon)
                        : notifier.createOptimistic(name: name, icon: icon);

                    action.then((_) {
                      showFolioSnack(isEdit ? 'Category updated' : 'Category added');
                    }).catchError((e) {
                      showFolioSnack('$e', isError: true);
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: FolioColors.foreground,
                    foregroundColor: FolioColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FolioRadii.pill),
                    ),
                  ),
                  child: Text(isEdit ? 'Save' : 'Add'),
                ),
                if (isEdit && existing.isCustom) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(context, ref, existing);
                    },
                    child: const Text('Delete category'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Category cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Remove "${cat.name}"? Expenses keep their history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(categoriesProvider.notifier).deleteOptimistic(cat.id);
      showFolioSnack('Category deleted');
    } catch (e) {
      showFolioSnack('$e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final cats = categories.valueOrNull;

    Widget body;
    if (categories.isLoading && cats == null) {
      body = const Center(child: CircularProgressIndicator(color: FolioColors.foreground));
    } else if (categories.hasError && cats == null) {
      body = Center(child: Text('${categories.error}'));
    } else {
      final list = cats ?? [];
      body = GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: list.length + (pickerMode ? 0 : 1),
        itemBuilder: (context, i) {
          if (!pickerMode && i == list.length) {
            return GestureDetector(
              onTap: () => _showCategorySheet(context, ref),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: FolioColors.border, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.add, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text('Add', style: FolioTheme.metaStyle(context, size: 11)),
                ],
              ),
            );
          }

          final cat = list[i];
          return _CategoryTile(
            cat: cat,
            pickerMode: pickerMode,
            onTap: () {
              if (pickerMode) {
                context.pop(cat);
              } else {
                _showCategorySheet(context, ref, existing: cat);
              }
            },
          );
        },
      );
    }

    if (pickerMode) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Categories', style: FolioTheme.labelStyle(context, size: 18)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCategorySheet(context, ref),
            ),
          ],
        ),
        body: body,
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Categories', style: FolioTheme.amountStyle(context, size: 28)),
                    Text('Tap any category to edit', style: FolioText.meta12),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showCategorySheet(context, ref),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  const _CategoryTile({
    required this.cat,
    required this.pickerMode,
    required this.onTap,
  });

  final Category cat;
  final bool pickerMode;
  final VoidCallback onTap;

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  double _scale = 1;

  Future<void> _handleTap() async {
    setState(() => _scale = 0.92);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    setState(() => _scale = 1);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          children: [
            CategoryIconTile(icon: widget.cat.icon),
            const SizedBox(height: 8),
            Text(
              widget.cat.name,
              style: FolioTheme.metaStyle(context, size: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

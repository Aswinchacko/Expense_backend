import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/folio_messenger.dart';
import '../../core/theme/folio_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/category_icon.dart';
import '../data/providers.dart';
import '../data/repositories.dart';

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
                  isEdit ? 'edit category' : 'new category',
                  style: FolioTheme.labelStyle(ctx, size: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'name'),
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
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    try {
                      if (isEdit) {
                        await ref.read(categoryRepositoryProvider).update(
                              id: existing.id,
                              name: name,
                              icon: CategoryIcons.storageKey(selectedIcon),
                            );
                        showFolioSnack('category updated');
                      } else {
                        await ref.read(categoryRepositoryProvider).create(
                              name: name,
                              icon: CategoryIcons.storageKey(selectedIcon),
                            );
                        showFolioSnack('category added');
                      }
                      ref.invalidate(categoriesProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      showFolioSnack('$e', isError: true);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: FolioColors.foreground,
                    foregroundColor: FolioColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FolioRadii.pill),
                    ),
                  ),
                  child: Text(isEdit ? 'save' : 'add'),
                ),
                if (isEdit) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDelete(context, ref, existing);
                    },
                    child: const Text('delete category'),
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
        title: const Text('delete category?'),
        content: Text('remove "${cat.name}"? expenses keep their history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('delete')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(categoryRepositoryProvider).delete(cat.id);
      ref.invalidate(categoriesProvider);
      showFolioSnack('category deleted');
    } catch (e) {
      showFolioSnack('$e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!pickerMode && !isTabVisited(ref, 1)) {
      return const SafeArea(child: SizedBox.expand());
    }

    final categories = pickerMode
        ? ref.watch(categoriesProvider)
        : (isTabVisited(ref, 1)
            ? ref.watch(categoriesProvider)
            : const AsyncValue<List<Category>>.loading());

    final body = categories.when(
      loading: () => const Center(child: CircularProgressIndicator(color: FolioColors.foreground)),
      error: (e, _) => Center(child: Text('$e')),
      data: (cats) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: cats.length + (pickerMode ? 0 : 1),
        itemBuilder: (context, i) {
          if (!pickerMode && i == cats.length) {
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
                  Text('add', style: FolioTheme.metaStyle(context, size: 11)),
                ],
              ),
            );
          }

          final cat = cats[i];
          return GestureDetector(
            onTap: () {
              if (pickerMode) {
                context.pop(cat);
              } else if (cat.isCustom) {
                _showCategorySheet(context, ref, existing: cat);
              }
            },
            child: Column(
              children: [
                CategoryIconTile(icon: cat.icon),
                const SizedBox(height: 8),
                Text(
                  cat.name,
                  style: FolioTheme.metaStyle(context, size: 11),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );

    if (pickerMode) {
      return Scaffold(
        appBar: AppBar(
          title: Text('categories', style: FolioTheme.labelStyle(context, size: 18)),
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
                    Text('categories', style: FolioTheme.amountStyle(context, size: 28)),
                    Text('tap custom ones to edit', style: FolioText.meta12),
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

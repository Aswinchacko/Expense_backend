import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/folio_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/folio_shell.dart';
import '../data/providers.dart';
import '../data/repositories.dart';

class CategoryPickerScreen extends ConsumerWidget {
  const CategoryPickerScreen({super.key, this.pickerMode = false});

  final bool pickerMode;

  void _showAddCategory(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '📦');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('new category', style: FolioTheme.labelStyle(ctx, size: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'name'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(hintText: 'emoji'),
              maxLength: 2,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                try {
                  await ref.read(categoryRepositoryProvider).create(
                        name: name,
                        icon: iconController.text.trim().isEmpty ? '📦' : iconController.text.trim(),
                      );
                  ref.invalidate(categoriesProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                  }
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
              child: const Text('add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final isPicker = pickerMode || GoRouterState.of(context).extra == true;

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
        itemCount: cats.length + (isPicker ? 0 : 1),
        itemBuilder: (context, i) {
          if (!isPicker && i == cats.length) {
            return GestureDetector(
              onTap: () => _showAddCategory(context, ref),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: FolioColors.border, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.add, size: 28),
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
              if (isPicker) {
                context.pop(cat);
              }
            },
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    border: Border.all(color: FolioColors.border, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(cat.icon, style: const TextStyle(fontSize: 28)),
                  ),
                ),
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

    if (isPicker) {
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
              onPressed: () => _showAddCategory(context, ref),
            ),
          ],
        ),
        body: body,
      );
    }

    return FolioShell(
      currentIndex: 1,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('categories', style: FolioTheme.amountStyle(context, size: 28)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddCategory(context, ref),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

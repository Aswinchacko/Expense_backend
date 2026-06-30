import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/folio_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/folio_shell.dart';
import '../data/providers.dart';

class CategoryPickerScreen extends ConsumerWidget {
  const CategoryPickerScreen({super.key, this.pickerMode = false});

  final bool pickerMode;

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
        itemCount: cats.length,
        itemBuilder: (context, i) {
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
              child: Text('categories', style: FolioTheme.amountStyle(context, size: 28)),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

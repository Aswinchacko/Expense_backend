import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/folio_theme.dart';
import 'features/auth/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.loadToken();

  runApp(const ProviderScope(child: FolioApp()));
}

class FolioApp extends ConsumerWidget {
  const FolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authInitProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'folio',
      debugShowCheckedModeBanner: false,
      theme: FolioTheme.light,
      routerConfig: router,
    );
  }
}

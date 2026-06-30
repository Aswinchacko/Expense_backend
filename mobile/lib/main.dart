import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_lock.dart';
import 'core/auth/auth_service.dart';
import 'core/folio_messenger.dart';
import 'core/router/app_router.dart';
import 'core/theme/folio_theme.dart';
import 'features/auth/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.loadToken();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Folio error: ${details.exceptionAsString()}');
  };

  runApp(const ProviderScope(child: FolioApp()));
}

class FolioApp extends ConsumerWidget {
  const FolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authInitProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Folio',
      debugShowCheckedModeBanner: false,
      theme: FolioTheme.light,
      routerConfig: router,
      builder: (context, child) => AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
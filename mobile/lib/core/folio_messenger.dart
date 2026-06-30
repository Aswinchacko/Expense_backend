import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/folio_theme.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showFolioSnack(String message, {bool isError = false}) {
  // One frame after route/sheet pops so the snack renders above the shell.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _show(message, isError: isError);
  });
}

void _show(String message, {bool isError = false}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  final navContext = rootNavigatorKey.currentContext;
  final bottom = (navContext != null ? MediaQuery.paddingOf(navContext).bottom : 0.0) + 96.0;
  final text = message.isEmpty ? message : message[0].toUpperCase() + message.substring(1);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: FolioColors.background,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: FolioText.label14.copyWith(color: FolioColors.background),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFD32F2F) : FolioColors.foreground,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        duration: Duration(seconds: isError ? 3 : 2),
        margin: EdgeInsets.fromLTRB(20, 0, 20, bottom),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FolioRadii.pill)),
      ),
    );
}

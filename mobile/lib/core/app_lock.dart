import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/folio_theme.dart';

class AppLock {
  AppLock._();
  static final instance = AppLock._();

  final _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _checking = false;

  bool get isUnlocked => _unlocked;

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_lock') ?? false;
  }

  Future<void> lock() async {
    if (await isEnabled()) _unlocked = false;
  }

  void markUnlocked() => _unlocked = true;

  Future<bool> unlockIfNeeded() async {
    if (_unlocked || _checking) return _unlocked;
    if (!await isEnabled()) {
      _unlocked = true;
      return true;
    }
    _checking = true;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock folio',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      _unlocked = ok;
      return ok;
    } catch (_) {
      return false;
    } finally {
      _checking = false;
    }
  }

  void resetOnLogout() => _unlocked = false;
}

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _ready = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      AppLock.instance.lock();
    }
    if (state == AppLifecycleState.resumed) {
      setState(() => _ready = false);
      _check();
    }
  }

  Future<void> _check() async {
    _enabled = await AppLock.instance.isEnabled();
    final ok = await AppLock.instance.unlockIfNeeded();
    if (mounted) setState(() => _ready = ok);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;

    return Material(
      color: FolioColors.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: FolioColors.foreground,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.lock_outline, color: FolioColors.background, size: 32),
                ),
                const SizedBox(height: 24),
                Text('folio is locked', style: FolioText.amount28),
                const SizedBox(height: 8),
                Text(
                  _enabled ? 'use your device pin or biometrics' : 'checking…',
                  style: FolioText.meta12,
                  textAlign: TextAlign.center,
                ),
                if (_enabled) ...[
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _check,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('unlock'),
                    style: FilledButton.styleFrom(
                      backgroundColor: FolioColors.foreground,
                      foregroundColor: FolioColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FolioRadii.pill),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

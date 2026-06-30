import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/widgets/folio_brand.dart';
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
    if (_unlocked) return true;
    if (_checking) return false;
    if (!await isEnabled()) {
      _unlocked = true;
      return true;
    }
    _checking = true;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Folio',
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
  bool _showLock = false;
  bool _enabled = false;
  bool _checking = false;

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
    if (state == AppLifecycleState.paused) {
      _onBackground();
    } else if (state == AppLifecycleState.resumed && _enabled) {
      _check();
    }
  }

  Future<void> _onBackground() async {
    final enabled = await AppLock.instance.isEnabled();
    if (!enabled || !mounted) return;
    await AppLock.instance.lock();
    if (mounted) setState(() => _showLock = true);
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;

    try {
      _enabled = await AppLock.instance.isEnabled();
      if (!_enabled) {
        AppLock.instance.markUnlocked();
        if (!mounted) return;
        setState(() {
          _checking = false;
          _showLock = false;
        });
        return;
      }

      if (mounted) setState(() => _showLock = true);
      final ok = await AppLock.instance.unlockIfNeeded();
      if (!mounted) return;
      setState(() {
        _checking = false;
        _showLock = !ok;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _showLock = _enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_showLock)
          Positioned.fill(
            child: _LockScreen(
              enabled: _enabled,
              checking: _checking,
              onUnlock: _check,
            ),
          ),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({
    required this.enabled,
    required this.checking,
    required this.onUnlock,
  });

  final bool enabled;
  final bool checking;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FolioColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _LockBackdrop(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FolioMonogram(size: 72),
                    const SizedBox(height: 20),
                    Text('Folio is locked', style: FolioText.amount28),
                    const SizedBox(height: 8),
                    Text(
                      checking
                          ? 'Checking…'
                          : 'Use your device PIN or biometrics',
                      style: FolioText.meta12,
                      textAlign: TextAlign.center,
                    ),
                    if (!checking) ...[
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: onUnlock,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Unlock'),
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
        ],
      ),
    );
  }
}

class _LockBackdrop extends StatelessWidget {
  const _LockBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.12,
          child: Opacity(
            opacity: 0.07,
            child: FolioMonogram(size: MediaQuery.of(context).size.width * 0.85),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.14,
          child: Opacity(
            opacity: 0.05,
            child: Text(
              'Folio',
              style: FolioText.amount28.copyWith(
                fontSize: 120,
                fontWeight: FontWeight.w800,
                letterSpacing: -4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/folio_theme.dart';
import '../../shared/widgets/folio_shell.dart';
import '../data/providers.dart';
import '../data/repositories.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricPref();
  }

  Future<void> _loadBiometricPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _biometricEnabled = prefs.getBool('biometric_lock') ?? false);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final can = await _localAuth.canCheckBiometrics;
      if (!can) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometrics not available')),
          );
        }
        return;
      }
      final ok = await _localAuth.authenticate(
        localizedReason: 'Enable biometric lock for folio',
      );
      if (!ok) return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_lock', value);
    setState(() => _biometricEnabled = value);
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', false);
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return FolioShell(
      currentIndex: 3,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          children: [
            Text('settings', style: FolioTheme.amountStyle(context, size: 28)),
            const SizedBox(height: 32),
            profile.when(
              data: (p) => _SettingTile(
                label: 'currency',
                value: p.currency,
                onTap: () => _showCurrencyPicker(p.currency),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            _SettingTile(
              label: 'biometric lock',
              trailing: Switch(
                value: _biometricEnabled,
                onChanged: _toggleBiometric,
                activeThumbColor: FolioColors.background,
                activeTrackColor: FolioColors.foreground,
              ),
            ),
            _SettingTile(
              label: 'export data',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export coming in v2')),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: FolioColors.foreground,
                  side: const BorderSide(color: FolioColors.foreground),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FolioRadii.pill),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(String current) {
    const currencies = ['USD', 'EUR', 'GBP', 'INR', 'JPY', 'CAD', 'AUD'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        children: currencies.map((c) {
          return ListTile(
            title: Text(c),
            trailing: c == current ? const Icon(Icons.check) : null,
            onTap: () async {
              await ref.read(profileRepositoryProvider).update(currency: c);
              ref.invalidate(profileProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: Text(label, style: FolioTheme.labelStyle(context))),
            if (value != null) Text(value!, style: FolioTheme.metaStyle(context)),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

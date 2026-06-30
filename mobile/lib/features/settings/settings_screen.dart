import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_lock.dart';
import '../../core/export_service.dart';
import '../../core/folio_messenger.dart';
import '../../core/theme/folio_theme.dart';
import '../../shared/widgets/premium_widgets.dart';
import '../auth/auth_providers.dart';
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
  bool _exporting = false;

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
      try {
        final can = await _localAuth.canCheckBiometrics;
        final supported = await _localAuth.isDeviceSupported();
        if (!can && !supported) {
          showFolioSnack('device lock not available', isError: true);
          return;
        }
        final ok = await _localAuth.authenticate(
          localizedReason: 'Enable app lock for folio',
          options: const AuthenticationOptions(biometricOnly: false),
        );
        if (!ok) return;
      } catch (e) {
        showFolioSnack('lock error: $e', isError: true);
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_lock', value);
    if (value) AppLock.instance.markUnlocked();
    setState(() => _biometricEnabled = value);
    showFolioSnack(value ? 'app lock enabled' : 'app lock disabled');
  }

  Future<void> _exportStatement() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final profile = await ref.read(profileProvider.future);
      final month = ref.read(selectedMonthProvider);
      final expenses = await ref.read(expensesProvider(month).future);
      await ExportService.exportBankStatement(
        profile: profile,
        expenses: expenses,
        month: month,
      );
      showFolioSnack('statement ready to share');
    } catch (e) {
      showFolioSnack('export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _editName(String? current) async {
    final controller = TextEditingController(text: current ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('display name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'your name'),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    try {
      await ref.read(profileRepositoryProvider).update(displayName: name);
      ref.invalidate(profileProvider);
      showFolioSnack('name updated');
    } catch (e) {
      showFolioSnack('$e', isError: true);
    }
  }

  Future<void> _logout() async {
    AppLock.instance.resetOnLogout();
    await ref.read(authRepositoryProvider).logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', false);
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    if (!isTabVisited(ref, 3)) {
      return const SafeArea(child: SizedBox.expand());
    }

    final profile = ref.watch(profileProvider);
    final auth = ref.watch(authNotifierProvider);
    final currencyCode = ref.watch(currencyCodeProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        children: [
          Text('settings', style: FolioTheme.amountStyle(context, size: 28)),
          const SizedBox(height: 24),
          profile.when(
            data: (p) {
              final email = p.email ?? auth.email ?? '—';
              final name = p.displayName ?? p.firstName;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FolioCard(
                    child: FolioProfileHeader(name: name, email: email),
                  ),
                  const SizedBox(height: 16),
                  FolioQuoteCard(quote: dailyMoneyQuote()),
                ],
              );
            },
            loading: () => const FolioCard(
              child: Center(child: CircularProgressIndicator(color: FolioColors.foreground)),
            ),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),
          FolioCard(
            child: Column(
              children: [
                _SettingTile(
                  label: 'display name',
                  value: profile.maybeWhen(data: (p) => p.displayName ?? p.firstName, orElse: () => null),
                  onTap: () => _editName(profile.valueOrNull?.displayName),
                ),
                const Divider(height: 1, color: FolioColors.border),
                _SettingTile(
                  label: 'currency',
                  value: currencyCode,
                  onTap: () => _showCurrencyPicker(currencyCode),
                ),
                const Divider(height: 1, color: FolioColors.border),
                _SettingTile(
                  label: 'app lock',
                  subtitle: 'pin · fingerprint · face',
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                    activeThumbColor: FolioColors.background,
                    activeTrackColor: FolioColors.foreground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FolioCard(
            child: _SettingTile(
              label: 'export bank statement',
              subtitle: _exporting ? 'generating pdf…' : 'monthly pdf with spending breakdown',
              trailing: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: FolioColors.foreground),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, size: 22),
              onTap: _exporting ? null : _exportStatement,
            ),
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
              await ref.read(currencyCodeProvider.notifier).set(c);
              ref.invalidate(profileProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              showFolioSnack('currency set to $c');
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
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: FolioText.label15.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: FolioText.meta12),
                  ],
                ],
              ),
            ),
            if (value != null) Text(value!, style: FolioText.meta12),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

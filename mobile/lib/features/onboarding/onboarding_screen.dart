import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/folio_theme.dart';
import '../../shared/widgets/folio_brand.dart';
import '../data/repositories.dart';

const _currencies = ['USD', 'EUR', 'GBP', 'INR', 'JPY', 'CAD', 'AUD'];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String _currency = 'USD';
  bool _loading = false;

  Future<void> _finish() async {
    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).update(currency: _currency);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
      if (mounted) context.go('/home');
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const FolioMonogram(size: 48),
              const SizedBox(height: 32),
              Text('pick your currency', style: FolioTheme.amountStyle(context, size: 28)),
              const SizedBox(height: 8),
              Text('you can change this later', style: FolioTheme.metaStyle(context)),
              const SizedBox(height: 32),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currencies.map((c) {
                  final selected = _currency == c;
                  return GestureDetector(
                    onTap: () => setState(() => _currency = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? FolioColors.foreground : FolioColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(FolioRadii.pill),
                      ),
                      child: Text(
                        c,
                        style: FolioTheme.labelStyle(context).copyWith(
                          color: selected ? FolioColors.background : FolioColors.foreground,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _finish,
                  child: Text(_loading ? '...' : 'get started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

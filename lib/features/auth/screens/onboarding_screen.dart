import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/providers/locale_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryGreen, kPrimaryGreenLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryGreen.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌐', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l.chooseLanguage,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Language options
              _LanguageOption(
                title: 'Português',
                flag: '🇧🇷',
                code: 'pt',
                isSelected: ref.watch(localeProvider).languageCode == 'pt',
                onTap: () => ref.read(localeProvider.notifier).setLocale('pt'),
              ),
              const SizedBox(height: 16),
              _LanguageOption(
                title: 'English',
                flag: '🇺🇸',
                code: 'en',
                isSelected: ref.watch(localeProvider).languageCode == 'en',
                onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
              ),
              const SizedBox(height: 16),
              _LanguageOption(
                title: 'Italiano',
                flag: '🇮🇹',
                code: 'it',
                isSelected: ref.watch(localeProvider).languageCode == 'it',
                onTap: () => ref.read(localeProvider.notifier).setLocale('it'),
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // This flag is already saved inside setLocale, but we do it anyway to be safe,
                    // then we just route to profile.
                    // The router will now know hasSelectedLanguage is true.
                    context.go('/profile');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l.continueBtn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final String flag;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.flag,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withOpacity(0.1) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cs.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

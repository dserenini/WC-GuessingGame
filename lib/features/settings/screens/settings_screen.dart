import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/shared/providers/theme_provider.dart';
import 'package:copa2026/shared/providers/locale_provider.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/core/constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text('⚙️ ${l.settings}')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // â”€â”€ Appearance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader(title: l.appearance),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l.themeSystem),
                  leading: const Icon(Icons.brightness_auto),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).setTheme(v!),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(l.themeLight),
                  leading: const Icon(Icons.light_mode),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).setTheme(v!),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(l.themeDark),
                  leading: const Icon(Icons.dark_mode),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).setTheme(v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // â”€â”€ Language â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader(title: l.language),
          Card(
            child: Column(
              children: [
                _LocaleTile(
                  flag: '🇧🇷',
                  label: 'Português',
                  code: 'pt',
                  current: locale.languageCode,
                  onTap: () =>
                      ref.read(localeProvider.notifier).setLocale('pt'),
                ),
                const Divider(height: 1),
                _LocaleTile(
                  flag: '🇺🇸',
                  label: 'English',
                  code: 'en',
                  current: locale.languageCode,
                  onTap: () =>
                      ref.read(localeProvider.notifier).setLocale('en'),
                ),
                const Divider(height: 1),
                _LocaleTile(
                  flag: '🇮🇹',
                  label: 'Italiano',
                  code: 'it',
                  current: locale.languageCode,
                  onTap: () =>
                      ref.read(localeProvider.notifier).setLocale('it'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Fuso Horário ───────────────────────
          _SectionHeader(title: 'Fuso Horário'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Fuso Horário Atual'),
              subtitle: Text(
                'GMT${ref.watch(timezoneProvider).inHours >= 0 ? '+' : ''}${ref.watch(timezoneProvider).inHours}',
              ),
              trailing: DropdownButton<int>(
                value: ref.watch(timezoneProvider).inHours,
                underline: const SizedBox(),
                items: List.generate(25, (index) {
                  final offset = index - 12; // -12 to +12
                  final label = 'GMT${offset >= 0 ? '+' : ''}$offset';
                  return DropdownMenuItem(
                    value: offset,
                    child: Text(label),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(timezoneProvider.notifier).setTimezone(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Agent of Chaos ────────────────────────────────────
          _SectionHeader(title: '🎲 ${l.agentOfChaos}'),
          Card(
            child: _MaxGoalsTile(),
          ),
          const SizedBox(height: 16),

          // â”€â”€ Bet Deadline â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader(title: l.betDeadline),
          Card(
            child: ListTile(
              leading: Icon(
                isBettingLocked ? Icons.lock : Icons.lock_open,
                color: isBettingLocked ? cs.error : cs.primary,
              ),
              title: Text(
                '10/06/2026 23:59 GMT-3',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                isBettingLocked ? l.betsLocked : l.betsOpen,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // â”€â”€ Account â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          _SectionHeader(title: l.account),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(l.signOut,
                  style: const TextStyle(color: Colors.red)),
              onTap: () =>
                  ref.read(authNotifierProvider.notifier).signOut(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _LocaleTile extends StatelessWidget {
  final String flag;
  final String label;
  final String code;
  final String current;
  final VoidCallback onTap;

  const _LocaleTile({
    required this.flag,
    required this.label,
    required this.code,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = code == current;
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle, color: cs.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _MaxGoalsTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MaxGoalsTile> createState() => _MaxGoalsTileState();
}

class _MaxGoalsTileState extends ConsumerState<_MaxGoalsTile> {
  int _maxGoals = kDefaultMaxGoals;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(l.chaosMaxGoals),
      subtitle: Slider(
        value: _maxGoals.toDouble(),
        min: 1,
        max: 20,
        divisions: 19,
        label: '$_maxGoals',
        activeColor: cs.primary,
        onChanged: (v) => setState(() => _maxGoals = v.round()),
      ),
      trailing: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$_maxGoals',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ),
      ),
    );
  }
}

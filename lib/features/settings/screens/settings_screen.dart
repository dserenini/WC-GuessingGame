import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/shared/providers/theme_provider.dart';
import 'package:copa2026/shared/providers/locale_provider.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/shared/providers/max_goals_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/core/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  ThemeMode? _pendingTheme;
  String? _pendingLocale;
  int? _pendingTimezone;
  int? _pendingMaxGoals;

  bool get _hasChanges =>
      _pendingTheme != null ||
      _pendingLocale != null ||
      _pendingTimezone != null ||
      _pendingMaxGoals != null;

  void _saveChanges() {
    if (_pendingTheme != null) ref.read(themeModeProvider.notifier).setTheme(_pendingTheme!);
    if (_pendingLocale != null) ref.read(localeProvider.notifier).setLocale(_pendingLocale!);
    if (_pendingTimezone != null) ref.read(timezoneProvider.notifier).setTimezone(_pendingTimezone!);
    if (_pendingMaxGoals != null) ref.read(maxGoalsProvider.notifier).setMaxGoals(_pendingMaxGoals!);

    setState(() {
      _pendingTheme = null;
      _pendingLocale = null;
      _pendingTimezone = null;
      _pendingMaxGoals = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações salvas com sucesso!')),
    );
  }

  Future<void> _cancelChanges() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('As alterações não salvas serão perdidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sim, descartar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _pendingTheme = null;
        _pendingLocale = null;
        _pendingTimezone = null;
        _pendingMaxGoals = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    
    final ThemeMode themeMode = _pendingTheme ?? ref.watch(themeModeProvider);
    final String localeCode = _pendingLocale ?? ref.watch(localeProvider).languageCode;
    final int timezoneOffset = _pendingTimezone ?? ref.watch(timezoneProvider).inHours;
    final int maxGoals = _pendingMaxGoals ?? ref.watch(maxGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('⚙️ ${l.settings}')),
      drawer: const AppDrawer(),
      bottomNavigationBar: _hasChanges
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelChanges,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
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
                    onChanged: (v) => setState(() => _pendingTheme = v),
                  ),
                  onTap: () => setState(() => _pendingTheme = ThemeMode.system),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(l.themeLight),
                  leading: const Icon(Icons.light_mode),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (v) => setState(() => _pendingTheme = v),
                  ),
                  onTap: () => setState(() => _pendingTheme = ThemeMode.light),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(l.themeDark),
                  leading: const Icon(Icons.dark_mode),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (v) => setState(() => _pendingTheme = v),
                  ),
                  onTap: () => setState(() => _pendingTheme = ThemeMode.dark),
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
                  current: localeCode,
                  onTap: () => setState(() => _pendingLocale = 'pt'),
                ),
                const Divider(height: 1),
                _LocaleTile(
                  flag: '🇺🇸',
                  label: 'English',
                  code: 'en',
                  current: localeCode,
                  onTap: () => setState(() => _pendingLocale = 'en'),
                ),
                const Divider(height: 1),
                _LocaleTile(
                  flag: '🇮🇹',
                  label: 'Italiano',
                  code: 'it',
                  current: localeCode,
                  onTap: () => setState(() => _pendingLocale = 'it'),
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
                'GMT${timezoneOffset >= 0 ? '+' : ''}$timezoneOffset',
              ),
              trailing: DropdownButton<int>(
                value: timezoneOffset,
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
                    setState(() => _pendingTimezone = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Agent of Chaos ────────────────────────────────────
          _SectionHeader(title: '🎲 ${l.agentOfChaos}'),
          Card(
            child: _MaxGoalsTile(
              maxGoals: maxGoals,
              onChanged: (v) => setState(() => _pendingMaxGoals = v),
            ),
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

          // ── Account ───────────────────────
          _SectionHeader(title: l.account),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Trocar Senha'),
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => const _ChangePasswordDialog(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(l.signOut,
                      style: const TextStyle(color: Colors.red)),
                  onTap: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.isEmpty || pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A senha deve ter pelo menos 6 caracteres.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pass),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha atualizada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trocar Senha'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Nova Senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscure,
            decoration: const InputDecoration(
              labelText: 'Confirmar Senha',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        _isLoading
            ? const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : ElevatedButton(
                onPressed: _updatePassword,
                child: const Text('Salvar'),
              ),
      ],
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

class _MaxGoalsTile extends StatelessWidget {
  final int maxGoals;
  final ValueChanged<int> onChanged;

  const _MaxGoalsTile({required this.maxGoals, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(l.chaosMaxGoals),
      subtitle: Slider(
        value: maxGoals.toDouble(),
        min: 1,
        max: 20,
        divisions: 19,
        label: '$maxGoals',
        activeColor: cs.primary,
        onChanged: (v) => onChanged(v.round()),
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
            '$maxGoals',
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

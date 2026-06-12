import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:copa2026/features/profile/providers/profile_stats_provider.dart';

import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/shared/providers/theme_provider.dart';
import 'package:copa2026/shared/providers/locale_provider.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/shared/providers/max_goals_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/settings/screens/export_bets_screen.dart';

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
      SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
    );
  }

  Future<void> _cancelChanges() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.discardChangesTitle),
        content: Text(AppLocalizations.of(context)!.discardChangesDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.yesDiscard, style: const TextStyle(color: Colors.white)),
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
    final dt = DateTime.utc(2026, 6, 11, 17, 30).add(Duration(hours: timezoneOffset));
    final deadlineStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} GMT${timezoneOffset >= 0 ? '+' : ''}$timezoneOffset';

    return Scaffold(
      appBar: AppBar(
        title: Text('⚙️ ${l.settings}'),
        leadingWidth: 100,
        leading: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const NotificationBell(),
          ],
        ),
      ),
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
                        child: Text(l.cancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        child: Text(l.save),
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
                  label: l.portuguese,
                  code: 'pt',
                  current: localeCode,
                  onTap: () => setState(() => _pendingLocale = 'pt'),
                ),
                const Divider(height: 1),
                _LocaleTile(
                  flag: '🇺🇸',
                  label: l.english,
                  code: 'en',
                  current: localeCode,
                  onTap: () => setState(() => _pendingLocale = 'en'),
                ),
                const Divider(height: 1),
                _LocaleTile(
                  flag: '🇮🇹',
                  label: l.italian,
                  code: 'it',
                  current: localeCode,
                  onTap: () => setState(() => _pendingLocale = 'it'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Fuso Horário ───────────────────────
          _SectionHeader(title: l.currentTimeZone),
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(l.currentTimeZone),
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
                deadlineStr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                isBettingLocked ? l.betsLocked : l.betsOpen,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Export ───────────────────────
          _SectionHeader(title: l.exportBets),
          Card(
            child: ListTile(
              leading: const Icon(Icons.ios_share),
              title: Text(l.exportMyBets),
              subtitle: Text(l.exportMyBetsSub),
              onTap: () async {
                final allMatches = ref.read(allMatchesProvider).valueOrNull;
                final allBets = ref.read(allBetsProvider).valueOrNull;

                if (allMatches == null || allBets == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.waitDataLoad)),
                  );
                  return;
                }

                // Busca username diretamente no Supabase para garantir que sempre vem o valor correto,
                // independente do estado do profileStatsProvider no momento do tap.
                final client = Supabase.instance.client;
                final user = client.auth.currentUser;
                String userName = user?.id ?? 'usuario'; // fallback absoluto

                try {
                  final profile = await client
                      .from('profiles')
                      .select('username')
                      .eq('id', user!.id)
                      .single();
                  final fetched = profile['username'] as String?;
                  if (fetched != null && fetched.isNotEmpty) {
                    userName = fetched;
                  } else {
                    // 2º fallback: metadado do auth
                    userName = (user.userMetadata?['username'] as String?)?.isNotEmpty == true
                        ? user.userMetadata!['username'] as String
                        : user.id;
                  }
                } catch (_) {
                  // Se a query falhar, usa metadado do auth ou user.id
                  userName = (user?.userMetadata?['username'] as String?)?.isNotEmpty == true
                      ? user!.userMetadata!['username'] as String
                      : (user?.id ?? 'usuario');
                }

                if (!context.mounted) return;

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExportBetsScreen(
                      matches: allMatches,
                      bets: allBets,
                      userName: userName,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Account ───────────────────────
          _SectionHeader(title: l.account),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(l.editProfile),
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => const _EditProfileDialog(),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: Text(l.changePassword),
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

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Versão $kAppVersion',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
          ),
          const SizedBox(height: 16),
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
    final l = AppLocalizations.of(context)!;
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.isEmpty || pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.passwordMinLength), backgroundColor: Colors.red),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.passwordsMismatch), backgroundColor: Colors.red),
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
          SnackBar(content: Text(l.passwordUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorGeneric(e.toString())), backgroundColor: Colors.red),
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
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.changePassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: l.newPassword,
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
            decoration: InputDecoration(
              labelText: l.confirmPassword,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
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
                child: Text(l.save),
              ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// EDIT PROFILE (Nome Completo + Telefone)
// ─────────────────────────────────────────────
class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog();

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  String _phoneNumber = '';
  String _initialPhone = '';
  String _displayPreference = 'username';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('full_name, phone, display_preference')
            .eq('id', user.id)
            .single();
        final fullName = (data['full_name'] as String?)?.trim() ?? '';
        final parts = fullName.isEmpty ? <String>[] : fullName.split(' ');
        _firstCtrl.text = parts.isNotEmpty ? parts.first : '';
        _lastCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _initialPhone = (data['phone'] as String?) ?? '';
        _phoneNumber = _initialPhone;
        _displayPreference =
            (data['display_preference'] as String?) ?? 'username';
      }
    } catch (_) {
      // Em caso de erro, os campos ficam vazios para preenchimento.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      final fullName =
          '${_firstCtrl.text.trim()} ${_lastCtrl.text.trim()}'.trim();
      await Supabase.instance.client.from('profiles').update({
        'full_name': fullName,
        'phone': _phoneNumber,
        'display_preference': _displayPreference,
      }).eq('id', user.id);
      ref.invalidate(profileStatsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.settingsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l.errorGeneric(e.toString())),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasInitialPhone = _initialPhone.startsWith('+');
    return AlertDialog(
      title: Text(l.editProfile),
      content: _loading
          ? const SizedBox(
              height: 80, child: Center(child: CircularProgressIndicator()))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _firstCtrl,
                      decoration: InputDecoration(
                        labelText: l.firstName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.nameRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastCtrl,
                      decoration: InputDecoration(
                        labelText: l.lastName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.nameRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    IntlPhoneField(
                      decoration: InputDecoration(
                        labelText: l.phoneLabel,
                        border: const OutlineInputBorder(),
                      ),
                      initialValue: hasInitialPhone ? _initialPhone : null,
                      initialCountryCode: hasInitialPhone ? null : 'BR',
                      disableLengthCheck: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      onChanged: (phone) => _phoneNumber = phone.completeNumber,
                      validator: (phone) {
                        final digits = (phone?.number ?? '')
                            .replaceAll(RegExp(r'\D'), '');
                        if (digits.isEmpty) return l.phoneRequired;
                        if (phone?.countryCode == '+55' &&
                            !RegExp(r'^[1-9][0-9]9[0-9]{8}$').hasMatch(digits)) {
                          return l.phoneInvalidBr;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Preferência de exibição no ranking — sem isto, alterar o
                    // nome completo não muda como o usuário aparece para os
                    // demais (o padrão é mostrar o username).
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l.displayAs,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            dense: true,
                            title: Text(l.displayAsUsername),
                            value: 'username',
                            groupValue: _displayPreference,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _displayPreference = value);
                              }
                            },
                          ),
                          const Divider(height: 1),
                          RadioListTile<String>(
                            dense: true,
                            title: Text(l.displayAsFullName),
                            value: 'full_name',
                            groupValue: _displayPreference,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _displayPreference = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        _saving
            ? const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : ElevatedButton(
                onPressed: _save,
                child: Text(l.save),
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

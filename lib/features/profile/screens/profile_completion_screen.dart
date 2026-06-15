import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:copa2026/shared/providers/locale_provider.dart';
import 'package:copa2026/features/profile/providers/profile_stats_provider.dart';
import 'package:copa2026/shared/utils/error_messages.dart';

/// Onboarding único, pedido UMA vez por conta: idioma + nome + telefone.
///
/// O idioma fica no topo e, ao ser trocado, re-traduz a tela na hora (o
/// app inteiro reconstrói via [localeProvider]), para que os campos de Nome/
/// Telefone apareçam no idioma escolhido. Tudo é gravado no `profiles`
/// (incl. a coluna `locale`), então o onboarding não se repete em outro
/// aparelho. Ver gating em ProfileScreen.
class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String _displayPreference = 'username';
  String _phoneNumber = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pré-preenche o que a conta já tiver (ex.: tinha nome mas faltava telefone),
    // para o usuário não redigitar tudo.
    final existing = ref.read(profileStatsProvider).valueOrNull;
    if (existing != null) {
      final fullName = existing.fullName?.trim() ?? '';
      if (fullName.isNotEmpty) {
        final parts = fullName.split(RegExp(r'\s+'));
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
      if (existing.displayPreference == 'full_name' || existing.displayPreference == 'username') {
        _displayPreference = existing.displayPreference;
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_phoneNumber.trim().isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.phoneRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
      final locale = ref.read(localeProvider).languageCode;

      final payload = <String, dynamic>{
        'id': user.id,
        'full_name': fullName,
        'display_preference': _displayPreference,
        'phone': _phoneNumber.trim(),
        'locale': locale,
      };

      // A coluna `username` tem constraint NOT NULL + `username_not_empty` no
      // banco. Mesmo num UPDATE, o Postgres revalida a CHECK na linha inteira:
      // se o perfil ficou com username vazio (conta antiga/criada fora do
      // trigger handle_new_user), o upsert falha com 23514. Então, só quando o
      // username atual está vazio, geramos um a partir do e-mail (mesma
      // convenção do trigger). Username já válido nunca é sobrescrito.
      final currentUsername =
          ref.read(profileStatsProvider).valueOrNull?.username.trim() ?? '';
      if (currentUsername.isEmpty) {
        final email = user.email ?? '';
        final base = email.contains('@') ? email.split('@').first : email;
        payload['username'] =
            base.isNotEmpty ? base : 'user_${user.id.substring(0, 8)}';
      }

      // upsert (em vez de update) garante que a linha seja criada se faltar e
      // evita o "0 linhas afetadas sem erro" que prendia o usuário no onboarding.
      // .select().single() confirma que a gravação realmente colou (sob RLS,
      // uma gravação bloqueada lança erro em vez de falhar em silêncio).
      final saved = await Supabase.instance.client
          .from('profiles')
          .upsert(payload)
          .select('full_name, phone, locale')
          .single();

      final savedName = (saved['full_name'] as String?)?.trim() ?? '';
      final savedPhone = (saved['phone'] as String?)?.trim() ?? '';
      if (savedName.isEmpty || savedPhone.isEmpty) {
        throw Exception('Não foi possível salvar o perfil. Tente novamente.');
      }

      // Recarrega a ProfileScreen, que agora encontra o perfil completo e some
      // com o onboarding.
      ref.invalidate(profileStatsProvider);
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeError(l, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final currentLang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.completeProfileTitle),
        // Sem drawer, sem voltar => obriga a concluir.
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_pin_rounded, size: 80, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  l.completeProfileTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l.completeProfileDesc,
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ── Idioma (troca a tela na hora) ──────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.chooseLanguage,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _LangChip(
                      flag: '🇧🇷',
                      label: 'Português',
                      selected: currentLang == 'pt',
                      onTap: () => ref.read(localeProvider.notifier).setLocale('pt'),
                    ),
                    const SizedBox(width: 8),
                    _LangChip(
                      flag: '🇺🇸',
                      label: 'English',
                      selected: currentLang == 'en',
                      onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
                    ),
                    const SizedBox(width: 8),
                    _LangChip(
                      flag: '🇮🇹',
                      label: 'Italiano',
                      selected: currentLang == 'it',
                      onTap: () => ref.read(localeProvider.notifier).setLocale('it'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: l.firstName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l.nameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: l.lastName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l.nameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: l.phoneLabel,
                    border: const OutlineInputBorder(),
                  ),
                  initialCountryCode: 'BR',
                  // Bloqueia letras/símbolos: apenas dígitos em qualquer país.
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  // Assumimos a validação completa (o pacote sobrescreveria o
                  // retorno do validator com o length-check padrão se false).
                  disableLengthCheck: true,
                  onChanged: (phone) {
                    _phoneNumber = phone.completeNumber;
                  },
                  validator: (phone) {
                    final digits =
                        (phone?.number ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.isEmpty) {
                      return l.phoneRequired;
                    }
                    // REGEX apenas para o Brasil: celular = DDD + 9 + 8 dígitos.
                    if (phone?.countryCode == '+55' &&
                        !RegExp(r'^[1-9][0-9]9[0-9]{8}$').hasMatch(digits)) {
                      return l.phoneInvalidBr;
                    }
                    // Demais países: sem restrição de tamanho/REGEX.
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                Text(
                  l.displayAs,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
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

                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l.save, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withOpacity(0.1) : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cs.primary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

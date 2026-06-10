import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:copa2026/features/profile/providers/profile_stats_provider.dart';

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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      await Supabase.instance.client.from('profiles').update({
        'full_name': fullName,
        'display_preference': _displayPreference,
        'phone': _phoneNumber,
      }).eq('id', user.id);

      // Invalidate the provider so the ProfileScreen re-fetches the stats
      ref.invalidate(profileStatsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l.completeProfileTitle),
        // No drawer, no back button => force them to complete
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

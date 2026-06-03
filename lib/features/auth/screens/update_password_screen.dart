import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/core/constants.dart';
import 'package:copa2026/l10n/app_localizations.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final l = AppLocalizations.of(context)!;
    final password = _passCtrl.text;
    final confirmPassword = _confirmPassCtrl.text;

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.errorGeneric('A senha deve ter pelo menos 6 caracteres'))),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.errorGeneric('As senhas não coincidem'))),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.errorGeneric('Senha atualizada com sucesso!')),
            backgroundColor: kPrimaryGreen,
          ),
        );
        // User will be redirected automatically due to AuthChangeEvent.userUpdated
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
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
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualizar Senha'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.lock_reset, size: 80, color: cs.primary),
              const SizedBox(height: 20),
              Text(
                'Digite sua nova senha',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: l.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPassCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Confirmar ${l.password}',
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 32),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _updatePassword,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Salvar Nova Senha'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs) : super(Locale(_prefs.getString('locale') ?? 'pt'));

  Future<void> setLocale(String languageCode) async {
    // Cache local do idioma (a fonte de verdade do onboarding é a conta:
    // profiles.locale). Serve para a UI já abrir no idioma certo antes de o
    // perfil carregar.
    await _prefs.setString('locale', languageCode);
    state = Locale(languageCode);
  }
}

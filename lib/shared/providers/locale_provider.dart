import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await _prefs.setString('locale', languageCode);
    // Automatically flag that onboarding language selection is done
    await _prefs.setBool('has_selected_lang', true);
    state = Locale(languageCode);
  }

  bool get hasSelectedLanguage => _prefs.getBool('has_selected_lang') ?? false;
}

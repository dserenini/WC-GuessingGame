import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:copa2026/core/app_env.dart';
import 'package:copa2026/core/supabase_config.dart';
import 'package:copa2026/shared/providers/locale_provider.dart';
import 'package:copa2026/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
  }

  // Diagnóstico: confirma se a flag de staging chegou via --dart-define.
  debugPrint('[ENV] isStaging=$isStaging url=$supabaseUrl');

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      // Fluxo implícito (em vez do PKCE default): os links de confirmação de
      // e-mail e reset de senha funcionam mesmo quando abertos em um
      // dispositivo/navegador diferente do que iniciou o cadastro — o PKCE
      // exige o code_verifier guardado no device de origem, o que causava o
      // "às vezes não dá pra confirmar". Ver helper authRedirectTo().
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  } catch (e) {
    debugPrint("Failed to initialize Supabase: $e");
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const Copa2026App(),
    ),
  );
}

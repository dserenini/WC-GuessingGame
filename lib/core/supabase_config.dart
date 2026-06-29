// ─────────────────────────────────────────────────────────────────────────────
// SUPABASE CONFIGURATION
//
// HOW TO FILL THESE IN:
//   1. Go to https://supabase.com and create a project named "copa2026".
//   2. Navigate to Settings → API.
//   3. Copy "Project URL" → paste as supabaseUrl below.
//   4. Copy "anon public" key → paste as supabaseAnonKey below.
//
// ⚠️  NEVER commit the service_role key here.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get supabaseUrl {
  const envUrl = String.fromEnvironment('SUPABASE_URL');
  if (envUrl.isNotEmpty) return envUrl;
  return dotenv.env['SUPABASE_URL'] ?? '';
}

/// URL de redirect para os e-mails de auth (confirmação de cadastro e reset de
/// senha). No Flutter Web usamos a origem atual (`Uri.base.origin`) para que o
/// link aponte sempre para o domínio publicado de onde o usuário se cadastrou
/// — funciona em prod e staging sem hardcode. Fora da web (futuro mobile)
/// retorna null para deixar o Supabase usar o deep link configurado.
///
/// IMPORTANTE: o caminho passado precisa estar na allowlist de "Redirect URLs"
/// do projeto Supabase, senão o link vem vazio/quebrado.
String? authRedirectTo(String path) {
  if (!kIsWeb) return null;
  return '${Uri.base.origin}$path';
}

String get supabaseAnonKey {
  const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (envKey.isNotEmpty) return envKey;
  return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}

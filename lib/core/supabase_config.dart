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

import 'package:flutter_dotenv/flutter_dotenv.dart';

String get supabaseUrl {
  const envUrl = String.fromEnvironment('SUPABASE_URL');
  if (envUrl.isNotEmpty) return envUrl;
  return dotenv.env['SUPABASE_URL'] ?? '';
}

String get supabaseAnonKey {
  const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (envKey.isNotEmpty) return envKey;
  return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}

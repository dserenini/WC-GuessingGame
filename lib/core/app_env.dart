// ─────────────────────────────────────────────────────────────────────────────
// AMBIENTE DA APLICAÇÃO
//
// `isStaging` é true apenas quando o app é compilado/rodado com
//   --dart-define=APP_ENV=staging
// que é injetado automaticamente pelo run-staging.ps1.
//
// O build de PRODUÇÃO não passa esse define, então isStaging é sempre false lá.
// ─────────────────────────────────────────────────────────────────────────────

const String _appEnv = String.fromEnvironment('APP_ENV');

/// Indica se estamos rodando contra o ambiente de testes (staging).
bool get isStaging => _appEnv == 'staging';

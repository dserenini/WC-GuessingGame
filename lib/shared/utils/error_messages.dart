import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ERROR MESSAGES
//
// Traduz qualquer exceção em uma mensagem amigável e internacionalizada para
// exibir ao usuário (SnackBar/diálogo), em vez de mostrar a exceção crua.
//
// As regras de negócio do banco (check_bet_deadline) usam SQLSTATEs estáveis
// para que a mensagem que o usuário lê venha do app (traduzida), e não do texto
// fixo em português do trigger. Ver supabase/fix_error_codes.sql.
//   P0010 → partida já em andamento/encerrada
//   P0011 → menos de 1 hora para o início
//   P0012 → limite de Super Palpites atingido
// ─────────────────────────────────────────────────────────────────────────────
String describeError(AppLocalizations l, Object error) {
  // Erros de regra de negócio vindos do Postgres (triggers).
  if (error is PostgrestException) {
    switch (error.code) {
      case 'P0010':
        return l.errBetMatchStarted;
      case 'P0011':
        return l.errBetDeadlinePassed;
      case 'P0012':
        return l.errSuperPalpiteLimit;
    }
    return l.errGeneric;
  }

  // Erros de autenticação (login/cadastro/recuperação de senha).
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('credentials')) {
      return l.invalidLogin;
    }
    return l.errAuth;
  }

  // Timeout (dart:async — seguro para web).
  if (error is TimeoutException) {
    return l.errConnection;
  }

  // Falhas de rede comuns (sem importar dart:io, para manter compatível com web).
  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('clientexception') ||
      text.contains('connection')) {
    return l.errConnection;
  }

  return l.errGeneric;
}

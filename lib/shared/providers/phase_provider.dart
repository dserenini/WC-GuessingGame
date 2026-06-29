import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/core/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FASE DO BOLÃO — fonte única de verdade da "fase atual" do torneio.
//
// O bolão tem três fases conceituais. A fase controla, de forma global, QUAIS
// dados ficam visíveis para todos os usuários:
//   • groups   → só dados da Fase de Grupos. Mata-Mata escondido para todos.
//   • mixed    → ambos visíveis (grupos + mata-mata).
//   • knockout → só dados do Mata-Mata. Dados de grupos escondidos para todos.
//
// É gravada em `app_config.phase` (= {"phase": "groups"|"mixed"|"knockout"}),
// mesmo padrão de `reveal`/`knockout`. Trocada manualmente pelo Admin (ou via
// SQL), sem rebuild. O gate por usuário do mata-mata (inscrição paga,
// `profiles.knockout_unlocked`) permanece ORTOGONAL: a fase diz se o mata-mata
// existe para o torneio; a inscrição diz se ESTE usuário pode vê-lo.
// ─────────────────────────────────────────────────────────────────────────────

enum TournamentPhase { groups, mixed, knockout }

TournamentPhase _phaseFromString(String? v) {
  switch (v) {
    case 'mixed':
      return TournamentPhase.mixed;
    case 'knockout':
      return TournamentPhase.knockout;
    default:
      return TournamentPhase.groups;
  }
}

/// Fase atual lida de `app_config.phase`. Default seguro = groups (esconde o
/// mata-mata) se a chave estiver ausente ou inacessível.
final tournamentPhaseProvider = FutureProvider<TournamentPhase>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('app_config')
        .select('value')
        .eq('key', 'phase')
        .maybeSingle();
    if (data == null) return TournamentPhase.groups;
    final value = (data['value'] as Map?)?.cast<String, dynamic>() ?? {};
    return _phaseFromString(value['phase'] as String?);
  } catch (_) {
    return TournamentPhase.groups;
  }
});

/// Dados da Fase de Grupos visíveis? (fases groups + mixed). Na fase knockout,
/// tudo de grupos some. Default = true enquanto carrega (evita piscar/esconder
/// o que hoje é sempre visível).
final groupStageVisibleProvider = FutureProvider<bool>((ref) async {
  final p = await ref.watch(tournamentPhaseProvider.future);
  return p != TournamentPhase.knockout;
});

/// O USUÁRIO ATUAL participa da FASE DE GRUPOS? (`profiles.groups_unlocked` OU
/// admin). Espelha o gate por usuário do mata-mata (knockout_unlocked), mas é
/// INDEPENDENTE da fase: diz se a visão de grupos faz sentido para este usuário.
/// Quando false, as telas/estatísticas de grupos ficam INATIVAS para ele.
/// Default = true enquanto carrega (a maioria participou dos grupos).
final groupParticipantProvider = FutureProvider<bool>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  if (kAdminUids.contains(user.id)) return true;
  try {
    final row = await Supabase.instance.client
        .from('profiles')
        .select('groups_unlocked')
        .eq('id', user.id)
        .maybeSingle();
    return row?['groups_unlocked'] == true;
  } catch (_) {
    return true;
  }
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/providers/phase_provider.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';
import 'package:copa2026/features/ranking/providers/ranking_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MATA-MATA — providers de leitura
// ─────────────────────────────────────────────────────────────────────────────

/// Modo de exibição do chaveamento: true = árvore (bracket), false = lista.
final koBracketViewProvider = StateProvider<bool>((ref) => true);

/// Mata-mata disponível globalmente? Derivado da FASE do torneio
/// ([tournamentPhaseProvider]): existe nas fases `mixed` e `knockout`, some na
/// `groups`. Substitui a antiga flag `app_config.knockout.enabled` — agora o
/// liga/desliga global do mata-mata é a própria fase, trocada pelo Admin.
final knockoutEnabledProvider = FutureProvider<bool>((ref) async {
  final p = await ref.watch(tournamentPhaseProvider.future);
  return p == TournamentPhase.mixed || p == TournamentPhase.knockout;
});

/// Acesso do USUÁRIO ATUAL ao mata-mata = mata-mata aberto na fase atual E
/// (inscrição paga OU admin). Controla menu, rota e tela.
///   • Enquanto a fase for `groups` ([knockoutEnabledProvider] = false), ninguém
///     vê o mata-mata.
///   • Nas fases `mixed`/`knockout`, cada usuário só passa a ver depois que o
///     admin libera a inscrição do mata-mata (`profiles.knockout_unlocked` —
///     separada da do bolão principal). Admins veem sempre (para testes).
/// O gate de verdade (impedir apostar via API sem pagar) é o RLS de `ko_bet`;
/// este provider é a camada de UX (esconder).
final knockoutVisibleProvider = FutureProvider<bool>((ref) async {
  final enabled = await ref.watch(knockoutEnabledProvider.future);
  if (!enabled) return false;
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  if (kAdminUids.contains(user.id)) return true;
  try {
    final row = await Supabase.instance.client
        .from('profiles')
        .select('knockout_unlocked')
        .eq('id', user.id)
        .maybeSingle();
    return row?['knockout_unlocked'] == true;
  } catch (_) {
    return false;
  }
});

/// Todos os jogos do mata-mata, com as seleções (casa/visitante/quem avançou).
/// autoDispose: rebusca dados frescos toda vez que a tela é reaberta.
final koMatchesProvider = FutureProvider.autoDispose<List<KoMatch>>((ref) async {
  final response = await Supabase.instance.client.from('ko_match').select('''
        id, round, slot, match_no, home_slot_label, away_slot_label, match_date, home_score, away_score, home_pens, away_pens, status, api_fixture_id,
        home:teams!ko_match_home_team_id_fkey(id, name, flag_url, group_letter),
        away:teams!ko_match_away_team_id_fkey(id, name, flag_url, group_letter),
        advancing:teams!ko_match_advancing_team_id_fkey(id, name, flag_url, group_letter)
      ''').order('match_date', ascending: true);

  return (response as List)
      .map((m) => KoMatch.fromJson((m as Map).cast<String, dynamic>()))
      .toList();
});

/// Override manual do toggle de fase no Ranking/Ligas. null = segue o default
/// da fase do torneio (mata-mata na fase knockout; grupos nas demais); true =
/// mata-mata; false = fase de grupos.
final rankingViewKnockoutProvider = StateProvider<bool?>((ref) => null);

// ── Lógica de fase do Ranking/Ligas (fonte única p/ RankingScreen e
//    LeaguesScreen ficarem em sincronia) ──────────────────────────────────────

/// View "Mata-Mata" ativa no Ranking/Ligas?
///   • groups   → false (só grupos).
///   • mixed    → segue o toggle (default grupos), apenas p/ quem participa.
///   • knockout → true p/ quem participa do mata-mata.
final rankingShowKoProvider = Provider<bool>((ref) {
  final phase =
      ref.watch(tournamentPhaseProvider).valueOrNull ?? TournamentPhase.groups;
  final iParticipate = ref.watch(knockoutVisibleProvider).valueOrNull ?? false;
  final groupPart = ref.watch(groupParticipantProvider).valueOrNull ?? true;
  if (phase == TournamentPhase.knockout) return iParticipate;
  if (phase == TournamentPhase.mixed && iParticipate) {
    // Quem não participa da fase de grupos fica travado no Mata-Mata (não pode
    // alternar para a visão de grupos).
    if (!groupPart) return true;
    return ref.watch(rankingViewKnockoutProvider) ?? false;
  }
  return false;
});

/// O toggle de fase (Grupos/Mata-Mata) deve aparecer? Só na fase mista e p/ quem
/// participa do mata-mata (nas demais fases há só uma view possível).
final rankingShowToggleProvider = Provider<bool>((ref) {
  final phase =
      ref.watch(tournamentPhaseProvider).valueOrNull ?? TournamentPhase.groups;
  final iParticipate = ref.watch(knockoutVisibleProvider).valueOrNull ?? false;
  return phase == TournamentPhase.mixed && iParticipate;
});

/// "Fase de grupos encerrada" para ESTE usuário? Acontece na fase knockout para
/// quem não tem inscrição no mata-mata: grupos escondidos + sem acesso ao KO.
final groupStageClosedProvider = Provider<bool>((ref) {
  final phase =
      ref.watch(tournamentPhaseProvider).valueOrNull ?? TournamentPhase.groups;
  final iParticipate = ref.watch(knockoutVisibleProvider).valueOrNull ?? false;
  return phase == TournamentPhase.knockout && !iParticipate;
});

/// Ranking geral do mata-mata (mesmo formato de user_rankings → reusa a tela).
final koUserRankingProvider =
    FutureProvider.autoDispose<List<RankingEntry>>((ref) async {
  final data = await Supabase.instance.client
      .from('ko_user_rankings')
      .select()
      .order('rank', ascending: true);
  // Ranking de COMPETIÇÃO: empate mantém a posição e o próximo pula (3, 3, 5),
  // igual ao Ranking Geral da fase de grupos. A view já entrega o RANK() com
  // buracos — NÃO aplicar dense rank aqui.
  return (data as List)
      .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
      .toList();
});

/// Pontos do mata-mata do usuário logado (soma de ko_bet.points + bônus de
/// campeão), lidos de [koUserRankingProvider] (view ko_user_rankings). 0 se o
/// usuário não estiver no ranking (não participa / sem pontos).
final myKoPointsProvider = FutureProvider.autoDispose<int>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return 0;
  final entries = await ref.watch(koUserRankingProvider.future);
  for (final e in entries) {
    if (e.userId == uid) return e.totalPoints;
  }
  return 0;
});

/// Nº de placares CRAVADOS do mata-mata do usuário logado (de
/// [koExactRankingProvider], onde total_points = nº de cravadas).
final myKoExactHitsProvider = FutureProvider.autoDispose<int>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return 0;
  final entries = await ref.watch(koExactRankingProvider.future);
  for (final e in entries) {
    if (e.userId == uid) return e.totalPoints;
  }
  return 0;
});

/// Ranking de CRAVADAS do mata-mata (view ko_exact_score_rankings). Mesmo shape
/// de user_rankings: total_points carrega o nº de placares cravados.
final koExactRankingProvider =
    FutureProvider.autoDispose<List<RankingEntry>>((ref) async {
  final data = await Supabase.instance.client
      .from('ko_exact_score_rankings')
      .select()
      .order('rank', ascending: true);
  return applyDenseRank((data as List)
      .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
      .toList());
});

/// Ranking do mata-mata de uma liga (mesmo formato de league_rankings).
final koLeagueRankingProvider = FutureProvider.autoDispose
    .family<List<RankingEntry>, String>((ref, leagueId) async {
  final data = await Supabase.instance.client
      .from('ko_league_rankings')
      .select()
      .eq('league_id', leagueId)
      .order('rank', ascending: true);
  // Ranking de COMPETIÇÃO (empate → próximo pula: 3, 3, 5), igual às ligas da
  // fase de grupos. A view já entrega o RANK() com buracos — sem dense rank.
  return (data as List)
      .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
      .toList();
});

// ── Palpites do usuário logado ───────────────────────────────────────────────

/// Apostas de placar do usuário, por ko_match_id → (home, away).
final koMyBetsProvider =
    FutureProvider.autoDispose<Map<String, (int, int)>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return {};
  final rows = await Supabase.instance.client
      .from('ko_bet')
      .select('ko_match_id, home_score_bet, away_score_bet')
      .eq('user_id', uid);
  return {
    for (final r in (rows as List))
      r['ko_match_id'] as String:
          ((r['home_score_bet'] as num).toInt(), (r['away_score_bet'] as num).toInt()),
  };
});

/// Palpites de placar de OUTRO usuário no mata-mata (por ko_match_id). A RLS
/// `ko_bet_read` só devolve linhas de jogos já reveláveis (30 min antes / ao
/// vivo / encerrado), então jogos ainda fechados simplesmente não vêm.
final koUserBetsProvider = FutureProvider.autoDispose
    .family<Map<String, (int, int)>, String>((ref, userId) async {
  final rows = await Supabase.instance.client
      .from('ko_bet')
      .select('ko_match_id, home_score_bet, away_score_bet')
      .eq('user_id', userId);
  return {
    for (final r in (rows as List))
      r['ko_match_id'] as String: (
        (r['home_score_bet'] as num).toInt(),
        (r['away_score_bet'] as num).toInt()
      ),
  };
});

/// Todos os palpites de placar de UM jogo do mata-mata (por user_id). A RLS só
/// devolve algo quando o jogo já é revelável; antes disso vem vazio.
final koMatchBetsProvider = FutureProvider.autoDispose
    .family<Map<String, (int, int)>, String>((ref, koMatchId) async {
  final rows = await Supabase.instance.client
      .from('ko_bet')
      .select('user_id, home_score_bet, away_score_bet')
      .eq('ko_match_id', koMatchId);
  return {
    for (final r in (rows as List))
      r['user_id'] as String: (
        (r['home_score_bet'] as num).toInt(),
        (r['away_score_bet'] as num).toInt()
      ),
  };
});

/// Ações de escrita (aposta de placar).
final knockoutActionsProvider = Provider((ref) => KnockoutActions(ref));

class KnockoutActions {
  KnockoutActions(this.ref);
  final Ref ref;
  SupabaseClient get _c => Supabase.instance.client;

  /// Salva/atualiza a aposta de placar de um jogo. Lança em erro (deadline etc.).
  Future<void> saveBet({
    required String koMatchId,
    required int home,
    required int away,
  }) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return;

    await _c.from('ko_bet').upsert({
      'user_id': uid,
      'ko_match_id': koMatchId,
      'home_score_bet': home,
      'away_score_bet': away,
    }, onConflict: 'user_id,ko_match_id');

    ref.invalidate(koMyBetsProvider);
    ref.invalidate(koUserRankingProvider);
    ref.invalidate(koLeagueRankingProvider);
  }
}

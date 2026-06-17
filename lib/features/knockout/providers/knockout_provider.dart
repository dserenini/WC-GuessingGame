import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';
import 'package:copa2026/features/ranking/providers/ranking_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MATA-MATA — providers de leitura
// ─────────────────────────────────────────────────────────────────────────────

/// Modo de exibição do chaveamento: true = árvore (bracket), false = lista.
final koBracketViewProvider = StateProvider<bool>((ref) => true);

/// Flag server-driven `app_config.knockout.enabled`. Controla se o mata-mata
/// aparece no app (ligado no staging; desligado em prod até o cutover).
final knockoutEnabledProvider = FutureProvider<bool>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('app_config')
        .select('value')
        .eq('key', 'knockout')
        .maybeSingle();
    if (data == null) return false;
    final value = (data['value'] as Map?)?.cast<String, dynamic>() ?? {};
    return value['enabled'] == true;
  } catch (_) {
    return false;
  }
});

/// Todos os jogos do mata-mata, com as seleções (casa/visitante/quem avançou).
/// autoDispose: rebusca dados frescos toda vez que a tela é reaberta.
final koMatchesProvider = FutureProvider.autoDispose<List<KoMatch>>((ref) async {
  final response = await Supabase.instance.client.from('ko_match').select('''
        id, round, slot, match_date, home_score, away_score, home_pens, away_pens, status, api_fixture_id,
        home:teams!ko_match_home_team_id_fkey(id, name, flag_url, group_letter),
        away:teams!ko_match_away_team_id_fkey(id, name, flag_url, group_letter),
        advancing:teams!ko_match_advancing_team_id_fkey(id, name, flag_url, group_letter)
      ''').order('match_date', ascending: true);

  return (response as List)
      .map((m) => KoMatch.fromJson((m as Map).cast<String, dynamic>()))
      .toList();
});

/// Override do toggle de fase no Ranking/Ligas. null = automático (mata-mata
/// quando knockout.enabled); true = mata-mata; false = fase de grupos.
final rankingViewKnockoutProvider = StateProvider<bool?>((ref) => null);

/// Ranking geral do mata-mata (mesmo formato de user_rankings → reusa a tela).
final koUserRankingProvider =
    FutureProvider.autoDispose<List<RankingEntry>>((ref) async {
  final data = await Supabase.instance.client
      .from('ko_user_rankings')
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
  return applyDenseRank((data as List)
      .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
      .toList());
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

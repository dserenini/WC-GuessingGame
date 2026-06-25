import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/core/constants.dart';
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

/// Acesso do USUÁRIO ATUAL ao mata-mata = master global ligado E
/// (inscrição paga OU admin). Controla menu, rota e tela.
///   • Enquanto o master (`app_config.knockout.enabled`) estiver false, ninguém
///     vê — é o rollout "às escondidas".
///   • Com o master ligado, cada usuário só passa a ver depois que o admin
///     libera a inscrição do mata-mata (`profiles.knockout_unlocked` — separada
///     da do bolão principal), então vai aparecendo aos poucos. Admins veem
///     sempre (para testes).
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

/// A partir de quando o Ranking passa a abrir em "Mata-Mata" POR PADRÃO (UTC).
/// Vale só para participantes (ver [knockoutVisibleProvider]); antes disso, e
/// para não-participantes, o default continua sendo a fase de grupos. O toggle
/// segue disponível para todos. 29/06/2026 15:00 GMT+0 = início dos 16-avos.
final DateTime kKoRankingDefaultFrom = DateTime.utc(2026, 6, 29, 15, 0);

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

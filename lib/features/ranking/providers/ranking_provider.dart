import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/shared/models/bet.dart';

/// Converte o ranking para *dense ranking* (1, 2, 3...): cada grupo de empate
/// (mesmos pontos) compartilha a posição e o próximo grupo recebe sempre a
/// posição seguinte, independentemente de quantas pessoas estão empatadas.
///
/// As views do Supabase usam `RANK()`, que deixa buracos após empates
/// (1, 2, 2, 2, 5, ...). Esta função reescreve para `DENSE_RANK` no cliente.
/// Assume a lista já ordenada por pontos desc (que é como as views entregam,
/// via `ORDER BY rank`).
///
/// NOTA: o Ranking Geral e o de Ligas NÃO usam mais esta função — eles exibem
/// o `RANK()` cru da view (ranking de competição, com buracos), que é o
/// comportamento desejado. Mantida apenas para os rankings de Estatísticas
/// Avançadas (`stat_rankings_provider`).
List<RankingEntry> applyDenseRank(List<RankingEntry> entries) {
  final result = <RankingEntry>[];
  var dense = 0;
  int? lastPoints;
  for (final e in entries) {
    if (lastPoints == null || e.totalPoints != lastPoints) {
      dense += 1;
      lastPoints = e.totalPoints;
    }
    result.add(e.copyWith(rank: dense));
  }
  return result;
}

// autoDispose: re-subscribes and re-queries each time the Ranking screen is
// opened, so per-user totals (points and bet counts) reflect the current state
// instead of a stale snapshot from when the app first loaded.
final rankingProvider = StreamProvider.autoDispose<List<RankingEntry>>((ref) {
  final client = Supabase.instance.client;

  // Subscribe to bet changes â†’ triggers refresh
  final stream = client
      .from('bets')
      .stream(primaryKey: ['id'])
      .asyncMap((_) async {
        final data = await client
            .from('user_rankings')
            .select()
            .order('rank', ascending: true);
        return (data as List)
            .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
            .toList();
      });

  return stream;
});

// Ranking geral filtrado por rodada da fase de grupos (1, 2 ou 3). Vem da view
// `user_round_rankings`, que já calcula o RANK() com os mesmos critérios de
// desempate do ranking geral, porém escopados à rodada. Mesmo shape de
// RankingEntry (a coluna extra `round` é ignorada no fromJson). autoDispose +
// stream de `bets` para refletir mudanças, igual ao rankingProvider.
final roundRankingProvider =
    StreamProvider.autoDispose.family<List<RankingEntry>, int>((ref, round) {
  final client = Supabase.instance.client;

  final stream = client
      .from('bets')
      .stream(primaryKey: ['id'])
      .asyncMap((_) async {
        final data = await client
            .from('user_round_rankings')
            .select()
            .eq('round', round)
            .order('rank', ascending: true);
        return (data as List)
            .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
            .toList();
      });

  return stream;
});

final myLeaguesRankingProvider =
    FutureProvider.family<List<RankingEntry>, String>((ref, leagueId) async {
  final data = await Supabase.instance.client
      .from('league_rankings')
      .select()
      .eq('league_id', leagueId)
      .order('rank', ascending: true);

  return (data as List)
      .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
      .toList();
});

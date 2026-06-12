import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/shared/models/bet.dart';

/// Converte o ranking para *dense ranking* (1, 2, 3...): cada grupo de empate
/// (mesmos pontos) compartilha a posição e o próximo grupo recebe sempre a
/// posição seguinte, independentemente de quantas pessoas estão empatadas.
///
/// As views do Supabase (`user_rankings` / `league_rankings`) usam `RANK()`,
/// que deixa buracos após empates (1, 1, ... , 8, ...). Aqui reescrevemos para
/// `DENSE_RANK` no cliente. Assume a lista já ordenada por pontos desc (que é
/// como as views entregam, via `ORDER BY rank`).
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
        return applyDenseRank((data as List)
            .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
            .toList());
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

  return applyDenseRank((data as List)
      .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
      .toList());
});

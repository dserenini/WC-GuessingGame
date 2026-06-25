import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MATA-MATA — modalidade "Bolão" das Estatísticas Avançadas (agregados do KO)
// ─────────────────────────────────────────────────────────────────────────────

/// Um placar e quantas vezes foi apostado no mata-mata (agregado).
class KoScorePop {
  final int home;
  final int away;
  final int n;
  const KoScorePop(this.home, this.away, this.n);

  String get label => '$home-$away';
}

final koScorePopularityProvider =
    FutureProvider.autoDispose<List<KoScorePop>>((ref) async {
  final data =
      await Supabase.instance.client.from('ko_score_popularity').select();
  final list = (data as List)
      .map((r) => KoScorePop(
            (r['home_score_bet'] as num).toInt(),
            (r['away_score_bet'] as num).toInt(),
            (r['n'] as num).toInt(),
          ))
      .toList();
  list.sort((a, b) => b.n.compareTo(a.n));
  return list;
});

/// Cravadas por jogo FINALIZADO do mata-mata (para "imprevisíveis" / "todo
/// mundo sabia").
class KoMatchPredictability {
  final String matchId;
  final int exactCount;
  final int totalBets;
  const KoMatchPredictability(this.matchId, this.exactCount, this.totalBets);
}

final koMatchPredictabilityProvider =
    FutureProvider.autoDispose<List<KoMatchPredictability>>((ref) async {
  final data =
      await Supabase.instance.client.from('ko_match_predictability').select();
  return (data as List)
      .map((r) => KoMatchPredictability(
            r['match_id'] as String,
            (r['exact_count'] as num).toInt(),
            (r['total_bets'] as num).toInt(),
          ))
      .toList();
});

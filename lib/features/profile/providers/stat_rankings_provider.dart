import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/features/ranking/providers/ranking_provider.dart'
    show applyDenseRank;
import 'package:copa2026/shared/models/bet.dart';

/// Rankings estatísticos da família A ("Você vs. o Bolão"). Cada valor mapeia
/// uma view do Supabase com o mesmo shape de `user_rankings`, onde a coluna
/// `total_points` carrega o valor da métrica.
enum StatRanking {
  exactScore,
  brazilPoints,
  nearMiss,
  dailyTop,
  regularity,
  boldness,
  contrarian,
}

extension StatRankingView on StatRanking {
  String get viewName => switch (this) {
        StatRanking.exactScore => 'exact_score_rankings',
        StatRanking.brazilPoints => 'brazil_points_rankings',
        StatRanking.nearMiss => 'near_miss_rankings',
        StatRanking.dailyTop => 'daily_top_rankings',
        StatRanking.regularity => 'regularity_rankings',
        StatRanking.boldness => 'boldness_rankings',
        StatRanking.contrarian => 'contrarian_rankings',
      };
}

/// Busca um ranking estatístico a partir da view correspondente, já aplicando
/// *dense rank* no cliente (mesmo tratamento do ranking global).
///
/// Desenhado para, no futuro, aceitar um `leagueId` opcional e trocar a view
/// global pela variante por liga sem alterar widgets nem tela — basta evoluir
/// o parâmetro da family para `(StatRanking, String? leagueId)`.
final statRankingProvider =
    FutureProvider.family.autoDispose<List<RankingEntry>, StatRanking>(
        (ref, stat) async {
  final data = await Supabase.instance.client
      .from(stat.viewName)
      .select()
      .order('rank', ascending: true);

  return applyDenseRank((data as List)
      .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
      .toList());
});

/// Conjunto de match_ids em que [userId] foi "do contra que acertou" (cravou um
/// placar que < 20% do bolão apostou). Usado para filtrar o detalhe do jogador
/// quando se toca nesse ranking. A rarez exige dados cruzados do bolão, por isso
/// vem de uma view dedicada (`contrarian_matches`) em vez de cálculo no cliente.
final contrarianMatchesProvider =
    FutureProvider.family.autoDispose<Set<String>, String>((ref, userId) async {
  final data = await Supabase.instance.client
      .from('contrarian_matches')
      .select('match_id')
      .eq('user_id', userId);

  return {
    for (final r in (data as List))
      (r as Map<String, dynamic>)['match_id'] as String
  };
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/features/results/providers/evolution_selection_provider.dart';

/// Granularidade do gráfico de evolução: ao fim de cada JOGO (api_match_id 1..72)
/// ou ao fim de cada DIA de jogos. Trocada por um toggle na própria aba.
enum EvolutionGranularity { perGame, perDay }

/// Estado do toggle (jogo/dia). Default = por jogo (mais granular).
final evolutionGranularityProvider =
    StateProvider.autoDispose<EvolutionGranularity>(
        (ref) => EvolutionGranularity.perGame);

/// Um ponto da série: a POSIÇÃO (rank) de um usuário num instante do eixo X.
/// `x` é o índice ordinal (0-based) dentro dos snapshots disponíveis; o rótulo
/// real do eixo (nº do jogo ou data) fica em [EvolutionData.xLabels].
class EvolutionPoint {
  final String userId;
  final int x;
  final int rank;
  final int cumPoints;

  const EvolutionPoint({
    required this.userId,
    required this.x,
    required this.rank,
    required this.cumPoints,
  });
}

/// Resultado pronto para o gráfico: os pontos de todos os usuários + os rótulos
/// do eixo X (nº do jogo "12" ou data "21/06") + nº de participantes (p/ o eixo Y).
class EvolutionData {
  final List<EvolutionPoint> points;

  /// Rótulos do eixo X por índice ordinal — usado SÓ no modo "por dia" (datas).
  /// No modo "por jogo", o eixo X é o próprio número do jogo (1..72), então
  /// xLabels fica vazio.
  final List<String> xLabels;
  final bool byGame;
  final int maxRank;

  const EvolutionData({
    required this.points,
    required this.xLabels,
    required this.byGame,
    required this.maxRank,
  });

  bool get isEmpty => points.isEmpty;

  /// Séries agrupadas por usuário, já ordenadas por x.
  Map<String, List<EvolutionPoint>> get byUser {
    final map = <String, List<EvolutionPoint>>{};
    for (final p in points) {
      (map[p.userId] ??= []).add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.x.compareTo(b.x));
    }
    return map;
  }
}

String _formatDay(String isoDate) {
  // isoDate vem como 'YYYY-MM-DD'; exibe 'dd/MM'.
  final parts = isoDate.split('-');
  if (parts.length == 3) return '${parts[2]}/${parts[1]}';
  return isoDate;
}

/// Lê a view de evolução (por jogo ou por dia) e devolve [EvolutionData] pronto
/// para o gráfico. autoDispose: requery a cada abertura da aba; refletindo novos
/// resultados finalizados. Mesmo padrão de query de ranking_provider.dart.
final evolutionDataProvider = FutureProvider.autoDispose
    .family<EvolutionData, EvolutionGranularity>((ref, granularity) async {
  final client = Supabase.instance.client;
  final byGame = granularity == EvolutionGranularity.perGame;
  final view = byGame ? 'user_game_evolution' : 'user_day_evolution';
  final keyCol = byGame ? 'game_no' : 'match_day';

  // Buscamos SÓ os usuários desenhados: você + os adicionados à comparação.
  // A view tem uma linha por (usuário × jogo/dia); puxar TODOS estouraria o teto
  // de linhas da API do Supabase ("Max rows", padrão 1000) e cortava a série nos
  // primeiros jogos. Filtrando por user_id, o volume fica pequeno. O `rank` de
  // cada linha continua sendo a posição real entre TODOS (calculada na view).
  final me = client.auth.currentUser?.id;
  final ids = <String>{if (me != null) me, ...ref.watch(evolutionSelectionProvider)}
      .toList();
  if (ids.isEmpty) {
    return EvolutionData(
        points: const [], xLabels: const [], byGame: byGame, maxRank: 0);
  }

  final rows = await client
      .from(view)
      .select()
      .inFilter('user_id', ids)
      .order(keyCol, ascending: true)
      .order('rank', ascending: true)
      .limit(200000);

  final data = (rows as List).cast<Map<String, dynamic>>();
  if (data.isEmpty) {
    return EvolutionData(
        points: const [], xLabels: const [], byGame: byGame, maxRank: 0);
  }

  // Modo "por dia": o eixo X é ordinal (datas não são numéricas), então
  // mapeamos cada dia distinto para um índice e guardamos os rótulos (dd/MM).
  // Modo "por jogo": o eixo X é o próprio número do jogo (1..72).
  final dayKeys = <String>[];
  final dayIndex = <String, int>{};
  if (!byGame) {
    for (final r in data) {
      final k = r[keyCol].toString();
      if (!dayIndex.containsKey(k)) {
        dayIndex[k] = dayKeys.length;
        dayKeys.add(k);
      }
    }
  }

  var maxRank = 0;
  final points = <EvolutionPoint>[];
  for (final r in data) {
    final rank = (r['rank'] as num).toInt();
    if (rank > maxRank) maxRank = rank;
    final x = byGame
        ? (r['game_no'] as num).toInt()
        : dayIndex[r['match_day'].toString()]!;
    points.add(EvolutionPoint(
      userId: r['user_id'] as String,
      x: x,
      rank: rank,
      cumPoints: (r['cum_points'] as num?)?.toInt() ?? 0,
    ));
  }

  final xLabels = byGame ? const <String>[] : dayKeys.map(_formatDay).toList();
  return EvolutionData(
      points: points, xLabels: xLabels, byGame: byGame, maxRank: maxRank);
});

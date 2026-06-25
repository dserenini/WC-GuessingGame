import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/shared/models/team.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MATA-MATA — palpite de CAMPEÃO (1 por usuário; fecha no início do mata-mata)
// ─────────────────────────────────────────────────────────────────────────────

/// Todas as seleções, para o seletor de campeão (ordenadas por nome).
final koAllTeamsProvider = FutureProvider.autoDispose<List<TeamModel>>((ref) async {
  final data = await Supabase.instance.client
      .from('teams')
      .select('id, name, flag_url, group_letter')
      .order('name', ascending: true);
  return (data as List)
      .map((t) => TeamModel.fromJson((t as Map).cast<String, dynamic>()))
      .toList();
});

/// Seleções CLASSIFICADAS ao mata-mata (presentes em algum ko_match como
/// mandante/visitante), para o seletor de campeão. Enquanto o chaveamento não
/// estiver preenchido (times nulos), cai para todas as seleções.
final koQualifiedTeamsProvider =
    FutureProvider.autoDispose<List<TeamModel>>((ref) async {
  final matches = await ref.watch(koMatchesProvider.future);
  final byId = <String, TeamModel>{};
  for (final m in matches) {
    if (m.home != null) byId[m.home!.id] = m.home!;
    if (m.away != null) byId[m.away!.id] = m.away!;
  }
  if (byId.isEmpty) {
    return ref.watch(koAllTeamsProvider.future);
  }
  final list = byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  return list;
});

/// Palpite de campeão do usuário logado: time escolhido + pontos (bônus pós-final).
class ChampionPick {
  final String teamId;
  final int points;
  const ChampionPick({required this.teamId, required this.points});
}

final koChampionPickProvider =
    FutureProvider.autoDispose<ChampionPick?>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return null;
  final row = await Supabase.instance.client
      .from('ko_champion_pick')
      .select('team_id, points')
      .eq('user_id', uid)
      .maybeSingle();
  if (row == null) return null;
  return ChampionPick(
    teamId: row['team_id'] as String,
    points: (row['points'] as num?)?.toInt() ?? 0,
  );
});

/// Início do mata-mata = data do 1º jogo. É o prazo do palpite de campeão.
/// null quando ainda não há jogos com data (aí o palpite segue liberado).
final koFirstMatchDateProvider =
    FutureProvider.autoDispose<DateTime?>((ref) async {
  final matches = await ref.watch(koMatchesProvider.future);
  DateTime? earliest;
  for (final m in matches) {
    final d = m.matchDate;
    if (d == null) continue;
    if (earliest == null || d.isBefore(earliest)) earliest = d;
  }
  return earliest;
});

/// Distribuição dos palpites de campeão (quantos escolheram cada seleção).
/// Só aparece depois que o mata-mata começa (RLS de ko_champion_pick).
class ChampionCount {
  final TeamModel team;
  final int count;
  const ChampionCount({required this.team, required this.count});
}

final koChampionDistributionProvider =
    FutureProvider.autoDispose<List<ChampionCount>>((ref) async {
  final teams = await ref.watch(koAllTeamsProvider.future);
  final byId = {for (final t in teams) t.id: t};
  final rows = await Supabase.instance.client
      .from('ko_champion_pick')
      .select('team_id');
  final counts = <String, int>{};
  for (final r in (rows as List)) {
    final id = (r as Map)['team_id'] as String;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  final list = <ChampionCount>[];
  counts.forEach((id, c) {
    final t = byId[id];
    if (t != null) list.add(ChampionCount(team: t, count: c));
  });
  list.sort((a, b) => b.count.compareTo(a.count));
  return list;
});

/// Ações de escrita do palpite de campeão.
final championPickActionsProvider = Provider((ref) => ChampionPickActions(ref));

class ChampionPickActions {
  ChampionPickActions(this.ref);
  final Ref ref;
  SupabaseClient get _c => Supabase.instance.client;

  /// Salva/atualiza o palpite de campeão. Lança em erro (prazo etc.).
  Future<void> save(String teamId) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return;
    await _c.from('ko_champion_pick').upsert({
      'user_id': uid,
      'team_id': teamId,
    }, onConflict: 'user_id');

    ref.invalidate(koChampionPickProvider);
    ref.invalidate(koChampionDistributionProvider);
    ref.invalidate(koUserRankingProvider);
    ref.invalidate(koLeagueRankingProvider);
  }
}

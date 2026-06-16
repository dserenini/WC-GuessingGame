import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/leagues/providers/leagues_provider.dart';
import 'package:copa2026/features/profile/providers/pool_stats_provider.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/models/match.dart';

/// Tiered achievements (bronze/prata/ouro shown side by side).
const List<String> kExactTierKeys = [
  'exatos_bronze', // 1 exact
  'exatos_prata', //  3 exact
  'exatos_ouro', //   5 exact
];
const List<String> kStreakTierKeys = [
  'embalado_bronze', // 3 in a row
  'embalado_prata', //  5 in a row
  'embalado_ouro', //   7 in a row
];
const List<String> kNearMissTierKeys = [
  'quasela_bronze', // 5 near-misses
  'quasela_prata', //  10 near-misses
  'quasela_ouro', //   15 near-misses
];
const List<List<String>> kAchievementTierGroups = [
  kExactTierKeys,
  kStreakTierKeys,
  kNearMissTierKeys,
];
const Set<String> kAchievementTierKeys = {
  'exatos_bronze', 'exatos_prata', 'exatos_ouro',
  'embalado_bronze', 'embalado_prata', 'embalado_ouro',
  'quasela_bronze', 'quasela_prata', 'quasela_ouro',
};

class AchievementState {
  final String key;
  final int current;
  final int target;
  final List<String> evidence; // match ids that count towards/completed it
  const AchievementState({
    required this.key,
    required this.current,
    required this.target,
    this.evidence = const [],
  });

  bool get unlocked => target > 0 && current >= target;
  double get progress => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);
}

/// Computes every achievement's progress from the user's bets + match results.
/// Returns null while any source is still loading.
final achievementStatesProvider = Provider<List<AchievementState>?>((ref) {
  final matches = ref.watch(allMatchesProvider).valueOrNull;
  final bets = ref.watch(allBetsProvider).valueOrNull;
  final pred = ref.watch(matchPredictabilityProvider).valueOrNull;
  final leagues = ref.watch(myLeaguesProvider).valueOrNull;
  if (matches == null || bets == null || pred == null || leagues == null) {
    return null;
  }
  final fraction = <String, double>{
    for (final p in pred)
      if (p.totalBets > 0) p.matchId: p.exactCount / p.totalBets,
  };
  return _compute(matches, bets, fraction, leagues.length);
});

List<AchievementState> _compute(
  List<MatchModel> matches,
  Map<String, BetModel> bets,
  Map<String, double> fraction,
  int leaguesCount,
) {
  bool finished(MatchModel m) =>
      m.status == MatchStatus.finished &&
      m.homeScore != null &&
      m.awayScore != null;

  final exactIds = <String>[];
  final drawExactIds = <String>[];
  final boldExactIds = <String>[];
  final profetaIds = <String>[];
  final brazilIds = <String>[];
  final nearMissIds = <String>[];
  final scoredIds = <String>[];
  final groupPoints = <String, int>{};
  final groupScoredIds = <String, List<String>>{};
  final groupsScored = <String>{};
  int totalPoints = 0;

  // per-day (São Paulo) tallies for "Dia Cheio"
  final dayTotal = <String, int>{};
  final dayScored = <String, int>{};
  final dayIds = <String, List<String>>{};
  const spOffset = Duration(hours: -3);

  for (final m in matches) {
    if (!finished(m)) continue;
    final b = bets[m.id];

    final sp = (m.matchDate ?? DateTime(0)).toUtc().add(spOffset);
    final dayKey = '${sp.year}-${sp.month}-${sp.day}';
    dayTotal[dayKey] = (dayTotal[dayKey] ?? 0) + 1;
    dayIds.putIfAbsent(dayKey, () => []).add(m.id);

    if (b == null) continue;
    totalPoints += b.points;

    if (b.points > 0) {
      scoredIds.add(m.id);
      groupsScored.add(m.groupLetter);
      groupPoints[m.groupLetter] = (groupPoints[m.groupLetter] ?? 0) + b.points;
      groupScoredIds.putIfAbsent(m.groupLetter, () => []).add(m.id);
      dayScored[dayKey] = (dayScored[dayKey] ?? 0) + 1;
    }

    final isBrazil =
        m.homeTeam.name == 'Brasil' || m.awayTeam.name == 'Brasil';
    if (isBrazil && b.points > 0) brazilIds.add(m.id);

    if (b.points == 3) {
      exactIds.add(m.id);
      if (m.homeScore == m.awayScore) drawExactIds.add(m.id);
      if ((b.homeScoreBet - b.awayScoreBet).abs() >= 5 ||
          (b.homeScoreBet + b.awayScoreBet) >= 7) {
        boldExactIds.add(m.id);
      }
      final f = fraction[m.id];
      if (f != null && f < 0.10) profetaIds.add(m.id);
    } else {
      final d = (b.homeScoreBet - m.homeScore!).abs() +
          (b.awayScoreBet - m.awayScore!).abs();
      if (d == 1) nearMissIds.add(m.id);
    }
  }

  // Longest streak of consecutive finished games scoring > 0 (by date).
  final sorted = [...matches]..sort((a, b) =>
      (a.matchDate ?? DateTime(0)).compareTo(b.matchDate ?? DateTime(0)));
  int longest = 0, cur = 0;
  var curIds = <String>[];
  var streakIds = <String>[];
  for (final m in sorted) {
    if (!finished(m)) continue;
    final b = bets[m.id];
    if (b != null && b.points > 0) {
      cur++;
      curIds.add(m.id);
      if (cur > longest) {
        longest = cur;
        streakIds = List<String>.from(curIds);
      }
    } else {
      cur = 0;
      curIds = [];
    }
  }

  // "Dia Cheio" só conta dias com pelo menos 3 jogos — senão quem pontuou no
  // único jogo de um dia ganharia o emblema de graça. Melhor dia = maior razão
  // acertos/jogos (desempate: mais jogos).
  const minGamesForFullDay = 3;
  String? bestDay;
  for (final k in dayTotal.keys) {
    if (dayTotal[k]! < minGamesForFullDay) continue;
    if (bestDay == null) {
      bestDay = k;
      continue;
    }
    final rNew = (dayScored[k] ?? 0) / dayTotal[k]!;
    final rBest = (dayScored[bestDay] ?? 0) / dayTotal[bestDay]!;
    if (rNew > rBest ||
        (rNew == rBest && dayTotal[k]! > dayTotal[bestDay]!)) {
      bestDay = k;
    }
  }

  // Best group (most points) for "Dono do Grupo".
  String? bestGroup;
  groupPoints.forEach((g, p) {
    if (bestGroup == null || p > groupPoints[bestGroup]!) bestGroup = g;
  });

  AchievementState exact(String key, int target) =>
      AchievementState(key: key, current: exactIds.length, target: target, evidence: exactIds);

  return [
    exact('exatos_bronze', 1),
    exact('exatos_prata', 3),
    exact('exatos_ouro', 5),
    AchievementState(key: 'embalado_bronze', current: longest, target: 3, evidence: streakIds),
    AchievementState(key: 'embalado_prata', current: longest, target: 5, evidence: streakIds),
    AchievementState(key: 'embalado_ouro', current: longest, target: 7, evidence: streakIds),
    AchievementState(
        key: 'empate',
        current: drawExactIds.isEmpty ? 0 : 1,
        target: 1,
        evidence: drawExactIds),
    AchievementState(
        key: 'ousadia',
        current: boldExactIds.isEmpty ? 0 : 1,
        target: 1,
        evidence: boldExactIds),
    AchievementState(
        key: 'diacheio',
        current: bestDay == null ? 0 : (dayScored[bestDay] ?? 0),
        target: bestDay == null ? minGamesForFullDay : dayTotal[bestDay]!,
        evidence: bestDay == null ? const [] : (dayIds[bestDay] ?? const [])),
    AchievementState(
        key: 'voltamundo',
        current: groupsScored.length,
        target: kGroups.length,
        evidence: scoredIds),
    AchievementState(
        key: 'donogrupo',
        current: bestGroup == null ? 0 : groupPoints[bestGroup]!,
        target: 6,
        evidence: bestGroup == null ? const [] : (groupScoredIds[bestGroup] ?? const [])),
    AchievementState(
        key: 'brasil',
        current: brazilIds.isEmpty ? 0 : 1,
        target: 1,
        evidence: brazilIds),
    AchievementState(
        key: 'profeta',
        current: profetaIds.isEmpty ? 0 : 1,
        target: 1,
        evidence: profetaIds),
    AchievementState(key: 'panela', current: leaguesCount, target: 1),
    AchievementState(
        key: 'meioseculo', current: totalPoints, target: 50, evidence: scoredIds),
    AchievementState(
        key: 'quasela_bronze',
        current: nearMissIds.length,
        target: 5,
        evidence: nearMissIds),
    AchievementState(
        key: 'quasela_prata',
        current: nearMissIds.length,
        target: 10,
        evidence: nearMissIds),
    AchievementState(
        key: 'quasela_ouro',
        current: nearMissIds.length,
        target: 15,
        evidence: nearMissIds),
  ];
}

/// Persists newly-unlocked achievements for the current user. Returns the map
/// of achievement_key -> unlocked_at plus the keys granted in THIS run (so the
/// UI can pop a celebration for them).
final achievementSyncProvider = FutureProvider.autoDispose<
    ({Map<String, DateTime> unlocked, List<String> newlyGranted})>((ref) async {
  final states = ref.watch(achievementStatesProvider);
  if (states == null) return (unlocked: <String, DateTime>{}, newlyGranted: <String>[]);
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return (unlocked: <String, DateTime>{}, newlyGranted: <String>[]);

  final rows = await client
      .from('user_achievements')
      .select('achievement_key, unlocked_at')
      .eq('user_id', uid);
  final persisted = <String, DateTime>{
    for (final r in (rows as List))
      (r as Map<String, dynamic>)['achievement_key'] as String:
          DateTime.parse(r['unlocked_at'] as String),
  };

  final unlocked = states.where((s) => s.unlocked).map((s) => s.key).toSet();
  final missing = unlocked.difference(persisted.keys.toSet()).toList();
  if (missing.isNotEmpty) {
    await client.rpc('grant_achievements', params: {'p_keys': missing});
    final now = DateTime.now();
    for (final k in missing) {
      persisted[k] = now;
    }
  }
  return (unlocked: persisted, newlyGranted: missing);
});

/// How many players hold each achievement, plus the participant total, so the
/// UI can show "% of players".
final achievementRarityProvider =
    FutureProvider.autoDispose<({Map<String, int> counts, int total})>((ref) async {
  // Refresh after our own grant so our newly-earned badges count.
  ref.watch(achievementSyncProvider);
  final client = Supabase.instance.client;
  final rows = await client.from('achievement_rarity').select();
  final counts = <String, int>{
    for (final r in (rows as List))
      (r as Map<String, dynamic>)['achievement_key'] as String:
          (r['n_users'] as num).toInt(),
  };
  final players =
      await client.from('profiles').select('id').eq('participate_in_ranking', true);
  return (counts: counts, total: (players as List).length);
});

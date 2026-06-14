import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/models/match.dart';

/// A scoreline the user bet and how many times (for the signature top-3).
class ScoreCount {
  final String score; // "2-1"
  final int count;
  const ScoreCount(this.score, this.count);
}

/// A team the user has bet on, with the total points earned in matches that
/// involved it (used for "lucky / unlucky team").
class TeamStat {
  final String name;
  final String? flagUrl;
  final int points;
  const TeamStat({required this.name, this.flagUrl, required this.points});
}

/// Personal ("Raio-X") statistics derived entirely on the client from the
/// current user's bets and the match results — no backend needed.
class PersonalStats {
  final Map<String, int> pointsByGroup; // points per group
  final List<String> finishedGroups; // A..L order, only groups with a played game
  final List<String> bestGroups; // tied groups at the max (among finished)
  final List<String> worstGroups; // tied groups at the min (empty if all equal)
  final int exact; // points == 3
  final int result; // points == 1
  final int zeros; // points == 0 (finished)
  final int totalPoints;
  final int maxPossible; // finishedBets * 3
  final List<ScoreCount> topScores; // top-3 most-used scorelines
  final double? avgPredicted; // goals/match the user predicts (finished bets)
  final double? avgReal; // real goals/match in those same games
  final TeamStat? luckyTeam;
  final TeamStat? unluckyTeam;
  final int longestStreak; // consecutive finished games scoring > 0
  final List<String> streakMatchIds; // matches forming that streak
  final int finishedBets;
  final int totalBets;

  const PersonalStats({
    required this.pointsByGroup,
    required this.finishedGroups,
    required this.bestGroups,
    required this.worstGroups,
    required this.exact,
    required this.result,
    required this.zeros,
    required this.totalPoints,
    required this.maxPossible,
    required this.topScores,
    required this.avgPredicted,
    required this.avgReal,
    required this.luckyTeam,
    required this.unluckyTeam,
    required this.longestStreak,
    required this.streakMatchIds,
    required this.finishedBets,
    required this.totalBets,
  });

  double get utilization => maxPossible == 0 ? 0 : totalPoints / maxPossible;
  bool get hasFinished => finishedBets > 0;
}

/// Derives [PersonalStats] from the global matches + the user's own bets.
/// Returns null while either source is still loading.
final personalStatsProvider = Provider<PersonalStats?>((ref) {
  final matches = ref.watch(allMatchesProvider).valueOrNull;
  final bets = ref.watch(allBetsProvider).valueOrNull;
  if (matches == null || bets == null) return null;
  return _compute(matches, bets);
});

PersonalStats _compute(List<MatchModel> matches, Map<String, BetModel> bets) {
  bool finished(MatchModel m) =>
      m.status == MatchStatus.finished &&
      m.homeScore != null &&
      m.awayScore != null;

  final pointsByGroup = {for (final g in kGroups) g: 0};
  final groupsWithFinished = <String>{};

  int exact = 0, result = 0, zeros = 0, totalPoints = 0, finishedBets = 0;
  int sumPredicted = 0, sumReal = 0;

  final scoreCounts = <String, int>{};
  final teamPoints = <String, int>{};
  final teamFlag = <String, String?>{};

  for (final m in matches) {
    final b = bets[m.id];
    if (b == null) continue;

    // Signature score uses every bet (a style trait, regardless of result).
    final key = '${b.homeScoreBet}-${b.awayScoreBet}';
    scoreCounts[key] = (scoreCounts[key] ?? 0) + 1;

    if (!finished(m)) continue;

    finishedBets++;
    totalPoints += b.points;
    if (pointsByGroup.containsKey(m.groupLetter)) {
      pointsByGroup[m.groupLetter] = pointsByGroup[m.groupLetter]! + b.points;
    }
    groupsWithFinished.add(m.groupLetter);

    if (b.points >= 3) {
      exact++;
    } else if (b.points == 1) {
      result++;
    } else {
      zeros++;
    }

    sumPredicted += b.homeScoreBet + b.awayScoreBet;
    sumReal += m.homeScore! + m.awayScore!;

    for (final t in [m.homeTeam, m.awayTeam]) {
      teamPoints[t.name] = (teamPoints[t.name] ?? 0) + b.points;
      teamFlag[t.name] = t.flagUrl;
    }
  }

  // Only groups with at least one played game count for best/worst (A..L order).
  final finishedGroups =
      kGroups.where((g) => groupsWithFinished.contains(g)).toList();
  var bestGroups = <String>[];
  var worstGroups = <String>[];
  if (finishedGroups.isNotEmpty) {
    final values = finishedGroups.map((g) => pointsByGroup[g]!);
    final maxPts = values.reduce((a, b) => a > b ? a : b);
    final minPts = values.reduce((a, b) => a < b ? a : b);
    bestGroups = finishedGroups.where((g) => pointsByGroup[g] == maxPts).toList();
    // Worst only makes sense when there's actual variation between groups.
    if (minPts < maxPts) {
      worstGroups =
          finishedGroups.where((g) => pointsByGroup[g] == minPts).toList();
    }
  }

  // Top-3 most-used scorelines.
  final topScores = scoreCounts.entries
      .map((e) => ScoreCount(e.key, e.value))
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  final top3Scores = topScores.take(3).toList();

  // Lucky / unlucky team (only meaningful with finished games).
  TeamStat? luckyTeam, unluckyTeam;
  String? bestTeam, worstTeam;
  teamPoints.forEach((name, p) {
    if (bestTeam == null || p > teamPoints[bestTeam]!) bestTeam = name;
    if (worstTeam == null || p < teamPoints[worstTeam]!) worstTeam = name;
  });
  if (bestTeam != null) {
    luckyTeam = TeamStat(
        name: bestTeam!, flagUrl: teamFlag[bestTeam], points: teamPoints[bestTeam]!);
  }
  if (worstTeam != null && worstTeam != bestTeam) {
    unluckyTeam = TeamStat(
        name: worstTeam!,
        flagUrl: teamFlag[worstTeam],
        points: teamPoints[worstTeam]!);
  }

  // Longest streak of consecutive finished games (by date) scoring > 0.
  final sorted = [...matches]..sort((a, b) =>
      (a.matchDate ?? DateTime(0)).compareTo(b.matchDate ?? DateTime(0)));
  int longestStreak = 0, current = 0;
  var currentIds = <String>[];
  var streakMatchIds = <String>[];
  for (final m in sorted) {
    if (!finished(m)) continue;
    final b = bets[m.id];
    if (b != null && b.points > 0) {
      current++;
      currentIds.add(m.id);
      if (current > longestStreak) {
        longestStreak = current;
        streakMatchIds = List<String>.from(currentIds);
      }
    } else {
      current = 0;
      currentIds = [];
    }
  }

  return PersonalStats(
    pointsByGroup: pointsByGroup,
    finishedGroups: finishedGroups,
    bestGroups: bestGroups,
    worstGroups: worstGroups,
    exact: exact,
    result: result,
    zeros: zeros,
    totalPoints: totalPoints,
    maxPossible: finishedBets * 3,
    topScores: top3Scores,
    avgPredicted: finishedBets == 0 ? null : sumPredicted / finishedBets,
    avgReal: finishedBets == 0 ? null : sumReal / finishedBets,
    luckyTeam: luckyTeam,
    unluckyTeam: unluckyTeam,
    longestStreak: longestStreak,
    streakMatchIds: streakMatchIds,
    finishedBets: finishedBets,
    totalBets: bets.length,
  );
}

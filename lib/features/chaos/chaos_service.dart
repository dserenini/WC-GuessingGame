import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';

final chaosModeProvider = StateProvider<bool>((ref) => false);

/// Agent of Chaos service — generates random scores
class ChaosService {
  static final _rng = Random();

  /// Random score bounded by [max] goals per team
  static (int, int) randomScore({int max = 5}) {
    return (_rng.nextInt(max + 1), _rng.nextInt(max + 1));
  }

  /// Random WIN for the specified side (never equal)
  static (int, int) randomWin({required bool isHome, int max = 5}) {
    int home, away;
    do {
      home = _rng.nextInt(max + 1);
      away = _rng.nextInt(max + 1);
    } while (isHome ? home <= away : away <= home);
    return (home, away);
  }

  /// Random DRAW (home == away)
  static (int, int) randomDraw({int max = 5}) {
    final score = _rng.nextInt(max + 1);
    return (score, score);
  }

  /// Generates random scores that strictly result in the requested standings
  /// Uses a rejection sampling algorithm to preserve true randomness and draws.
  static Map<String, (int, int)> generateRankedBets({
    required List<MatchModel> matches,
    required List<String> rankedTeamNames,
  }) {
    const int maxIterations = 1000;

    for (int i = 0; i < maxIterations; i++) {
      final Map<String, (int, int)> candidateScores = {};
      final Map<String, BetModel> simulatedBets = {};

      for (final m in matches) {
        final scores = randomScore(max: 5);
        candidateScores[m.id] = scores;
        simulatedBets[m.id] = BetModel(
          id: 'tmp',
          userId: 'tmp',
          matchId: m.id,
          homeScoreBet: scores.$1,
          awayScoreBet: scores.$2,
          points: 0,
        );
      }

      final standings = computeStandings(matches: matches, bets: simulatedBets);

      bool isPerfectMatch = true;
      for (int j = 0; j < rankedTeamNames.length; j++) {
        if (standings.length <= j || standings[j].teamName != rankedTeamNames[j]) {
          isPerfectMatch = false;
          break;
        }
      }

      if (isPerfectMatch) {
        return candidateScores;
      }
    }

    // Fallback if rejection sampling fails after 1000 iterations:
    // Deterministic generation ensuring strict wins for higher ranked teams.
    final Map<String, (int, int)> fallbackScores = {};
    for (final m in matches) {
      final homeRank = rankedTeamNames.indexOf(m.homeTeam.name);
      final awayRank = rankedTeamNames.indexOf(m.awayTeam.name);

      if (homeRank < awayRank) {
        fallbackScores[m.id] = randomWin(isHome: true);
      } else {
        fallbackScores[m.id] = randomWin(isHome: false);
      }
    }
    return fallbackScores;
  }
}

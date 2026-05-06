import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/core/constants.dart';

import 'package:copa2026/features/auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────
// GLOBAL MATCHES & BETS
// ─────────────────────────────────────────────
final allMatchesProvider = FutureProvider<List<MatchModel>>((ref) async {
  final response = await Supabase.instance.client
      .from('matches')
      .select('''
        id,
        group_letter,
        match_date,
        home_score,
        away_score,
        status,
        api_match_id,
        home_team:teams!matches_home_team_id_fkey(id, name, flag_url, group_letter),
        away_team:teams!matches_away_team_id_fkey(id, name, flag_url, group_letter)
      ''')
      .order('match_date', ascending: true);

  return (response as List)
      .map((m) => MatchModel.fromJson(m as Map<String, dynamic>))
      .toList();
});

final allBetsProvider = FutureProvider<Map<String, BetModel>>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return {};

  final bets = await Supabase.instance.client
      .from('bets')
      .select()
      .eq('user_id', userId);

  return {
    for (final b in (bets as List))
      (b as Map<String, dynamic>)['match_id'] as String: BetModel.fromJson(b),
  };
});

// ─────────────────────────────────────────────
// SPECIFIC GROUP SCOPE (Derived)
// ─────────────────────────────────────────────
final groupMatchesProvider = Provider.family<AsyncValue<List<MatchModel>>, String>((ref, groupLetter) {
  return ref.watch(allMatchesProvider).whenData((matches) {
    final groupMatches = matches.where((m) => m.groupLetter == groupLetter).toList();
    groupMatches.sort((a, b) {
      final idA = int.tryParse(a.apiMatchId ?? '') ?? 0;
      final idB = int.tryParse(b.apiMatchId ?? '') ?? 0;
      return idA.compareTo(idB);
    });
    return groupMatches;
  });
});

final groupBetsProvider = Provider.family<AsyncValue<Map<String, BetModel>>, String>((ref, groupLetter) {
  return ref.watch(allBetsProvider);
});

// ─────────────────────────────────────────────
// BEST 3RD PLACES ACROSS TOURNAMENT
// ─────────────────────────────────────────────
final bestThirdPlacesProvider = Provider<Set<String>>((ref) {
  final matches = ref.watch(allMatchesProvider).valueOrNull;
  final bets = ref.watch(allBetsProvider).valueOrNull;

  if (matches == null || bets == null) return {};

  final Map<String, List<MatchModel>> groupedMatches = {};
  for (final m in matches) {
    groupedMatches.putIfAbsent(m.groupLetter, () => []).add(m);
  }

  final List<StandingEntry> thirdPlaces = [];
  for (final group in groupedMatches.values) {
    final standings = computeStandings(matches: group, bets: bets);
    if (standings.length > 2) {
      thirdPlaces.add(standings[2]); // Index 2 is the 3rd placed team
    }
  }

  // Sort them mathematically: Pts -> GoalDiff -> GoalsFor
  thirdPlaces.sort((a, b) {
    if (b.points != a.points) return b.points.compareTo(a.points);
    if (b.goalDiff != a.goalDiff) return b.goalDiff.compareTo(a.goalDiff);
    if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);
    return a.teamName.compareTo(b.teamName); // Fallback alphabetical
  });

  // Top 8 advance
  return thirdPlaces.take(8).map((e) => e.teamName).toSet();
});

// ─────────────────────────────────────────────
// BET SAVE NOTIFIER
// ─────────────────────────────────────────────
final betNotifierProvider =
    StateNotifierProvider<BetNotifier, AsyncValue<void>>((ref) {
  return BetNotifier(ref);
});

class BetNotifier extends StateNotifier<AsyncValue<void>> {
  BetNotifier(this.ref) : super(const AsyncData(null));
  final Ref ref;

  Future<void> saveBet({
    required String matchId,
    required String groupLetter,
    required int homeScore,
    required int awayScore,
  }) async {
    if (isBettingLocked) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('bets').upsert({
        'user_id': userId,
        'match_id': matchId,
        'home_score_bet': homeScore,
        'away_score_bet': awayScore,
      }, onConflict: 'user_id,match_id');

      // Invalidate to refresh
      ref.invalidate(allBetsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteBet({
    required String matchId,
    required String groupLetter,
  }) async {
    if (isBettingLocked) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      await Supabase.instance.client
          .from('bets')
          .delete()
          .eq('user_id', userId)
          .eq('match_id', matchId);

      ref.invalidate(allBetsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> clearGroupBets({
    required List<String> matchIds,
    required String groupLetter,
  }) async {
    if (isBettingLocked || matchIds.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    state = const AsyncLoading();
    try {
      await Supabase.instance.client
          .from('bets')
          .delete()
          .eq('user_id', userId)
          .inFilter('match_id', matchIds);

      ref.invalidate(allBetsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Admin override for a user's bet
  Future<void> adminOverrideBet({
    required String userId,
    required String matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    await Supabase.instance.client.from('bets').upsert({
      'user_id': userId,
      'match_id': matchId,
      'home_score_bet': homeScore,
      'away_score_bet': awayScore,
    }, onConflict: 'user_id,match_id');
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// STANDINGS COMPUTATION (LOCAL)
// Computes group standings from user bets
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class StandingEntry {
  final String teamName;
  final String? flagUrl;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  StandingEntry({required this.teamName, this.flagUrl});

  int get points => won * 3 + drawn;
  int get goalDiff => goalsFor - goalsAgainst;
}

List<StandingEntry> computeStandings({
  required List<MatchModel> matches,
  required Map<String, BetModel> bets,
}) {
  final Map<String, StandingEntry> table = {};

  for (final m in matches) {
    // Use real scores if finished, otherwise use user's bet
    final int? home;
    final int? away;

    if (m.status == MatchStatus.finished) {
      home = m.homeScore;
      away = m.awayScore;
    } else {
      final bet = bets[m.id];
      home = bet?.homeScoreBet;
      away = bet?.awayScoreBet;
    }

    final homeTeam = m.homeTeam.name;
    final awayTeam = m.awayTeam.name;

    table.putIfAbsent(homeTeam,
        () => StandingEntry(teamName: homeTeam, flagUrl: m.homeTeam.flagUrl));
    table.putIfAbsent(awayTeam,
        () => StandingEntry(teamName: awayTeam, flagUrl: m.awayTeam.flagUrl));

    if (home == null || away == null) continue;

    final h = table[homeTeam]!;
    final a = table[awayTeam]!;

    h.played++;
    a.played++;
    h.goalsFor += home;
    h.goalsAgainst += away;
    a.goalsFor += away;
    a.goalsAgainst += home;

    if (home > away) {
      h.won++;
      a.lost++;
    } else if (home < away) {
      a.won++;
      h.lost++;
    } else {
      h.drawn++;
      a.drawn++;
    }
  }

  final list = table.values.toList()
    ..sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.goalDiff != a.goalDiff) return b.goalDiff.compareTo(a.goalDiff);
      if (b.goalsFor != a.goalsFor) return b.goalsFor.compareTo(a.goalsFor);

      // Head-to-Head
      final match = matches.firstWhereOrNull((m) =>
          (m.homeTeam.name == a.teamName && m.awayTeam.name == b.teamName) ||
          (m.homeTeam.name == b.teamName && m.awayTeam.name == a.teamName));

      if (match != null) {
        int? scoreA;
        int? scoreB;

        if (match.status == MatchStatus.finished) {
          scoreA = match.homeTeam.name == a.teamName ? match.homeScore : match.awayScore;
          scoreB = match.homeTeam.name == b.teamName ? match.homeScore : match.awayScore;
        } else {
          final bet = bets[match.id];
          if (bet != null) {
            scoreA = match.homeTeam.name == a.teamName ? bet.homeScoreBet : bet.awayScoreBet;
            scoreB = match.homeTeam.name == b.teamName ? bet.homeScoreBet : bet.awayScoreBet;
          }
        }

        if (scoreA != null && scoreB != null) {
          if (scoreB != scoreA) return scoreB.compareTo(scoreA); // Winner goes above
        }
      }

      // Alphabetical
      return a.teamName.compareTo(b.teamName);
    });

  return list;
}

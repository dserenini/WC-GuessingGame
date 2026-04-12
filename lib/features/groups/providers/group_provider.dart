import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/core/constants.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// MATCHES PER GROUP
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final groupMatchesProvider =
    FutureProvider.family<List<MatchModel>, String>((ref, groupLetter) async {
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
      .eq('group_letter', groupLetter)
      .order('match_date', ascending: true);

  return (response as List)
      .map((m) => MatchModel.fromJson(m as Map<String, dynamic>))
      .toList();
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// USER BETS FOR A GROUP
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final groupBetsProvider =
    FutureProvider.family<Map<String, BetModel>, String>((ref, groupLetter) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return {};

  // Get all match IDs for this group first
  final matchIds = await Supabase.instance.client
      .from('matches')
      .select('id')
      .eq('group_letter', groupLetter);

  final ids = (matchIds as List).map((m) => m['id'] as String).toList();
  if (ids.isEmpty) return {};

  final bets = await Supabase.instance.client
      .from('bets')
      .select()
      .eq('user_id', userId)
      .inFilter('match_id', ids);

  return {
    for (final b in (bets as List))
      (b as Map<String, dynamic>)['match_id'] as String: BetModel.fromJson(b),
  };
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// BET SAVE NOTIFIER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      ref.invalidate(groupBetsProvider(groupLetter));
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
      return b.goalsFor.compareTo(a.goalsFor);
    });

  return list;
}

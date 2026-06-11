import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/shared/models/bet.dart';

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
        return (data as List)
            .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
            .toList();
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

  return (data as List)
      .map((r) => RankingEntry.fromJson(r as Map<String, dynamic>))
      .toList();
});

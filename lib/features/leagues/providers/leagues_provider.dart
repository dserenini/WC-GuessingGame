import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/shared/models/bet.dart';

import 'package:copa2026/features/auth/providers/auth_provider.dart';

final myLeaguesProvider = FutureProvider<List<LeagueModel>>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await Supabase.instance.client
      .from('league_members')
      .select('leagues(*)')
      .eq('user_id', userId);

  return (data as List)
      .map((r) => LeagueModel.fromJson(
          (r as Map<String, dynamic>)['leagues'] as Map<String, dynamic>))
      .toList();
});

/// Every bet placed on a single match, keyed by user_id. RLS allows reading all
/// bets (`bets` SELECT USING (true)), so this returns all users' bets; callers
/// intersect with a league's member list to scope it. autoDispose so each open
/// of the league scorelines view re-fetches the current state.
final matchBetsProvider =
    FutureProvider.autoDispose.family<Map<String, BetModel>, String>(
        (ref, matchId) async {
  final rows = await Supabase.instance.client
      .from('bets')
      .select()
      .eq('match_id', matchId);

  return {
    for (final b in (rows as List))
      (b as Map<String, dynamic>)['user_id'] as String: BetModel.fromJson(b),
  };
});

final leagueNotifierProvider =
    StateNotifierProvider<LeagueNotifier, AsyncValue<void>>((ref) {
  return LeagueNotifier(ref);
});

class LeagueNotifier extends StateNotifier<AsyncValue<void>> {
  LeagueNotifier(this.ref) : super(const AsyncData(null));
  final Ref ref;
  final _client = Supabase.instance.client;

  Future<void> createLeague(String name) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    try {
      final result = await _client
          .from('leagues')
          .insert({'name': name, 'owner_id': userId})
          .select()
          .single();

      // Auto-join as owner
      await _client.from('league_members').insert({
        'league_id': result['id'],
        'user_id': userId,
      });

      ref.invalidate(myLeaguesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> joinLeague(String inviteCode) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    try {
      final league = await _client
          .from('leagues')
          .select('id')
          .eq('invite_code', inviteCode.toUpperCase())
          .single();

      await _client.from('league_members').insert({
        'league_id': league['id'],
        'user_id': userId,
      });

      ref.invalidate(myLeaguesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> leaveLeague(String leagueId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    try {
      await _client
          .from('league_members')
          .delete()
          .match({'league_id': leagueId, 'user_id': userId});

      ref.invalidate(myLeaguesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

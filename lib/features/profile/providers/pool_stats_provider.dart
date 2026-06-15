import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A bettor's identity for the "who bet this" lists.
class PickerUser {
  final String userId;
  final String username;
  final String? fullName;
  final String displayPreference;
  final String? avatarUrl;

  const PickerUser({
    required this.userId,
    required this.username,
    this.fullName,
    required this.displayPreference,
    this.avatarUrl,
  });

  String get displayName =>
      (displayPreference == 'full_name' && fullName != null && fullName!.isNotEmpty)
          ? fullName!
          : username;

  factory PickerUser.fromJson(Map<String, dynamic> j) => PickerUser(
        userId: j['user_id'] as String,
        username: j['username'] as String? ?? '?',
        fullName: j['full_name'] as String?,
        displayPreference: j['display_preference'] as String? ?? 'username',
        avatarUrl: j['avatar_url'] as String?,
      );
}

/// One bettor's pick on a specific match (for the unique-scoreline detail).
class MatchPicker {
  final String matchId;
  final PickerUser user;
  const MatchPicker({required this.matchId, required this.user});
}

/// A scoreline and how many times it was bet across the whole pool.
class ScorePop {
  final int home;
  final int away;
  final int n;
  const ScorePop(this.home, this.away, this.n);

  int get diff => (home - away).abs();
  int get goals => home + away;
  String get label => '$home-$away';
}

/// The full scoreline distribution plus the pool total (for % math + lookups).
class ScorePopData {
  final List<ScorePop> all;
  final int total;
  const ScorePopData(this.all, this.total);

  /// Most-bet scorelines first.
  List<ScorePop> mostPopular(int take) {
    final l = [...all]..sort((a, b) => b.n.compareTo(a.n));
    return l.take(take).toList();
  }

  /// Least-bet first; ties broken by larger goal difference, then more goals.
  List<ScorePop> leastPopular(int take) {
    final l = [...all]..sort((a, b) {
        if (a.n != b.n) return a.n.compareTo(b.n);
        if (a.diff != b.diff) return b.diff.compareTo(a.diff);
        return b.goals.compareTo(a.goals);
      });
    return l.take(take).toList();
  }

  ScorePop? lookup(int home, int away) {
    for (final s in all) {
      if (s.home == home && s.away == away) return s;
    }
    return null;
  }
}

/// Exact-hit count per finished match.
class MatchPredictability {
  final String matchId;
  final int exactCount;
  final int totalBets;
  const MatchPredictability(this.matchId, this.exactCount, this.totalBets);
}

final scorePopularityProvider =
    FutureProvider.autoDispose<ScorePopData>((ref) async {
  final data = await Supabase.instance.client.from('score_popularity').select();
  final list = (data as List)
      .map((r) => ScorePop(
            (r['home_score_bet'] as num).toInt(),
            (r['away_score_bet'] as num).toInt(),
            (r['n'] as num).toInt(),
          ))
      .toList();
  final total = list.fold<int>(0, (a, s) => a + s.n);
  return ScorePopData(list, total);
});

final matchPredictabilityProvider =
    FutureProvider.autoDispose<List<MatchPredictability>>((ref) async {
  final data =
      await Supabase.instance.client.from('match_predictability').select();
  return (data as List)
      .map((r) => MatchPredictability(
            r['match_id'] as String,
            (r['exact_count'] as num).toInt(),
            (r['total_bets'] as num).toInt(),
          ))
      .toList();
});

/// Users who nailed the exact score on a given match.
final exactPickersProvider =
    FutureProvider.autoDispose.family<List<PickerUser>, String>((ref, matchId) async {
  final data = await Supabase.instance.client
      .from('bet_pickers')
      .select('user_id, username, full_name, display_preference, avatar_url')
      .eq('match_id', matchId)
      .eq('points', 3);
  return (data as List)
      .map((r) => PickerUser.fromJson(r as Map<String, dynamic>))
      .toList();
});

/// Everyone who bet a specific scoreline, with the match it was on.
final scorelinePickersProvider = FutureProvider.autoDispose
    .family<List<MatchPicker>, (int, int)>((ref, score) async {
  final data = await Supabase.instance.client
      .from('bet_pickers')
      .select('match_id, user_id, username, full_name, display_preference, avatar_url')
      .eq('home_score_bet', score.$1)
      .eq('away_score_bet', score.$2);
  return (data as List)
      .map((r) => MatchPicker(
            matchId: (r as Map<String, dynamic>)['match_id'] as String,
            user: PickerUser.fromJson(r),
          ))
      .toList();
});

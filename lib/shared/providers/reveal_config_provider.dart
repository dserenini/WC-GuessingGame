import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/models/match.dart';

/// Reveal modes for showing other users' bets.
const String kRevealModeGlobal = 'global';
const String kRevealModePerGameTail = 'per_game_tail';

/// Server-driven configuration controlling when another user's bets become
/// visible. Stored in the `app_config` table (key = 'reveal') so it can be
/// changed mid-tournament via a single SQL UPDATE, with no app rebuild.
class RevealConfig {
  /// Either [kRevealModeGlobal] or [kRevealModePerGameTail].
  final String mode;

  /// In per-game-tail mode, how many of the last (chronological) matches are
  /// protected — revealed only once each one kicks off.
  final int protectedTailCount;

  const RevealConfig({required this.mode, required this.protectedTailCount});

  /// Safe default used if `app_config` is missing or unreachable.
  static const fallback =
      RevealConfig(mode: kRevealModeGlobal, protectedTailCount: 10);
}

final revealConfigProvider = FutureProvider<RevealConfig>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('app_config')
        .select('value')
        .eq('key', 'reveal')
        .maybeSingle();

    if (data == null) return RevealConfig.fallback;

    final value = (data['value'] as Map?)?.cast<String, dynamic>() ?? {};
    return RevealConfig(
      mode: value['mode'] as String? ?? kRevealModeGlobal,
      protectedTailCount:
          (value['protected_tail_count'] as num?)?.toInt() ?? 10,
    );
  } catch (_) {
    return RevealConfig.fallback;
  }
});

/// Whether user B's bet for [match] may be revealed to a viewer who has already
/// passed the access gate (i.e. filled all of their own bets).
///
/// - Global mode (or any non-protected match): revealed once betting is locked
///   (the global deadline, via [isBettingLocked]).
/// - Per-game-tail mode, protected match: revealed only once that match has
///   started, so leaders can't copy the trailing games of the final stretch.
bool canRevealMatch(
  MatchModel match,
  List<MatchModel> allMatches,
  RevealConfig cfg,
) {
  if (cfg.mode == kRevealModePerGameTail) {
    if (_protectedTailIds(allMatches, cfg.protectedTailCount)
        .contains(match.id)) {
      return match.hasStarted;
    }
  }
  return isBettingLocked;
}

/// Ids of the last [count] matches by kickoff time (the protected "tail").
Set<String> _protectedTailIds(List<MatchModel> allMatches, int count) {
  if (count <= 0) return const {};
  final dated = allMatches.where((m) => m.matchDate != null).toList()
    ..sort((a, b) => a.matchDate!.compareTo(b.matchDate!));
  final start = dated.length > count ? dated.length - count : 0;
  return dated.sublist(start).map((m) => m.id).toSet();
}

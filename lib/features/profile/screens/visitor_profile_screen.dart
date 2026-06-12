import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/profile/providers/profile_stats_provider.dart';
import 'package:copa2026/features/profile/providers/stat_rankings_provider.dart';
import 'package:copa2026/features/profile/widgets/bet_comparison_card.dart';
import 'package:copa2026/shared/providers/reveal_config_provider.dart';

/// Read-only view of another user's bets, reached by tapping their name in a
/// ranking. Each match shows B's bet with the viewer's own bet faded beneath it,
/// gated by [canRevealMatch]. Access requires the viewer to have completed all
/// their own bets (anti-copy gate).
class VisitorProfileScreen extends ConsumerWidget {
  final String userId;
  final RankingEntry? entry;

  /// When set, the bet list is filtered to only the matches relevant to that
  /// statistic (e.g. Brazil games, exact hits, near misses…), instead of
  /// showing every match. [contextLabel] is the stat name shown in the header.
  final StatRanking? statFilter;
  final String? contextLabel;

  const VisitorProfileScreen({
    super.key,
    required this.userId,
    this.entry,
    this.statFilter,
    this.contextLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final name = entry?.displayName ?? '';
    final myStatsAsync = ref.watch(profileStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, size: 13, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(l.visitorMode,
                      style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: myStatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Error(message: e.toString()),
        data: (myStats) {
          // Access gate: only viewers who filled all their own bets may peek.
          // Bypassed in debug builds with kDebugForceReveal, for local testing.
          final gateOpen = (kDebugMode && kDebugForceReveal) ||
              myStats.totalBets >= myStats.totalMatches;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allMatchesProvider);
              ref.invalidate(userBetsProvider(userId));
              ref.invalidate(allBetsProvider);
              ref.invalidate(revealConfigProvider);
              ref.invalidate(profileStatsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _VisitorHeader(
                    name: name, entry: entry, l: l, contextLabel: contextLabel),
                if (!gateOpen)
                  _AccessGate(
                    done: myStats.totalBets,
                    total: myStats.totalMatches,
                    l: l,
                  )
                else
                  _BetList(userId: userId, bName: name, statFilter: statFilter),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header (green card mirroring the profile look)
// ─────────────────────────────────────────────
class _VisitorHeader extends StatelessWidget {
  final String name;
  final RankingEntry? entry;
  final AppLocalizations l;
  final String? contextLabel;
  const _VisitorHeader(
      {required this.name,
      required this.entry,
      required this.l,
      this.contextLabel});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryGreen, kPrimaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.25),
            backgroundImage: entry?.avatarUrl != null ? NetworkImage(entry!.avatarUrl!) : null,
            child: entry?.avatarUrl == null
                ? Text(initial,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                if (contextLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    contextLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ] else if (entry != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${l.rankPositionShort(entry!.rank)} · ${l.rankingBetsCount(entry!.totalBets)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          // Stat-filtered view: the metric value is already shown on the card
          // the user came from, so the global "pts" total is omitted here.
          if (entry != null && contextLabel == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry!.totalPoints}',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                Text('pts', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bet list (matches + comparison cards)
// ─────────────────────────────────────────────
class _BetList extends ConsumerWidget {
  final String userId;
  final String bName;
  final StatRanking? statFilter;
  const _BetList(
      {required this.userId, required this.bName, this.statFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(allMatchesProvider);
    final bBetsAsync = ref.watch(userBetsProvider(userId));
    final aBetsAsync = ref.watch(allBetsProvider);
    final cfgAsync = ref.watch(revealConfigProvider);

    final matches = matchesAsync.valueOrNull;
    final bBets = bBetsAsync.valueOrNull;
    final aBets = aBetsAsync.valueOrNull;
    final cfg = cfgAsync.valueOrNull;

    // The "Do Contra" filter needs cross-pool data from a dedicated view.
    final contrarianIds = statFilter == StatRanking.contrarian
        ? ref.watch(contrarianMatchesProvider(userId)).valueOrNull
        : const <String>{};

    if (matches == null ||
        bBets == null ||
        aBets == null ||
        cfg == null ||
        contrarianIds == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final visible = statFilter == null
        ? matches
        : _applyStatFilter(statFilter!, matches, bBets, contrarianIds);

    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.statsNoGames,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final m in visible)
          BetComparisonCard(
            match: m,
            betB: bBets[m.id],
            betA: aBets[m.id],
            bDisplayName: bName,
            revealed: canRevealMatch(m, matches, cfg),
          ),
      ],
    );
  }
}

/// Selects the matches relevant to a given statistic for the tapped player.
/// Mirrors the criteria of the SQL ranking views so the detail matches the
/// number shown on the card.
List<MatchModel> _applyStatFilter(
  StatRanking stat,
  List<MatchModel> matches,
  Map<String, BetModel> bBets,
  Set<String> contrarianIds,
) {
  bool isBrazil(MatchModel m) =>
      m.homeTeam.name == 'Brasil' || m.awayTeam.name == 'Brasil';
  bool finished(MatchModel m) =>
      m.status == MatchStatus.finished &&
      m.homeScore != null &&
      m.awayScore != null;

  switch (stat) {
    case StatRanking.brazilPoints:
      return matches
          .where((m) => isBrazil(m) && bBets[m.id] != null)
          .toList();
    case StatRanking.exactScore:
      return matches.where((m) => (bBets[m.id]?.points ?? -1) == 3).toList();
    case StatRanking.nearMiss:
      return matches.where((m) {
        final b = bBets[m.id];
        if (b == null || !finished(m) || b.points >= 3) return false;
        final d = (b.homeScoreBet - m.homeScore!).abs() +
            (b.awayScoreBet - m.awayScore!).abs();
        return d == 1;
      }).toList();
    case StatRanking.regularity:
      return matches.where((m) {
        final b = bBets[m.id];
        return b != null && finished(m) && b.points > 0;
      }).toList();
    case StatRanking.boldness:
      return matches.where((m) {
        final b = bBets[m.id];
        if (b == null) return false;
        return (b.homeScoreBet - b.awayScoreBet).abs() >= 5 ||
            (b.homeScoreBet + b.awayScoreBet) >= 7;
      }).toList();
    case StatRanking.dailyTop:
      final ids = _bestDayMatchIds(matches, bBets);
      return matches.where((m) => ids.contains(m.id)).toList();
    case StatRanking.contrarian:
      return matches.where((m) => contrarianIds.contains(m.id)).toList();
  }
}

/// Match ids of the player's best single day (highest summed points), grouped
/// in São Paulo time (UTC-3) to match the `daily_top_rankings` view.
Set<String> _bestDayMatchIds(
    List<MatchModel> matches, Map<String, BetModel> bBets) {
  const spOffset = Duration(hours: -3);
  final Map<String, int> dayPoints = {};
  final Map<String, List<String>> dayMatchIds = {};

  for (final m in matches) {
    if (m.status != MatchStatus.finished || m.matchDate == null) continue;
    final b = bBets[m.id];
    if (b == null) continue;
    final sp = m.matchDate!.toUtc().add(spOffset);
    final key = '${sp.year}-${sp.month}-${sp.day}';
    dayPoints[key] = (dayPoints[key] ?? 0) + b.points;
    dayMatchIds.putIfAbsent(key, () => []).add(m.id);
  }

  if (dayPoints.isEmpty) return const {};
  var bestKey = dayPoints.keys.first;
  for (final e in dayPoints.entries) {
    if (e.value > dayPoints[bestKey]!) bestKey = e.key;
  }
  return dayMatchIds[bestKey]!.toSet();
}

// ─────────────────────────────────────────────
// Access gate (viewer hasn't filled all bets)
// ─────────────────────────────────────────────
class _AccessGate extends StatelessWidget {
  final int done;
  final int total;
  final AppLocalizations l;
  const _AccessGate({required this.done, required this.total, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 56, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            l.completeBetsToView,
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            l.completeBetsToViewSub,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$done/$total',
              style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  const _Error({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ),
    );
  }
}

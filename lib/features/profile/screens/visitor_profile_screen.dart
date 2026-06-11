import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/profile/providers/profile_stats_provider.dart';
import 'package:copa2026/features/profile/widgets/bet_comparison_card.dart';
import 'package:copa2026/shared/providers/reveal_config_provider.dart';

/// Read-only view of another user's bets, reached by tapping their name in a
/// ranking. Each match shows B's bet with the viewer's own bet faded beneath it,
/// gated by [canRevealMatch]. Access requires the viewer to have completed all
/// their own bets (anti-copy gate).
class VisitorProfileScreen extends ConsumerWidget {
  final String userId;
  final RankingEntry? entry;

  const VisitorProfileScreen({super.key, required this.userId, this.entry});

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
                _VisitorHeader(name: name, entry: entry, l: l),
                if (!gateOpen)
                  _AccessGate(
                    done: myStats.totalBets,
                    total: myStats.totalMatches,
                    l: l,
                  )
                else
                  _BetList(userId: userId, bName: name),
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
  const _VisitorHeader({required this.name, required this.entry, required this.l});

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
                if (entry != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${l.rankPositionShort(entry!.rank)} · ${l.rankingBetsCount(entry!.totalBets)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (entry != null)
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
  const _BetList({required this.userId, required this.bName});

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

    if (matches == null || bBets == null || aBets == null || cfg == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        for (final m in matches)
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

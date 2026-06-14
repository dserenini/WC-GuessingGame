import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/profile/widgets/bet_comparison_card.dart';

/// Lists the current user's own matches for a personal-stats drill-down, with
/// their bet and the real result. Filter by [scoreline] (a "h-a" string),
/// [teamName] (all of a team's games), or an explicit [matchIds] set.
class MyMatchesDetailScreen extends ConsumerWidget {
  final String title;
  final String? scoreline;
  final String? teamName;
  final Set<String>? matchIds;

  const MyMatchesDetailScreen({
    super.key,
    required this.title,
    this.scoreline,
    this.teamName,
    this.matchIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final matchesAsync = ref.watch(allMatchesProvider);
    final betsAsync = ref.watch(allBetsProvider);

    final matches = matchesAsync.valueOrNull;
    final bets = betsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: (matches == null || bets == null)
          ? const Center(child: CircularProgressIndicator())
          : Builder(builder: (context) {
              final visible = matches.where((m) {
                final b = bets[m.id];
                if (teamName != null) {
                  return m.homeTeam.name == teamName ||
                      m.awayTeam.name == teamName;
                }
                if (matchIds != null) return matchIds!.contains(m.id);
                if (scoreline != null) {
                  return b != null &&
                      '${b.homeScoreBet}-${b.awayScoreBet}' == scoreline;
                }
                return false;
              }).toList()
                ..sort((a, b) => (a.matchDate ?? DateTime(0))
                    .compareTo(b.matchDate ?? DateTime(0)));

              if (visible.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l.statsNoGames,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final m in visible)
                    BetComparisonCard(
                      match: m,
                      betB: bets[m.id],
                      betA: null,
                      bDisplayName: l.statsYou,
                      revealed: true,
                      showViewerRow: false,
                    ),
                ],
              );
            }),
    );
  }
}

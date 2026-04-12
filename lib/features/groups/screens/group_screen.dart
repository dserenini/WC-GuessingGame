import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/groups/widgets/standings_table.dart';
import 'package:copa2026/features/groups/widgets/match_card.dart';
import 'package:copa2026/features/chaos/chaos_service.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';

class GroupScreen extends ConsumerWidget {
  final String groupLetter;

  const GroupScreen({super.key, required this.groupLetter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(groupMatchesProvider(groupLetter));
    final betsAsync = ref.watch(groupBetsProvider(groupLetter));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l.group} $groupLetter'),
        actions: [
          if (!isBettingLocked)
            IconButton(
              tooltip: l.agentOfChaos,
              onPressed: () => _showChaosMenu(context, ref),
              icon: const Text('🎲', style: TextStyle(fontSize: 22)),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (matches) => betsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (bets) {
            final standings = computeStandings(matches: matches, bets: bets);

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(groupMatchesProvider(groupLetter));
                ref.invalidate(groupBetsProvider(groupLetter));
              },
              child: CustomScrollView(
                slivers: [
                  // â”€â”€ Deadline Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  if (isBettingLocked)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: cs.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: cs.error, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l.betsLocked,
                              style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // â”€â”€ Standings Table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: StandingsTable(standings: standings),
                    ),
                  ),

                  // â”€â”€ Match Cards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final match = matches[i];
                          final bet = bets[match.id];
                          return MatchCard(
                            match: match,
                            bet: bet,
                            groupLetter: groupLetter,
                          );
                        },
                        childCount: matches.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showChaosMenu(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '🎲 ${l.agentOfChaos}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.shuffle),
              title: Text(l.chaosRandomAll),
              subtitle: Text(l.chaosRandomAllSub),
              onTap: () {
                Navigator.pop(context);
                _randomizeAll(context, ref);
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l.chaosGuidedHint,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _randomizeAll(BuildContext context, WidgetRef ref) async {
    final matches = ref.read(groupMatchesProvider(groupLetter)).valueOrNull ?? [];
    final bets = ref.read(groupBetsProvider(groupLetter)).valueOrNull ?? {};

    // Only fill empty bets
    for (final match in matches) {
      if (bets.containsKey(match.id)) continue;
      if (match.isLocked) continue;

      final scores = ChaosService.randomScore();
      await ref.read(betNotifierProvider.notifier).saveBet(
            matchId: match.id,
            groupLetter: groupLetter,
            homeScore: scores.$1,
            awayScore: scores.$2,
          );
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/groups/widgets/standings_table.dart';
import 'package:copa2026/features/groups/widgets/match_card.dart';
import 'package:copa2026/features/chaos/chaos_service.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';
import 'package:copa2026/shared/providers/max_goals_provider.dart';

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
        title: Text(' '),
        leadingWidth: 100,
        leading: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const NotificationBell(),
          ],
        ),

        actions: [
          if (!isBettingLocked) ...[
            Consumer(
              builder: (context, ref, child) {
                final chaosActive = ref.watch(chaosModeProvider);
                return Switch(
                  value: chaosActive,
                  onChanged: (val) =>
                      ref.read(chaosModeProvider.notifier).state = val,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                );
              },
            ),
            IconButton(
              tooltip: l.agentOfChaos,
              onPressed: () => _showChaosMenu(context, ref),
              icon: const Text('🎲', style: TextStyle(fontSize: 22)),
            ),
            IconButton(
              tooltip: l.deleteAllBets,
              onPressed: () => _confirmDeleteAll(context, ref),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          ],
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

                  // ── Standings Table ──────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final top8 = ref.watch(bestThirdPlacesProvider);
                          return StandingsTable(standings: standings, top8ThirdPlaces: top8);
                        },
                      ),
                    ),
                  ),

                  // ── Match Cards ──────────────────────
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
            ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: Text(l.followStandings),
              subtitle: Text(l.followStandingsSub),
              onTap: () {
                Navigator.pop(context);
                final matches = ref.read(groupMatchesProvider(groupLetter)).valueOrNull ?? [];
                _showRankingDialog(context, ref, matches);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRankingDialog(BuildContext context, WidgetRef ref, List<MatchModel> matches) {
    if (matches.isEmpty) return;
    final l = AppLocalizations.of(context)!;

    final Set<String> teamNamesSet = {};
    for (final m in matches) {
      teamNamesSet.add(m.homeTeam.name);
      teamNamesSet.add(m.awayTeam.name);
    }
    final List<String> teamNames = teamNamesSet.toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l.desiredStandings),
              content: SizedBox(
                width: double.maxFinite,
                height: 320,
                child: Column(
                  children: [
                    Text(l.dragTeams, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ReorderableListView(
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = teamNames.removeAt(oldIndex);
                            teamNames.insert(newIndex, item);
                          });
                        },
                        children: [
                          for (int i = 0; i < teamNames.length; i++)
                            ListTile(
                              key: ValueKey(teamNames[i]),
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                child: Text('${i + 1}º', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                              ),
                              title: Text(teamNames[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                              trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final maxGoals = ref.read(maxGoalsProvider);
                    final scores = ChaosService.generateRankedBets(matches: matches, rankedTeamNames: teamNames, max: maxGoals);
                    for (final m in matches) {
                      if (scores.containsKey(m.id)) {
                        await ref.read(betNotifierProvider.notifier).saveBet(
                              matchId: m.id,
                              groupLetter: groupLetter,
                              homeScore: scores[m.id]!.$1,
                              awayScore: scores[m.id]!.$2,
                            );
                      }
                    }
                  },
                  child: Text(l.generateChaos),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _randomizeAll(BuildContext context, WidgetRef ref) async {
    final matches = ref.read(groupMatchesProvider(groupLetter)).valueOrNull ?? [];
    final bets = ref.read(groupBetsProvider(groupLetter)).valueOrNull ?? {};

    // Only fill empty bets
    for (final match in matches) {
      if (bets.containsKey(match.id)) continue;
      if (match.isLocked) continue;

      final maxGoals = ref.read(maxGoalsProvider);
      final scores = ChaosService.randomScore(max: maxGoals);
      await ref.read(betNotifierProvider.notifier).saveBet(
            matchId: match.id,
            groupLetter: groupLetter,
            homeScore: scores.$1,
            awayScore: scores.$2,
          );
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.deleteGroup),
        content: Text(l.deleteGroupConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final bets = ref.read(groupBetsProvider(groupLetter)).valueOrNull ?? {};
      if (bets.isNotEmpty) {
        await ref.read(betNotifierProvider.notifier).clearGroupBets(
              matchIds: bets.keys.toList(),
              groupLetter: groupLetter,
            );
      }
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

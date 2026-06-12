import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/groups/widgets/standings_table.dart';
import 'package:copa2026/features/groups/widgets/match_card.dart';
import 'package:copa2026/l10n/team_translator.dart';
import 'package:copa2026/features/chaos/chaos_service.dart';
import 'package:copa2026/features/profile/providers/profile_stats_provider.dart';
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
                return Tooltip(
                  message: l.easyBet,
                  child: Switch(
                    value: chaosActive,
                    onChanged: (val) =>
                        ref.read(chaosModeProvider.notifier).state = val,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
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
      bottomNavigationBar: _GroupNavBar(groupLetter: groupLetter),
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
                // Invalida as FONTES (não os providers derivados): re-assina o
                // stream de partidas e re-busca os palpites do usuário.
                ref.invalidate(allMatchesProvider);
                ref.invalidate(allBetsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // ── Deadline Banner ──────────────────
                  if (isBettingLocked)
                    const SliverToBoxAdapter(child: _DeadlineBanner()),

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
                              title: Text(translateTeam(context, teamNames[i]), style: const TextStyle(fontWeight: FontWeight.w600)),
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

// ─────────────────────────────────────────────
// GROUP NAVIGATION BAR (prev / picker / next)
// ─────────────────────────────────────────────
class _GroupNavBar extends StatelessWidget {
  final String groupLetter;
  const _GroupNavBar({required this.groupLetter});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final idx = kGroups.indexOf(groupLetter);
    final hasPrev = idx > 0;
    final hasNext = idx >= 0 && idx < kGroups.length - 1;

    void go(int targetIdx) => context.go('/groups/${kGroups[targetIdx]}');

    return BottomAppBar(
      height: 58,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          // ── Previous ──
          Expanded(
            child: hasPrev
                ? TextButton.icon(
                    onPressed: () => go(idx - 1),
                    icon: const Icon(Icons.chevron_left),
                    label: Text('${l.group} ${kGroups[idx - 1]}'),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                      alignment: Alignment.centerLeft,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          // ── Center: current group (tap to pick) ──
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _showGroupPicker(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${l.group} $groupLetter',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, color: cs.onSurface.withOpacity(0.6)),
                ],
              ),
            ),
          ),
          // ── Next ──
          Expanded(
            child: hasNext
                ? TextButton.icon(
                    onPressed: () => go(idx + 1),
                    icon: const Icon(Icons.chevron_right),
                    label: Text('${l.group} ${kGroups[idx + 1]}'),
                    iconAlignment: IconAlignment.end,
                    style: TextButton.styleFrom(
                      foregroundColor: cs.primary,
                      alignment: Alignment.centerRight,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showGroupPicker(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: GridView.count(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            for (final g in kGroups)
              _GroupPickerChip(
                label: '${l.group} $g',
                selected: g == groupLetter,
                onTap: () {
                  Navigator.pop(context);
                  if (g != groupLetter) context.go('/groups/$g');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupPickerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GroupPickerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primary : cs.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? cs.onPrimary : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DEADLINE BANNER (pós-prazo)
// ─────────────────────────────────────────────
// Enquanto restam Super Palpites: aviso âmbar (ainda dá para apostar, mas
// consome um Super Palpite) com a contagem restante. Quando esgotam: vermelho,
// apostas realmente bloqueadas.
class _DeadlineBanner extends ConsumerWidget {
  const _DeadlineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final used =
        ref.watch(profileStatsProvider).valueOrNull?.superPalpitesUsed ?? 0;
    final remaining =
        (kMaxSuperPalpites - used).clamp(0, kMaxSuperPalpites);
    final exhausted = remaining <= 0;

    final accent =
        exhausted ? cs.error : (isDark ? Colors.amber.shade300 : Colors.amber.shade800);
    final bg = (exhausted ? cs.error : Colors.amber).withOpacity(0.12);
    final border = (exhausted ? cs.error : Colors.amber).withOpacity(isDark ? 0.5 : 0.4);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: exhausted
          ? Row(
              children: [
                Icon(Icons.lock, color: accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.superPalpitesExhausted,
                    style: tt.bodySmall
                        ?.copyWith(color: accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.regularDeadlineClosed,
                        style: tt.labelLarge?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l.betsUseSuperPalpite,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(isDark ? 0.22 : 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🌟 $remaining/$kMaxSuperPalpites',
                    style: tt.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
    );
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

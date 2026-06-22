import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/shared/models/bet.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final currentUser = ref.watch(currentUserProvider);
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isAdmin = kAdminUids.contains(currentUser?.id);
    final knockoutOn = ref.watch(knockoutVisibleProvider).valueOrNull ?? false;

    final allMatches = ref.watch(allMatchesProvider).valueOrNull ?? [];
    final allBets = ref.watch(allBetsProvider).valueOrNull ?? {};

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryGreen, kPrimaryGreenLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('⚽', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Make Bolão Great Again',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            currentUser?.userMetadata?['username'] as String? ??
                                currentUser?.email ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: cs.onSurface.withOpacity(0.5),
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Main navigation (scrolls; Groups A–L collapse under "Apostas")
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: '🏠',
                    label: l.home,
                    selected: currentPath == '/profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                  ),
                  _DrawerItem(
                    icon: '🏅',
                    label: l.statsTabAchievements,
                    selected: currentPath == '/achievements',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/achievements');
                    },
                  ),
                  _DrawerItem(
                    icon: '📊',
                    label: l.advancedStats,
                    selected: currentPath == '/stats',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/stats');
                    },
                  ),
                  _DrawerItem(
                    icon: '🏆',
                    label: l.ranking,
                    selected: currentPath == '/ranking',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/ranking');
                    },
                  ),
                  _DrawerItem(
                    icon: '🛡️',
                    label: l.privateLeagues,
                    selected: currentPath == '/leagues',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/leagues');
                    },
                  ),
                  if (knockoutOn)
                    _DrawerItem(
                      icon: '⚔️',
                      label: 'Mata-Mata',
                      selected: currentPath == '/knockout',
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/knockout');
                      },
                    ),
                  // ── Apostas → Grupos A–L (colapsável) ──
                  _BetsGroup(
                    currentPath: currentPath,
                    allMatches: allMatches,
                    allBets: allBets,
                    l: l,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Bottom items ─────────────────
            _DrawerItem(
              icon: '❓',
              label: l.helpAndRules,
              onTap: () {
                Navigator.pop(context);
                context.go('/help');
              },
            ),
            _DrawerItem(
              icon: '⚙️',
              label: l.settings,
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
            if (isAdmin)
              _DrawerItem(
                icon: '🔧',
                label: l.adminPanel,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/admin');
                },
              ),
            _DrawerItem(
              icon: '🚪',
              label: l.signOut,
              onTap: () {
                Navigator.pop(context);
                ref.read(authNotifierProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// "Apostas" — collapsible group holding Groups A–L
// ─────────────────────────────────────────────
class _BetsGroup extends StatelessWidget {
  final String currentPath;
  final List<MatchModel> allMatches;
  final Map<String, BetModel> allBets;
  final AppLocalizations l;

  const _BetsGroup({
    required this.currentPath,
    required this.allMatches,
    required this.allBets,
    required this.l,
  });

  /// Per-group bet-progress badge (X/Y, green = complete, amber = partial,
  /// red = none). Null when the group has no matches loaded yet.
  Widget? _badge(String g) {
    final groupMatches = allMatches.where((m) => m.groupLetter == g).toList();
    final total = groupMatches.length;
    if (total == 0) return null;
    final placed = groupMatches.where((m) => allBets.containsKey(m.id)).length;

    final Color statusColor = placed == total
        ? Colors.greenAccent.shade400
        : placed == 0
            ? Colors.redAccent.shade400
            : Colors.amberAccent.shade400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        border: Border.all(color: statusColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$placed/$total',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: statusColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onGroups = currentPath.startsWith('/groups/');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Theme(
        // Drop the ExpansionTile's default top/bottom divider lines.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Auto-open while browsing a group so the active one is visible.
          initiallyExpanded: onGroups,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 16, bottom: 4),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: const Text('🎯', style: TextStyle(fontSize: 18)),
          title: Text(
            l.bets,
            style: TextStyle(
              fontSize: 14,
              fontWeight: onGroups ? FontWeight.w600 : FontWeight.w400,
              color: onGroups ? cs.primary : null,
            ),
          ),
          children: [
            for (final g in kGroups)
              _DrawerItem(
                label: '${l.group} $g',
                selected: currentPath == '/groups/$g',
                trailing: _badge(g),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/groups/$g');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String? icon;
  final String label;
  final bool selected;
  final Widget? trailing;
  final VoidCallback onTap;

  const _DrawerItem({
    this.icon,
    required this.label,
    this.selected = false,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: selected,
        selectedTileColor: cs.primary.withOpacity(0.1),
        selectedColor: cs.primary,
        leading: icon != null
            ? Text(icon!, style: const TextStyle(fontSize: 18))
            : null,
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

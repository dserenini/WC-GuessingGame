import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final currentUser = ref.watch(currentUserProvider);
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isAdmin = kAdminUids.contains(currentUser?.id);

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

            // ── Perfil ────────────────────────
            _DrawerItem(
              icon: '👤',
              label: l.myProfile,
              selected: currentPath == '/profile',
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),

            // ── Ranking ──────────────────────
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
              icon: '🏅',
              label: l.privateLeagues,
              selected: currentPath == '/leagues',
              onTap: () {
                Navigator.pop(context);
                context.go('/leagues');
              },
            ),

            const Divider(height: 24),

            // ── Groups A–L ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                l.groups,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: kGroups.length,
                itemBuilder: (_, i) {
                  final g = kGroups[i];
                  final path = '/groups/$g';
                  
                  final groupMatches = allMatches.where((m) => m.groupLetter == g).toList();
                  final totalMatches = groupMatches.length;
                  final placedBets = groupMatches.where((m) => allBets.containsKey(m.id)).length;
                  
                  Widget? trailingIndicator;
                  if (totalMatches > 0) {
                    final isComplete = placedBets == totalMatches;
                    final isZero = placedBets == 0;
                    
                    Color statusColor;
                    if (isComplete) {
                      statusColor = Colors.greenAccent.shade400;
                    } else if (isZero) {
                      statusColor = Colors.redAccent.shade400;
                    } else {
                      statusColor = Colors.amberAccent.shade400;
                    }

                    trailingIndicator = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$placedBets/$totalMatches',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }

                  return _DrawerItem(
                    label: '${l.group} $g',
                    selected: currentPath == path,
                    trailing: trailingIndicator,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(path);
                    },
                  );
                },
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

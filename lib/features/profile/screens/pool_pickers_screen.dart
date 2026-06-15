import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/profile/providers/pool_stats_provider.dart';
import 'package:copa2026/l10n/team_translator.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/shared/providers/reveal_config_provider.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';

// ─────────────────────────────────────────────
// Who nailed a specific match (most/least predictable games)
// ─────────────────────────────────────────────
class MatchPickersScreen extends ConsumerWidget {
  final MatchModel match;
  const MatchPickersScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final pickersAsync = ref.watch(exactPickersProvider(match.id));

    return Scaffold(
      appBar: AppBar(title: Text(l.poolWhoNailed)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MatchHeader(match: match),
          const SizedBox(height: 16),
          pickersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(l.statsError, style: TextStyle(color: cs.error)),
            data: (users) {
              if (users.isEmpty) {
                return _emptyHint(context, l.poolNobodyNailed);
              }
              return Column(
                children: [for (final u in users) _UserTile(user: u)],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Who bet a specific (rare) scoreline, and on which match
// ─────────────────────────────────────────────
class ScorelinePickersScreen extends ConsumerWidget {
  final int home;
  final int away;
  const ScorelinePickersScreen({super.key, required this.home, required this.away});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final pickersAsync = ref.watch(scorelinePickersProvider((home, away)));
    final matches = ref.watch(allMatchesProvider).valueOrNull;
    final cfg = ref.watch(revealConfigProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text('$home - $away')),
      body: (matches == null || cfg == null)
          ? const Center(child: CircularProgressIndicator())
          : pickersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(l.statsError, style: TextStyle(color: cs.error))),
              data: (pickers) {
                final byId = {for (final m in matches) m.id: m};
                // Respect reveal: only show picks on already-revealed matches.
                final visible = pickers
                    .where((p) {
                      final m = byId[p.matchId];
                      return m != null && canRevealMatch(m, matches, cfg);
                    })
                    .toList();

                if (visible.isEmpty) {
                  return Center(child: _emptyHint(context, l.statsNoGames));
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final p in visible)
                      _PickRow(match: byId[p.matchId]!, user: p.user),
                  ],
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────
class _MatchHeader extends StatelessWidget {
  final MatchModel match;
  const _MatchHeader({required this.match});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasScore = match.homeScore != null && match.awayScore != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(child: _TeamCol(name: match.homeTeam.name, flag: match.homeTeam.flagUrl)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              hasScore ? '${match.homeScore} - ${match.awayScore}' : '—',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: _TeamCol(name: match.awayTeam.name, flag: match.awayTeam.flagUrl)),
        ],
      ),
    );
  }
}

class _TeamCol extends StatelessWidget {
  final String name;
  final String? flag;
  const _TeamCol({required this.name, required this.flag});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        FlagAvatar(flagUrl: flag, radius: 20),
        const SizedBox(height: 6),
        Text(translateTeam(context, name),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final PickerUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primary.withOpacity(0.15),
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  final MatchModel match;
  final PickerUser user;
  const _PickRow({required this.match, required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FlagAvatar(flagUrl: match.homeTeam.flagUrl, radius: 12),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${translateTeam(context, match.homeTeam.name)} x ${translateTeam(context, match.awayTeam.name)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelMedium?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                ),
              ),
              const SizedBox(width: 6),
              FlagAvatar(flagUrl: match.awayTeam.flagUrl, radius: 12),
            ],
          ),
          const SizedBox(height: 8),
          _UserTile(user: user),
        ],
      ),
    );
  }
}

Widget _emptyHint(BuildContext context, String msg) {
  final cs = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Text(msg,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6))),
  );
}

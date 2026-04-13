import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/shared/widgets/score_bottom_sheet.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/chaos/chaos_service.dart';

class MatchCard extends ConsumerWidget {
  final MatchModel match;
  final BetModel? bet;
  final String groupLetter;

  const MatchCard({
    super.key,
    required this.match,
    required this.bet,
    required this.groupLetter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final locked = isBettingLocked || match.isLocked;

    final homeScore = bet?.homeScoreBet;
    final awayScore = bet?.awayScoreBet;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Status chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              children: [
                _StatusChip(status: match.status),
                const Spacer(),
                if (match.matchDate != null)
                  Text(
                    _formatDate(match.matchDate!),
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // â”€â”€ Score row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              children: [
                // Home team
                Expanded(
                  child: GestureDetector(
                    onTap: locked
                        ? null
                        : () => _randomWin(context, ref, isHome: true),
                    child: Column(
                      children: [
                        FlagAvatar(
                          flagUrl: match.homeTeam.flagUrl,
                          radius: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeam.name,
                          textAlign: TextAlign.center,
                          style: tt.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Score inputs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ScoreBox(
                        value: homeScore,
                        locked: locked,
                        onTap: () => _openPicker(
                          context, ref,
                          isHome: true,
                          currentHome: homeScore ?? 0,
                          currentAway: awayScore ?? 0,
                        ),
                      ),
                      GestureDetector(
                        onTap: locked
                            ? null
                            : () => _randomDraw(context, ref),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'X',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                      _ScoreBox(
                        value: awayScore,
                        locked: locked,
                        onTap: () => _openPicker(
                          context, ref,
                          isHome: false,
                          currentHome: homeScore ?? 0,
                          currentAway: awayScore ?? 0,
                        ),
                      ),
                    ],
                  ),
                ),

                // Away team
                Expanded(
                  child: GestureDetector(
                    onTap: locked
                        ? null
                        : () => _randomWin(context, ref, isHome: false),
                    child: Column(
                      children: [
                        FlagAvatar(
                          flagUrl: match.awayTeam.flagUrl,
                          radius: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeam.name,
                          textAlign: TextAlign.center,
                          style: tt.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // â”€â”€ Real score (finished matches) â”€â”€
            if (match.status == MatchStatus.finished &&
                match.homeScore != null &&
                match.awayScore != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${l.result}: ${match.homeScore} – ${match.awayScore}',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            // â”€â”€ Points badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (bet != null && bet!.points > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: _PointsBadge(points: bet!.points),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    WidgetRef ref, {
    required bool isHome,
    required int currentHome,
    required int currentAway,
  }) async {
    final l = AppLocalizations.of(context)!;

    final result = await showModalBottomSheet<(int, int)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ScoreBottomSheet(
        homeTeam: match.homeTeam.name,
        awayTeam: match.awayTeam.name,
        initialHome: currentHome,
        initialAway: currentAway,
        focusHome: isHome,
      ),
    );

    if (result == null) return;
    final (home, away) = result;

    // "Are you serious?" validation
    if (home > kWackyGoalThreshold || away > kWackyGoalThreshold) {
      if (context.mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('😱'),
            content: Text(l.wackyGoalAlert),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.cancel)),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l.yes)),
            ],
          ),
        );
        if (confirmed != true) return;
      }
    }

    if (context.mounted) {
      await ref.read(betNotifierProvider.notifier).saveBet(
            matchId: match.id,
            groupLetter: groupLetter,
            homeScore: home,
            awayScore: away,
          );
    }
  }

  Future<void> _randomWin(
    BuildContext context,
    WidgetRef ref, {
    required bool isHome,
  }) async {
    final maxGoals = kDefaultMaxGoals; // TODO: read from user prefs
    final scores = ChaosService.randomWin(isHome: isHome, max: maxGoals);
    await ref.read(betNotifierProvider.notifier).saveBet(
          matchId: match.id,
          groupLetter: groupLetter,
          homeScore: scores.$1,
          awayScore: scores.$2,
        );
  }

  Future<void> _randomDraw(BuildContext context, WidgetRef ref) async {
    final maxGoals = kDefaultMaxGoals;
    final scores = ChaosService.randomDraw(max: maxGoals);
    await ref.read(betNotifierProvider.notifier).saveBet(
          matchId: match.id,
          groupLetter: groupLetter,
          homeScore: scores.$1,
          awayScore: scores.$2,
        );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Score Input Box
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ScoreBox extends StatelessWidget {
  final int? value;
  final bool locked;
  final VoidCallback onTap;

  const _ScoreBox({this.value, required this.locked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: locked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: locked
              ? cs.surfaceContainerHighest
              : value != null
                  ? cs.primary.withOpacity(0.1)
                  : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: locked
                ? cs.outline.withOpacity(0.3)
                : value != null
                    ? cs.primary.withOpacity(0.5)
                    : cs.outline.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            value?.toString() ?? '—',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: locked
                      ? cs.onSurface.withOpacity(0.35)
                      : value != null
                          ? cs.primary
                          : cs.onSurface.withOpacity(0.35),
                ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Status Chip
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _StatusChip extends StatelessWidget {
  final MatchStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      MatchStatus.scheduled => ('Agendado', cs.outline),
      MatchStatus.live      => ('Ao Vivo 🔴', Colors.red),
      MatchStatus.finished  => ('Encerrado', cs.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Points Badge
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    final isExact = points == 3;
    final color = isExact ? kGold : kPrimaryGreenLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        isExact ? '🎯 +3 pts' : '✅ +1 pt',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

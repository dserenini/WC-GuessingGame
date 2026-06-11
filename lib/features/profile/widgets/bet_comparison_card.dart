import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';
import 'package:copa2026/shared/utils/bet_points.dart';
import 'package:copa2026/l10n/team_translator.dart';

/// A single match shown on the visitor profile, comparing user B's bet (prominent)
/// with the viewer's own bet (faded), plus per-bet points once the game has a
/// score. When [revealed] is false the bets are hidden behind a lock.
class BetComparisonCard extends ConsumerWidget {
  final MatchModel match;

  /// User B's bet (the profile being visited). Null if B didn't bet this match.
  final BetModel? betB;

  /// The viewer's own bet. Null if the viewer didn't bet this match.
  final BetModel? betA;

  /// Display name of user B (for the comparison row label).
  final String bDisplayName;

  /// Whether B's bet may be shown (decided by canRevealMatch).
  final bool revealed;

  const BetComparisonCard({
    super.key,
    required this.match,
    required this.betB,
    required this.betA,
    required this.bDisplayName,
    required this.revealed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final offset = ref.watch(timezoneProvider);

    if (!revealed) {
      return _HiddenCard(match: match, l: l, offset: offset);
    }

    final hasRealScore = match.homeScore != null &&
        match.awayScore != null &&
        (match.status == MatchStatus.live ||
            match.status == MatchStatus.finished);
    final isPartial = match.status == MatchStatus.live;

    int? pointsFor(BetModel? bet) {
      if (bet == null) return null;
      if (match.status == MatchStatus.finished) return bet.points;
      if (isPartial && hasRealScore) {
        return computeBetPoints(
          homeBet: bet.homeScoreBet,
          awayBet: bet.awayScoreBet,
          homeReal: match.homeScore!,
          awayReal: match.awayScore!,
        );
      }
      return null; // scheduled / no score yet → no badge
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status pill (right aligned) ──────────────
            Row(
              children: [
                const Spacer(),
                _StatusPill(match: match, l: l, offset: offset),
              ],
            ),
            const SizedBox(height: 6),

            // ── Teams + real/live score (or "vs") ────────
            Row(
              children: [
                Expanded(child: _TeamColumn(team: match.homeTeam.name, flagUrl: match.homeTeam.flagUrl)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: hasRealScore
                      ? Text(
                          '${match.homeScore} - ${match.awayScore}',
                          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        )
                      : Text(
                          l.versusShort,
                          style: tt.titleMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                Expanded(child: _TeamColumn(team: match.awayTeam.name, flagUrl: match.awayTeam.flagUrl)),
              ],
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: cs.outline.withOpacity(0.15)),
            const SizedBox(height: 8),

            // ── Comparison: B (prominent) then You (faded) ──
            _BetRow(
              label: bDisplayName,
              initial: bDisplayName.isNotEmpty ? bDisplayName[0].toUpperCase() : '?',
              bet: betB,
              points: pointsFor(betB),
              isPartial: isPartial,
              faded: false,
              l: l,
            ),
            const SizedBox(height: 6),
            _BetRow(
              label: l.yourBet,
              initial: null,
              bet: betA,
              points: pointsFor(betA),
              isPartial: isPartial,
              faded: true,
              l: l,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Team column (flag + translated name)
// ─────────────────────────────────────────────
class _TeamColumn extends StatelessWidget {
  final String team;
  final String? flagUrl;
  const _TeamColumn({required this.team, required this.flagUrl});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        FlagAvatar(flagUrl: flagUrl, radius: 20),
        const SizedBox(height: 6),
        Text(
          translateTeam(context, team),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Comparison row (one bet)
// ─────────────────────────────────────────────
class _BetRow extends StatelessWidget {
  final String label;
  final String? initial; // null → generic person icon (the viewer)
  final BetModel? bet;
  final int? points;
  final bool isPartial;
  final bool faded;
  final AppLocalizations l;

  const _BetRow({
    required this.label,
    required this.initial,
    required this.bet,
    required this.points,
    required this.isPartial,
    required this.faded,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fadedColor = cs.onSurface.withOpacity(0.45);

    final scoreText = bet != null
        ? '${bet!.homeScoreBet} - ${bet!.awayScoreBet}'
        : '—';

    return Row(
      children: [
        // Avatar / icon
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: faded ? cs.onSurface.withOpacity(0.10) : cs.primary,
          ),
          alignment: Alignment.center,
          child: initial != null
              ? Text(
                  initial!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Icon(Icons.person, size: 13, color: fadedColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(
              color: faded ? fadedColor : cs.onSurface,
            ),
          ),
        ),
        Text(
          scoreText,
          style: tt.titleSmall?.copyWith(
            fontWeight: faded ? FontWeight.w500 : FontWeight.w700,
            color: faded ? fadedColor : cs.onSurface,
          ),
        ),
        if (points != null) ...[
          const SizedBox(width: 8),
          _PointsBadge(points: points!, isPartial: isPartial, l: l),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Points badge — color tier: 3 = green, 1 = amber, 0 = gray
// ─────────────────────────────────────────────
class _PointsBadge extends StatelessWidget {
  final int points;
  final bool isPartial;
  final AppLocalizations l;
  const _PointsBadge({required this.points, required this.isPartial, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (Color bg, Color fg) = switch (points) {
      3 => (cs.primary.withOpacity(0.15), cs.primary),
      1 => (Colors.amber.withOpacity(0.18), Colors.amber.shade800),
      _ => (cs.onSurface.withOpacity(0.08), cs.onSurface.withOpacity(0.55)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            points > 0 ? '+$points' : '0',
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          if (isPartial) ...[
            const SizedBox(width: 4),
            Text(
              l.partial,
              style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Status pill — FINAL (green) / LIVE (neutral bg, red text) / kickoff time
// ─────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final MatchModel match;
  final AppLocalizations l;
  final Duration offset;
  const _StatusPill({required this.match, required this.l, required this.offset});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    switch (match.status) {
      case MatchStatus.finished:
        return _pill(
          bg: cs.primary.withOpacity(0.12),
          fg: cs.primary,
          child: Text(l.finalLabel,
              style: TextStyle(color: cs.primary, fontSize: 10, fontWeight: FontWeight.w600)),
        );
      case MatchStatus.live:
        return _pill(
          bg: cs.onSurface.withOpacity(0.08),
          fg: cs.error,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: cs.error),
              ),
              const SizedBox(width: 4),
              Text(l.liveNow,
                  style: TextStyle(color: cs.error, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      case MatchStatus.scheduled:
        return _pill(
          bg: cs.onSurface.withOpacity(0.06),
          fg: cs.onSurface.withOpacity(0.6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 12, color: cs.onSurface.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text(
                match.matchDate != null ? _formatKickoff(match.matchDate!, offset) : '',
                style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
    }
  }

  Widget _pill({required Color bg, required Color fg, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// Hidden card — protected tail, not yet revealed
// ─────────────────────────────────────────────
class _HiddenCard extends StatelessWidget {
  final MatchModel match;
  final AppLocalizations l;
  final Duration offset;
  const _HiddenCard({required this.match, required this.l, required this.offset});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.withOpacity(0.35),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 20, color: cs.onSurface.withOpacity(0.4)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${translateTeam(context, match.homeTeam.name)} '
                  '${l.versusShort} '
                  '${translateTeam(context, match.awayTeam.name)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 2),
                Text(
                  l.hiddenUntilKickoff,
                  style: tt.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.45)),
                ),
              ],
            ),
          ),
          if (match.matchDate != null)
            Text(
              _formatKickoff(match.matchDate!, offset),
              style: tt.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.45)),
            ),
        ],
      ),
    );
  }
}

String _formatKickoff(DateTime d, Duration offset) {
  final t = d.toUtc().add(offset);
  return '${t.day.toString().padLeft(2, '0')}/'
      '${t.month.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

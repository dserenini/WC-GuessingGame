import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/profile/providers/personal_stats_provider.dart';
import 'package:copa2026/features/profile/screens/my_matches_detail_screen.dart';
import 'package:copa2026/l10n/team_translator.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';

/// "Pessoal" (Raio-X) tab of the Advanced Stats screen. Personal, client-side
/// breakdown of the current user's performance.
class PersonalStatsTab extends ConsumerWidget {
  const PersonalStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final stats = ref.watch(personalStatsProvider);

    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (stats.totalBets == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l.statsPersonalEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.55),
                ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PointsByGroupCard(stats: stats, l: l),
        _DistributionCard(stats: stats, l: l),
        _SignatureCard(stats: stats, l: l),
        _HandCard(stats: stats, l: l),
        _LuckyTeamsCard(stats: stats, l: l),
        _StreakCard(stats: stats, l: l),
      ],
    );
  }
}

void _push(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

// ─────────────────────────────────────────────
// Shared card shell
// ─────────────────────────────────────────────
class _PersonalCard extends StatelessWidget {
  final String? icon; // emoji
  final IconData? iconData; // material icon (overrides emoji)
  final String title;
  final String subtitle;
  final Widget child;
  const _PersonalCard({
    this.icon,
    this.iconData,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: iconData != null
                      ? Icon(iconData, size: 20, color: cs.primary)
                      : Text(icon ?? '', style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.55))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

Widget _emptyHint(BuildContext context, String msg) {
  final cs = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(msg,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: cs.onSurface.withOpacity(0.5))),
  );
}

Widget _tag(BuildContext context, String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700)),
  );
}

// ─────────────────────────────────────────────
// Points by group (bars, only groups with a played game)
// ─────────────────────────────────────────────
class _PointsByGroupCard extends StatelessWidget {
  final PersonalStats stats;
  final AppLocalizations l;
  const _PointsByGroupCard({required this.stats, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final groups = stats.finishedGroups;
    final maxPts = groups.fold<int>(0, (a, g) {
      final p = stats.pointsByGroup[g]!;
      return p > a ? p : a;
    });

    final bestLabel = stats.bestGroups.length > 1 ? l.statBestPlural : l.statBest;
    final worstLabel = stats.worstGroups.length > 1 ? l.statWorstPlural : l.statWorst;

    return _PersonalCard(
      icon: '📊',
      title: l.statGroupPointsTitle,
      subtitle: l.statGroupPointsSub,
      child: groups.isEmpty
          ? _emptyHint(context, l.statsPersonalEmpty)
          : Column(
              children: [
                for (final g in groups)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          child: Text(g,
                              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: maxPts == 0 ? 0 : stats.pointsByGroup[g]! / maxPts,
                              minHeight: 10,
                              backgroundColor: cs.primary.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                stats.bestGroups.contains(g)
                                    ? kPrimaryGreenLight
                                    : stats.worstGroups.contains(g)
                                        ? cs.error.withOpacity(0.7)
                                        : cs.primary.withOpacity(0.45),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          child: Text('${stats.pointsByGroup[g]}',
                              textAlign: TextAlign.end,
                              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _tag(context, '$bestLabel: ${stats.bestGroups.join(", ")}',
                        kPrimaryGreenLight),
                    if (stats.worstGroups.isNotEmpty)
                      _tag(context, '$worstLabel: ${stats.worstGroups.join(", ")}',
                          cs.error),
                  ],
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
// Distribution (exact / result / zero) + utilization
// ─────────────────────────────────────────────
class _DistributionCard extends StatelessWidget {
  final PersonalStats stats;
  final AppLocalizations l;
  const _DistributionCard({required this.stats, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final total = stats.exact + stats.result + stats.zeros;

    return _PersonalCard(
      iconData: Icons.pie_chart,
      title: l.statDistributionTitle,
      subtitle: l.statDistributionSub,
      child: total == 0
          ? _emptyHint(context, l.statsPersonalEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      if (stats.exact > 0)
                        Expanded(flex: stats.exact, child: Container(height: 16, color: kGold)),
                      if (stats.result > 0)
                        Expanded(
                            flex: stats.result,
                            child: Container(height: 16, color: kPrimaryGreenLight)),
                      if (stats.zeros > 0)
                        Expanded(
                            flex: stats.zeros,
                            child: Container(height: 16, color: cs.onSurface.withOpacity(0.18))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _legend(context, kGold, l.statExactUnit, stats.exact),
                    _legend(context, kPrimaryGreenLight, l.statDistResult, stats.result),
                    _legend(context, cs.onSurface.withOpacity(0.3), l.statDistZero, stats.zeros),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${l.statUtilization}: ',
                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.6))),
                    Text('${(stats.utilization * 100).round()}%',
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _legend(BuildContext context, Color color, String label, int count) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text('$count $label',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: cs.onSurface.withOpacity(0.8))),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Signature scores (top-3, tappable to the matches)
// ─────────────────────────────────────────────
class _SignatureCard extends StatelessWidget {
  final PersonalStats stats;
  final AppLocalizations l;
  const _SignatureCard({required this.stats, required this.l});

  @override
  Widget build(BuildContext context) {
    final maxCount =
        stats.topScores.isEmpty ? 0 : stats.topScores.first.count;

    return _PersonalCard(
      icon: '🔢',
      title: l.statSignatureTitle,
      subtitle: l.statSignatureSub,
      child: stats.topScores.isEmpty
          ? _emptyHint(context, l.statsPersonalEmpty)
          : Column(
              children: [
                for (final sc in stats.topScores)
                  _row(context, sc, maxCount),
              ],
            ),
    );
  }

  Widget _row(BuildContext context, ScoreCount sc, int maxCount) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final pretty = sc.score.replaceAll('-', ' - ');

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _push(
        context,
        MyMatchesDetailScreen(title: pretty, scoreline: sc.score),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(pretty,
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: maxCount == 0 ? 0 : sc.count / maxCount,
                  minHeight: 10,
                  backgroundColor: cs.primary.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary.withOpacity(0.5)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(l.rankingBetsCount(sc.count),
                style: tt.labelMedium?.copyWith(color: cs.onSurface.withOpacity(0.7))),
            Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Average goals — predicted vs real per game
// ─────────────────────────────────────────────
class _HandCard extends StatelessWidget {
  final PersonalStats stats;
  final AppLocalizations l;
  const _HandCard({required this.stats, required this.l});

  @override
  Widget build(BuildContext context) {
    return _PersonalCard(
      iconData: Icons.show_chart,
      title: l.statHandTitle,
      subtitle: l.statHandSub,
      child: stats.avgPredicted == null
          ? _emptyHint(context, l.statsPersonalEmpty)
          : Row(
              children: [
                Expanded(
                    child: _big(context, l.statsYou, stats.avgPredicted!, l.statGoalsPerGame,
                        Theme.of(context).colorScheme.primary)),
                Expanded(
                    child: _big(context, l.statHandReal, stats.avgReal!, l.statGoalsPerGame,
                        Theme.of(context).colorScheme.onSurface)),
              ],
            ),
    );
  }

  Widget _big(BuildContext context, String label, double value, String unit, Color color) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: tt.labelMedium?.copyWith(color: cs.onSurface.withOpacity(0.6))),
        const SizedBox(height: 2),
        Text(value.toStringAsFixed(1),
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: color)),
        Text(unit, style: tt.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.45))),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Lucky / unlucky team (tappable to the team's games)
// ─────────────────────────────────────────────
class _LuckyTeamsCard extends StatelessWidget {
  final PersonalStats stats;
  final AppLocalizations l;
  const _LuckyTeamsCard({required this.stats, required this.l});

  @override
  Widget build(BuildContext context) {
    return _PersonalCard(
      icon: '🍀',
      title: l.statLuckyTitle,
      subtitle: l.statLuckySub,
      child: stats.luckyTeam == null
          ? _emptyHint(context, l.statsPersonalEmpty)
          : Column(
              children: [
                _row(context, '🍀', l.statLucky, stats.luckyTeam!, kPrimaryGreenLight),
                if (stats.unluckyTeam != null) ...[
                  const SizedBox(height: 8),
                  _row(context, '💀', l.statUnlucky, stats.unluckyTeam!,
                      Theme.of(context).colorScheme.error),
                ],
              ],
            ),
    );
  }

  Widget _row(BuildContext context, String emoji, String label, TeamStat t, Color color) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _push(
        context,
        MyMatchesDetailScreen(
          title: translateTeam(context, t.name),
          teamName: t.name,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            FlagAvatar(flagUrl: t.flagUrl, radius: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: tt.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
                  Text(translateTeam(context, t.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Text('${t.points} ${l.statPointsUnit}',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
            Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Longest streak (tappable to the streak's games)
// ─────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final PersonalStats stats;
  final AppLocalizations l;
  const _StreakCard({required this.stats, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tappable = stats.longestStreak > 0;

    final content = Row(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${stats.longestStreak}',
                  style: tt.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
              const SizedBox(width: 6),
              Text(l.statRegularUnit,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.5))),
            ],
          ),
        ),
        if (tappable)
          Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withOpacity(0.3)),
      ],
    );

    return _PersonalCard(
      icon: '⚡',
      title: l.statStreakTitle,
      subtitle: l.statStreakSub,
      child: tappable
          ? InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _push(
                context,
                MyMatchesDetailScreen(
                  title: l.statStreakTitle,
                  matchIds: stats.streakMatchIds.toSet(),
                ),
              ),
              child: content,
            )
          : content,
    );
  }
}

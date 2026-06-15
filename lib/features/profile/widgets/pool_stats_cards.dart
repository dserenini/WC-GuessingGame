import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/profile/providers/pool_stats_provider.dart';
import 'package:copa2026/features/profile/screens/pool_pickers_screen.dart';
import 'package:copa2026/l10n/team_translator.dart';
import 'package:copa2026/shared/models/match.dart';

/// "Bolão" (family F) tab — pool-wide curiosities across everyone's bets.
class PoolStatsTab extends ConsumerWidget {
  const PoolStatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final matches = ref.watch(allMatchesProvider).valueOrNull;
    final pred = ref.watch(matchPredictabilityProvider).valueOrNull;
    final pop = ref.watch(scorePopularityProvider).valueOrNull;

    if (matches == null || pred == null || pop == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final byId = {for (final m in matches) m.id: m};
    final joined = <({MatchModel match, int exact})>[
      for (final p in pred)
        if (byId[p.matchId] != null) (match: byId[p.matchId]!, exact: p.exactCount),
    ];
    final unpredictable = [...joined]..sort((a, b) => a.exact.compareTo(b.exact));
    final everyoneKnew = [...joined]..sort((a, b) => b.exact.compareTo(a.exact));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PredictabilityCard(
          icon: '🎲',
          title: l.poolUnpredictableTitle,
          subtitle: l.poolUnpredictableSub,
          rows: unpredictable.take(10).toList(),
          l: l,
        ),
        _PredictabilityCard(
          icon: '🧠',
          title: l.poolEveryoneKnewTitle,
          subtitle: l.poolEveryoneKnewSub,
          rows: everyoneKnew.take(10).toList(),
          l: l,
        ),
        _PopularScoresCard(data: pop, l: l),
        _UniqueScoresCard(data: pop, l: l),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Card shell
// ─────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Widget child;
  const _Card({
    required this.icon,
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
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
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

/// "Ver mais / Ver menos" toggle aligned to the right of a card.
Widget _seeMoreButton(
    BuildContext context, bool expanded, VoidCallback onTap, AppLocalizations l) {
  return Align(
    alignment: Alignment.centerRight,
    child: TextButton(
      onPressed: onTap,
      child: Text(expanded ? l.statsSeeLess : l.statsSeeMore),
    ),
  );
}

// ─────────────────────────────────────────────
// Items 1 & 2 — most / least predictable games
// ─────────────────────────────────────────────
class _PredictabilityCard extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final List<({MatchModel match, int exact})> rows;
  final AppLocalizations l;
  const _PredictabilityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.l,
  });

  @override
  State<_PredictabilityCard> createState() => _PredictabilityCardState();
}

class _PredictabilityCardState extends State<_PredictabilityCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = widget.l;
    final rows = widget.rows;
    final visible = _expanded ? rows : rows.take(5).toList();

    return _Card(
      icon: widget.icon,
      title: widget.title,
      subtitle: widget.subtitle,
      child: rows.isEmpty
          ? Text(l.statsEmpty,
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.5)))
          : Column(
              children: [
                for (final r in visible)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MatchPickersScreen(match: r.match))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${translateTeam(context, r.match.homeTeam.name)} ${r.match.homeScore}-${r.match.awayScore} ${translateTeam(context, r.match.awayTeam.name)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${r.exact}',
                              style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800, color: cs.primary)),
                          const SizedBox(width: 4),
                          Text(l.poolNailedLabel,
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onSurface.withOpacity(0.45))),
                          Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withOpacity(0.3)),
                        ],
                      ),
                    ),
                  ),
                if (rows.length > 5)
                  _seeMoreButton(context, _expanded,
                      () => setState(() => _expanded = !_expanded), l),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
// Item 3 — most popular scorelines + lookup
// ─────────────────────────────────────────────
class _PopularScoresCard extends StatefulWidget {
  final ScorePopData data;
  final AppLocalizations l;
  const _PopularScoresCard({required this.data, required this.l});

  @override
  State<_PopularScoresCard> createState() => _PopularScoresCardState();
}

class _PopularScoresCardState extends State<_PopularScoresCard> {
  final _ctrl = TextEditingController();
  String? _result;
  bool _expanded = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _lookup(String text) {
    final nums = RegExp(r'\d+')
        .allMatches(text)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    if (nums.length < 2) {
      setState(() => _result = null);
      return;
    }
    final hit = widget.data.lookup(nums[0], nums[1]);
    final total = widget.data.total;
    setState(() {
      if (hit == null) {
        _result = widget.l.poolLookupNotFound;
      } else {
        final pct = total == 0 ? 0 : (hit.n / total * 100).round();
        _result = '${hit.label.replaceAll('-', ' - ')}:  $pct%  ·  ${widget.l.rankingBetsCount(hit.n)}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = widget.l;
    final top = widget.data.mostPopular(10);
    final visible = _expanded ? top : top.take(5).toList();
    final maxN = top.isEmpty ? 0 : top.first.n;
    final total = widget.data.total;

    return _Card(
      icon: '📊',
      title: l.poolPopularTitle,
      subtitle: l.poolPopularSub,
      child: total == 0
          ? Text(l.statsEmpty,
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.5)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in visible) _bar(context, s, maxN, total),
                if (top.length > 5)
                  _seeMoreButton(context, _expanded,
                      () => setState(() => _expanded = !_expanded), l),
                const SizedBox(height: 14),
                Text(l.poolLookupTitle,
                    style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _ctrl,
                  onChanged: _lookup,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: l.poolLookupHint,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 8),
                  Text(_result!,
                      style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600, color: cs.primary)),
                ],
              ],
            ),
    );
  }

  Widget _bar(BuildContext context, ScorePop s, int maxN, int total) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final pct = total == 0 ? 0 : (s.n / total * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(s.label.replaceAll('-', ' - '),
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: maxN == 0 ? 0 : s.n / maxN,
                minHeight: 12,
                backgroundColor: cs.primary.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$pct%',
              style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.primary)),
          const SizedBox(width: 6),
          Text('(${s.n})',
              style: tt.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Item 4 — unique (rarest) scorelines
// ─────────────────────────────────────────────
class _UniqueScoresCard extends StatefulWidget {
  final ScorePopData data;
  final AppLocalizations l;
  const _UniqueScoresCard({required this.data, required this.l});

  @override
  State<_UniqueScoresCard> createState() => _UniqueScoresCardState();
}

class _UniqueScoresCardState extends State<_UniqueScoresCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = widget.l;
    final rare = widget.data.leastPopular(10);
    final visible = _expanded ? rare : rare.take(5).toList();

    return _Card(
      icon: '🦄',
      title: l.poolUniqueTitle,
      subtitle: l.poolUniqueSub,
      child: rare.isEmpty
          ? Text(l.statsEmpty,
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.5)))
          : Column(
              children: [
                for (final s in visible)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            ScorelinePickersScreen(home: s.home, away: s.away))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      child: Row(
                        children: [
                          Text(s.label.replaceAll('-', ' - '),
                              style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800, color: cs.primary)),
                          const Spacer(),
                          Text(l.rankingBetsCount(s.n),
                              style: tt.bodyMedium
                                  ?.copyWith(color: cs.onSurface.withOpacity(0.7))),
                          Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withOpacity(0.3)),
                        ],
                      ),
                    ),
                  ),
                if (rare.length > 5)
                  _seeMoreButton(context, _expanded,
                      () => setState(() => _expanded = !_expanded), l),
              ],
            ),
    );
  }
}

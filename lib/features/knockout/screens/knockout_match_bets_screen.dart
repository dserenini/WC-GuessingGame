import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/shared/models/match.dart' show MatchStatus;
import 'package:copa2026/shared/models/bet.dart' show RankingEntry;
import 'package:copa2026/shared/utils/bet_filter.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/l10n/team_translator.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';

/// "Ver apostas" do MATA-MATA: escolhe um jogo (só finalizados/ao vivo/fechados
/// 30 min antes) e vê o palpite de todo mundo agrupado por placar. Sem filtro
/// "Top N" e sem realce de premiação (suprimidos no KO por ora).
class KnockoutMatchBetsScreen extends ConsumerWidget {
  final String title;
  final List<RankingEntry> members;
  const KnockoutMatchBetsScreen(
      {super.key, required this.title, required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final matchesAsync = ref.watch(koMatchesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (matches) {
          final sorted = [...matches]
            ..sort((a, b) => (a.matchDate ?? DateTime(0))
                .compareTo(b.matchDate ?? DateTime(0)));
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l.leagueBetsSelectMatch,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.6))),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) => _KoMatchSelectTile(
                    match: sorted[i],
                    title: title,
                    members: members,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KoMatchSelectTile extends StatelessWidget {
  final KoMatch match;
  final String title;
  final List<RankingEntry> members;
  const _KoMatchSelectTile(
      {required this.match, required this.title, required this.members});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final revealed = koMatchRevealed(match);

    final hasScore = match.homeScore != null &&
        match.awayScore != null &&
        (match.status == MatchStatus.live ||
            match.status == MatchStatus.finished);
    final scoreOrVs =
        hasScore ? '${match.homeScore} - ${match.awayScore}' : l.versusShort;

    final tile = Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            FlagAvatar(flagUrl: match.home?.flagUrl, radius: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(translateTeam(context, match.homeText),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(scoreOrVs,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: Text(translateTeam(context, match.awayText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            FlagAvatar(flagUrl: match.away?.flagUrl, radius: 14),
            const SizedBox(width: 6),
            Icon(revealed ? Icons.chevron_right : Icons.lock_outline,
                size: 18, color: cs.onSurface.withOpacity(revealed ? 0.4 : 0.3)),
          ],
        ),
      ),
    );

    if (!revealed) return Opacity(opacity: 0.6, child: tile);
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => KnockoutScorelinesScreen(
          title: title,
          matchId: match.id,
          members: members,
        ),
      )),
      child: tile,
    );
  }
}

// ─────────────────────────────────────────────
// Agrupamento por placar para um jogo do mata-mata
// ─────────────────────────────────────────────
class _ScoreGroup {
  final int home;
  final int away;
  final List<RankingEntry> users;
  final int bucket; // 0 exato, 1 resultado, 2 errou
  final int distance;
  _ScoreGroup(
      {required this.home,
      required this.away,
      required this.users,
      required this.bucket,
      required this.distance});
}

class KnockoutScorelinesScreen extends ConsumerStatefulWidget {
  final String title;
  final String matchId;
  final List<RankingEntry> members;
  const KnockoutScorelinesScreen(
      {super.key,
      required this.title,
      required this.matchId,
      required this.members});

  @override
  ConsumerState<KnockoutScorelinesScreen> createState() =>
      _KnockoutScorelinesScreenState();
}

class _KnockoutScorelinesScreenState
    extends ConsumerState<KnockoutScorelinesScreen> {
  int? _bucketFilter; // null = todos; 0/1/2 (só com placar real)
  final _searchCtrl = TextEditingController();
  final List<String> _scoreFilters = [];
  final List<String> _userFilters = [];
  final Map<String, bool> _expandOverride = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _hasFilters => _scoreFilters.isNotEmpty || _userFilters.isNotEmpty;

  bool _userHit(RankingEntry u) {
    final n = u.displayName.toLowerCase();
    return _userFilters.any((f) => n.contains(f.toLowerCase()));
  }

  _ScoreGroup? _viewGroup(_ScoreGroup g) {
    if (!_hasFilters) return g;
    if (_scoreFilters.contains('${g.home}-${g.away}')) return g;
    final users = g.users.where(_userHit).toList();
    if (users.isEmpty) return null;
    return _ScoreGroup(
        home: g.home,
        away: g.away,
        users: users,
        bucket: g.bucket,
        distance: g.distance);
  }

  void _addToken(String raw) {
    if (raw.trim().isEmpty) return;
    final token = classifyFilterToken(raw);
    setState(() {
      if (token.isScore) {
        if (!_scoreFilters.contains(token.value)) {
          _scoreFilters.add(token.value);
          _expandOverride[token.value] = true;
        }
      } else if (!_userFilters
          .any((u) => u.toLowerCase() == token.value.toLowerCase())) {
        _userFilters.add(token.value);
      }
      _searchCtrl.clear();
    });
  }

  bool _defaultExpanded(String key) {
    final scoreOnly = _scoreFilters.contains(key);
    return !scoreOnly && _userFilters.isNotEmpty;
  }

  bool _isExpanded(_ScoreGroup g) {
    final key = '${g.home}-${g.away}';
    return _expandOverride[key] ?? _defaultExpanded(key);
  }

  void _toggle(_ScoreGroup g) {
    final key = '${g.home}-${g.away}';
    setState(() => _expandOverride[key] = !_isExpanded(g));
  }

  String _bucketLabel(int b, bool finished) => switch (b) {
        0 => l.filterExact,
        1 => l.filterResult,
        _ => finished ? l.filterLost : l.filterLosing,
      };

  late AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    l = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(koMatchesProvider);
    final betsAsync = ref.watch(koMatchBetsProvider(widget.matchId));
    final currentUid = ref.watch(currentUserProvider)?.id;

    final matches = matchesAsync.valueOrNull;
    final bets = betsAsync.valueOrNull;
    if (matches == null || bets == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    KoMatch? match;
    for (final m in matches) {
      if (m.id == widget.matchId) {
        match = m;
        break;
      }
    }
    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: _Centered(text: l.leagueBetsNobody),
      );
    }

    final scheduled = match.status == MatchStatus.scheduled;
    final finished = match.status == MatchStatus.finished;
    final groups = _buildGroups(match, bets);

    final shown = <_ScoreGroup>[];
    for (final g in groups) {
      final bucketOk =
          scheduled || _bucketFilter == null || g.bucket == _bucketFilter;
      if (!bucketOk) continue;
      final v = _viewGroup(g);
      if (v != null) shown.add(v);
    }

    final items = <Widget>[_KoMatchHeader(match: match, l: l)];
    if (shown.isEmpty) {
      items.add(_Centered(text: l.leagueBetsNobody));
    } else if (scheduled) {
      for (final g in shown) {
        items.add(_scoreCard(g, match, currentUid));
      }
    } else {
      int? lastBucket;
      for (final g in shown) {
        if (_bucketFilter == null && g.bucket != lastBucket) {
          items.add(_SectionHeader(label: _bucketLabel(g.bucket, finished)));
          lastBucket = g.bucket;
        }
        items.add(_scoreCard(g, match, currentUid));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${translateTeam(context, match.homeText)} ${l.versusShort} '
          '${translateTeam(context, match.awayText)}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          if (groups.isNotEmpty) ...[
            _SearchField(
                controller: _searchCtrl,
                hint: l.searchScoreOrPlayer,
                onSubmit: _addToken),
            if (_hasFilters)
              _ActiveFilters(
                scores: _scoreFilters,
                users: _userFilters,
                onRemoveScore: (s) => setState(() => _scoreFilters.remove(s)),
                onRemoveUser: (u) => setState(() => _userFilters.remove(u)),
                onClear: () => setState(() {
                  _scoreFilters.clear();
                  _userFilters.clear();
                }),
              ),
            if (!scheduled)
              _BucketChips(
                selected: _bucketFilter,
                finished: finished,
                l: l,
                onSelect: (b) => setState(() => _bucketFilter = b),
              ),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(koMatchesProvider);
                ref.invalidate(koMatchBetsProvider(widget.matchId));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: items,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCard(_ScoreGroup g, KoMatch match, String? uid) => _ScoreCard(
        group: g,
        match: match,
        currentUid: uid,
        expanded: _isExpanded(g),
        onToggle: () => _toggle(g),
        isHit: _userHit,
      );

  List<_ScoreGroup> _buildGroups(KoMatch match, Map<String, (int, int)> bets) {
    final byUser = {for (final m in widget.members) m.userId: m};
    final hasReal = (match.status == MatchStatus.live ||
            match.status == MatchStatus.finished) &&
        match.homeScore != null &&
        match.awayScore != null;
    final rh = match.homeScore ?? 0;
    final ra = match.awayScore ?? 0;

    final Map<String, List<RankingEntry>> grouped = {};
    bets.forEach((userId, bet) {
      final entry = byUser[userId];
      if (entry == null) return; // fora do cohort (liga/ranking selecionado)
      grouped.putIfAbsent('${bet.$1}-${bet.$2}', () => []).add(entry);
    });

    final groups = grouped.entries.map((e) {
      final parts = e.key.split('-');
      final h = int.parse(parts[0]);
      final a = int.parse(parts[1]);
      int bucket = 0;
      if (hasReal) {
        if (h == rh && a == ra) {
          bucket = 0;
        } else if (h.compareTo(a) == rh.compareTo(ra)) {
          bucket = 1;
        } else {
          bucket = 2;
        }
      }
      final distance = (h - rh).abs() + (a - ra).abs();
      final users = e.value
        ..sort((x, y) =>
            x.displayName.toLowerCase().compareTo(y.displayName.toLowerCase()));
      return _ScoreGroup(
          home: h, away: a, users: users, bucket: bucket, distance: distance);
    }).toList();

    groups.sort((x, y) {
      if (x.bucket != y.bucket) return x.bucket.compareTo(y.bucket);
      if (x.distance != y.distance) return x.distance.compareTo(y.distance);
      if (x.home != y.home) return y.home.compareTo(x.home);
      return y.away.compareTo(x.away);
    });
    return groups;
  }
}

// ─────────────────────────────────────────────
// Widgets de apoio
// ─────────────────────────────────────────────
class _BucketChips extends StatelessWidget {
  final int? selected;
  final bool finished;
  final AppLocalizations l;
  final ValueChanged<int?> onSelect;
  const _BucketChips(
      {required this.selected,
      required this.finished,
      required this.l,
      required this.onSelect});

  Widget _chip(String label, bool sel, VoidCallback onTap) => ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12.5)),
        selected: sel,
        onSelected: (_) => onTap(),
        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        children: [
          _chip(l.filterAll, selected == null, () => onSelect(null)),
          _chip(l.filterExact, selected == 0, () => onSelect(0)),
          _chip(l.filterResult, selected == 1, () => onSelect(1)),
          _chip(finished ? l.filterLost : l.filterLosing, selected == 2,
              () => onSelect(2)),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmit;
  const _SearchField(
      {required this.controller, required this.hint, required this.onSubmit});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final hasText = widget.controller.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: widget.controller,
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSubmit,
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: hasText
              ? IconButton(
                  icon: const Icon(Icons.add_circle, size: 22),
                  tooltip: l.filterAdd,
                  onPressed: () => widget.onSubmit(widget.controller.text),
                )
              : null,
          filled: true,
          fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  final List<String> scores;
  final List<String> users;
  final ValueChanged<String> onRemoveScore;
  final ValueChanged<String> onRemoveUser;
  final VoidCallback onClear;
  const _ActiveFilters(
      {required this.scores,
      required this.users,
      required this.onRemoveScore,
      required this.onRemoveUser,
      required this.onClear});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    Widget chip(IconData icon, String label, VoidCallback onDeleted) =>
        InputChip(
          avatar: Icon(icon, size: 16, color: cs.primary),
          label: Text(label, style: const TextStyle(fontSize: 12.5)),
          onDeleted: onDeleted,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: cs.primary.withOpacity(0.08),
          side: BorderSide(color: cs.primary.withOpacity(0.25)),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final s in scores)
            chip(Icons.scoreboard_outlined, s, () => onRemoveScore(s)),
          for (final u in users)
            chip(Icons.person_outline, u, () => onRemoveUser(u)),
          if (scores.length + users.length > 1)
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: cs.onSurface.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(l.filterClear, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _KoMatchHeader extends StatelessWidget {
  final KoMatch match;
  final AppLocalizations l;
  const _KoMatchHeader({required this.match, required this.l});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final hasScore = match.homeScore != null &&
        match.awayScore != null &&
        (match.status == MatchStatus.live ||
            match.status == MatchStatus.finished);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(koRoundLabel(l, match.round).toUpperCase(),
              style: tt.labelSmall
                  ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _Team(match.homeText, match.home?.flagUrl)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                    hasScore
                        ? '${match.homeScore} - ${match.awayScore}'
                        : l.versusShort,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Expanded(child: _Team(match.awayText, match.away?.flagUrl)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Team extends StatelessWidget {
  final String name;
  final String? flagUrl;
  const _Team(this.name, this.flagUrl);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        FlagAvatar(flagUrl: flagUrl, radius: 20),
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

class _ScoreCard extends StatelessWidget {
  final _ScoreGroup group;
  final KoMatch match;
  final String? currentUid;
  final bool expanded;
  final VoidCallback onToggle;
  final bool Function(RankingEntry) isHit;
  const _ScoreCard(
      {required this.group,
      required this.match,
      required this.currentUid,
      required this.expanded,
      required this.onToggle,
      required this.isHit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasReal = match.homeScore != null &&
        match.awayScore != null &&
        (match.status == MatchStatus.live ||
            match.status == MatchStatus.finished);
    int? points;
    if (hasReal) {
      points = koBetPoints(match.round, group.home, group.away,
          match.homeScore!, match.awayScore!);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${group.home} - ${group.away}',
                        style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800, color: cs.primary)),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.person_outline,
                      size: 15, color: cs.onSurface.withOpacity(0.45)),
                  const SizedBox(width: 2),
                  Text('${group.users.length}',
                      style: tt.labelMedium
                          ?.copyWith(color: cs.onSurface.withOpacity(0.6))),
                  const Spacer(),
                  if (points != null) _PointsBadge(points: points),
                  const SizedBox(width: 6),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      size: 22, color: cs.onSurface.withOpacity(0.4)),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final u in group.users)
                      _UserChip(
                          name: u.displayName,
                          isMe: u.userId == currentUid,
                          isHit: isHit(u)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final String name;
  final bool isMe;
  final bool isHit;
  const _UserChip(
      {required this.name, required this.isMe, this.isHit = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = isMe
        ? (cs.primary.withOpacity(0.15), cs.primary)
        : isHit
            ? (cs.primary, cs.onPrimary)
            : (cs.surfaceContainerHighest.withOpacity(0.6), cs.onSurface);
    final Color border = isMe
        ? cs.primary.withOpacity(0.5)
        : isHit
            ? cs.primary
            : Colors.transparent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(name,
          style: TextStyle(
              fontSize: 12.5,
              fontWeight:
                  (isMe || isHit) ? FontWeight.w700 : FontWeight.w500,
              color: fg)),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = points >= 3
        ? (cs.primary.withOpacity(0.15), cs.primary)
        : points >= 1
            ? (Colors.amber.withOpacity(0.18), Colors.amber.shade800)
            : (cs.onSurface.withOpacity(0.08), cs.onSurface.withOpacity(0.55));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(points > 0 ? '+$points' : '0',
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: cs.outline.withOpacity(0.3))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(0.5))),
          ),
          Expanded(child: Divider(color: cs.outline.withOpacity(0.3))),
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  final String text;
  const _Centered({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ),
    );
  }
}

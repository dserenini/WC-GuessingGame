import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/leagues/providers/leagues_provider.dart';
import 'package:copa2026/features/profile/providers/profile_stats_provider.dart';
import 'package:copa2026/features/ranking/providers/ranking_provider.dart';
import 'package:copa2026/shared/providers/reveal_config_provider.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';
import 'package:copa2026/shared/utils/bet_points.dart';
import 'package:copa2026/shared/widgets/bet_filter_bar.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/l10n/team_translator.dart';

/// League "view bets": pick a game (with the two-level quick filter) and see
/// every league member's prediction for it, grouped by scoreline. Reached from
/// the "Ver apostas" button on a league card.
class LeagueMatchBetsScreen extends ConsumerStatefulWidget {
  final String leagueId;
  final String leagueName;

  const LeagueMatchBetsScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
  });

  @override
  ConsumerState<LeagueMatchBetsScreen> createState() =>
      _LeagueMatchBetsScreenState();
}

class _LeagueMatchBetsScreenState extends ConsumerState<LeagueMatchBetsScreen> {
  BetScope _scope = BetScope.all;
  BetStatus _status = BetStatus.all;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(myLeaguesRankingProvider(widget.leagueId));
    final matchesAsync = ref.watch(allMatchesProvider);
    final myStatsAsync = ref.watch(profileStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leagueName, overflow: TextOverflow.ellipsis),
      ),
      body: () {
        // Before the global deadline nobody may peek at others' bets.
        if (!isBettingLocked && !(kDebugMode && kDebugForceReveal)) {
          return _Centered(text: l.leagueBetsLockedUntilDeadline);
        }

        final members = membersAsync.valueOrNull;
        final matches = matchesAsync.valueOrNull;
        final myStats = myStatsAsync.valueOrNull;
        if (members == null || matches == null || myStats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Anti-copy gate: the viewer must have placed at least kRevealMinBets of
        // their own bets (mirrors the visitor profile).
        final required = myStats.totalMatches < kRevealMinBets
            ? myStats.totalMatches
            : kRevealMinBets;
        final gateOpen = (kDebugMode && kDebugForceReveal) ||
            myStats.totalBets >= required;
        if (!gateOpen) {
          return _AccessGate(done: myStats.totalBets, total: required, l: l);
        }

        final dayIds = _scope == BetScope.day
            ? ref.watch(matchesOfDayProvider).map((m) => m.id).toSet()
            : const <String>{};

        final visible = matches
            .where((m) =>
                betPassScope(_scope, m, dayIds) && betPassStatus(_status, m))
            .toList()
          ..sort((a, b) {
            final ia = int.tryParse(a.apiMatchId ?? '') ?? 0;
            final ib = int.tryParse(b.apiMatchId ?? '') ?? 0;
            return ia.compareTo(ib);
          });

        return Column(
          children: [
            BetFilterBar(
              scope: _scope,
              status: _status,
              onScope: (s) => setState(() => _scope = s),
              onStatus: (s) => setState(() => _status = s),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.leagueBetsSelectMatch,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? _Centered(text: l.filterNoGames)
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: visible.length,
                      itemBuilder: (_, i) => _MatchSelectTile(
                        match: visible[i],
                        allMatches: matches,
                        leagueId: widget.leagueId,
                        leagueName: widget.leagueName,
                        members: members,
                      ),
                    ),
            ),
          ],
        );
      }(),
    );
  }
}

// ─────────────────────────────────────────────
// Match selection tile
// ─────────────────────────────────────────────
class _MatchSelectTile extends ConsumerWidget {
  final MatchModel match;
  final List<MatchModel> allMatches;
  final String leagueId;
  final String leagueName;
  final List<RankingEntry> members;

  const _MatchSelectTile({
    required this.match,
    required this.allMatches,
    required this.leagueId,
    required this.leagueName,
    required this.members,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final cfg = ref.watch(revealConfigProvider).valueOrNull;

    // A protected-tail match that hasn't kicked off yet stays locked so leaders
    // can't peek at the final stretch (mirrors canRevealMatch).
    final revealable =
        cfg == null ? true : canRevealMatch(match, allMatches, cfg);

    final hasScore = match.homeScore != null &&
        match.awayScore != null &&
        (match.status == MatchStatus.live ||
            match.status == MatchStatus.finished);

    final scoreOrVs = hasScore
        ? '${match.homeScore} - ${match.awayScore}'
        : l.versusShort;

    final tile = Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            FlagAvatar(flagUrl: match.homeTeam.flagUrl, radius: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                translateTeam(context, match.homeTeam.name),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                scoreOrVs,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: Text(
                translateTeam(context, match.awayTeam.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            FlagAvatar(flagUrl: match.awayTeam.flagUrl, radius: 14),
            const SizedBox(width: 6),
            Icon(
              revealable ? Icons.chevron_right : Icons.lock_outline,
              size: 18,
              color: cs.onSurface.withOpacity(revealable ? 0.4 : 0.3),
            ),
          ],
        ),
      ),
    );

    if (!revealable) {
      return Opacity(opacity: 0.6, child: tile);
    }
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LeagueScorelinesScreen(
            leagueName: leagueName,
            matchId: match.id,
            members: members,
          ),
        ),
      ),
      child: tile,
    );
  }
}

// ─────────────────────────────────────────────
// Scorelines grouping for one match
// ─────────────────────────────────────────────
/// A scoreline bet by one or more league members. [bucket] classifies it for
/// the top filter by the points it scores against the real score (final for
/// finished, current for live): 0 = exact (3), 1 = correct result (1), 2 = lost
/// /losing (0). For scheduled games the bucket is unused. [reachable] (live
/// only) marks scorelines the match can still reach, shown before the ones that
/// can no longer happen within the same bucket. [distance] is the Manhattan
/// distance to the baseline score (or to 0-0 for scheduled = ascending goals).
class _ScoreGroup {
  final int home;
  final int away;
  final List<RankingEntry> users;
  final int bucket;
  final bool reachable;
  final int distance;
  _ScoreGroup({
    required this.home,
    required this.away,
    required this.users,
    required this.bucket,
    required this.reachable,
    required this.distance,
  });
}

class LeagueScorelinesScreen extends ConsumerStatefulWidget {
  final String leagueName;
  final String matchId;
  final List<RankingEntry> members;

  const LeagueScorelinesScreen({
    super.key,
    required this.leagueName,
    required this.matchId,
    required this.members,
  });

  @override
  ConsumerState<LeagueScorelinesScreen> createState() =>
      _LeagueScorelinesScreenState();
}

class _LeagueScorelinesScreenState
    extends ConsumerState<LeagueScorelinesScreen> {
  int? _bucketFilter; // null = all; 0/1/2 (finished & live only)
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _bucketLabel(int b, bool finished, AppLocalizations l) {
    switch (b) {
      case 0:
        return l.filterExact;
      case 1:
        return l.filterResult;
      default:
        return finished ? l.filterLost : l.filterLosing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(allMatchesProvider);
    final betsAsync = ref.watch(matchBetsProvider(widget.matchId));
    final currentUid = ref.watch(currentUserProvider)?.id;

    final matches = matchesAsync.valueOrNull;
    final bets = betsAsync.valueOrNull;

    if (matches == null || bets == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.leagueName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    MatchModel? match;
    for (final m in matches) {
      if (m.id == widget.matchId) {
        match = m;
        break;
      }
    }
    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.leagueName)),
        body: _Centered(text: l.leagueBetsNobody),
      );
    }

    final scheduled = match.status == MatchStatus.scheduled;
    final finished = match.status == MatchStatus.finished;
    final groups = _buildGroups(match, bets);

    // Filtered + section-grouped list of scoreline cards.
    final List<Widget> items = [
      _MatchHeader(match: match, l: l),
      const SizedBox(height: 12),
    ];
    if (scheduled) {
      final shown = _query.isEmpty
          ? groups
          : groups.where((g) => '${g.home}-${g.away}'.contains(_query)).toList();
      for (final g in shown) {
        items.add(_ScoreCard(
            group: g, match: match, currentUid: currentUid, l: l));
      }
      if (shown.isEmpty) items.add(_Centered(text: l.leagueBetsNobody));
    } else {
      final shown = _bucketFilter == null
          ? groups
          : groups.where((g) => g.bucket == _bucketFilter).toList();
      int? lastBucket;
      for (final g in shown) {
        if (_bucketFilter == null && g.bucket != lastBucket) {
          items.add(_SectionHeader(label: _bucketLabel(g.bucket, finished, l)));
          lastBucket = g.bucket;
        }
        items.add(_ScoreCard(
            group: g, match: match, currentUid: currentUid, l: l));
      }
      if (shown.isEmpty) items.add(_Centered(text: l.leagueBetsNobody));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${translateTeam(context, match.homeTeam.name)} '
          '${l.versusShort} '
          '${translateTeam(context, match.awayTeam.name)}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // Top filter: bucket chips (finished/live) or a scoreline search
          // (scheduled — no buckets, just ascending goals + lookup).
          if (groups.isNotEmpty)
            scheduled
                ? _ScoreSearchField(
                    controller: _searchCtrl,
                    hint: l.searchScore,
                    onChanged: (v) => setState(() => _query = v.trim()),
                  )
                : _BucketChips(
                    selected: _bucketFilter,
                    finished: finished,
                    l: l,
                    onSelect: (b) => setState(() => _bucketFilter = b),
                  ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allMatchesProvider);
                ref.invalidate(matchBetsProvider(widget.matchId));
              },
              child: groups.isEmpty
                  ? ListView(children: [_Centered(text: l.leagueBetsNobody)])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: items,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Groups members' bets by scoreline, attaching a [bucket] and the distance
  /// to the baseline score, then sorts by bucket → distance → home goals desc.
  List<_ScoreGroup> _buildGroups(MatchModel match, Map<String, BetModel> bets) {
    final memberIds = widget.members.map((m) => m.userId).toSet();
    final byUser = {for (final m in widget.members) m.userId: m};

    final Map<String, List<RankingEntry>> grouped = {};
    bets.forEach((userId, bet) {
      if (!memberIds.contains(userId)) return;
      final key = '${bet.homeScoreBet}-${bet.awayScoreBet}';
      grouped.putIfAbsent(key, () => []).add(byUser[userId]!);
    });

    final scheduled = match.status == MatchStatus.scheduled;
    // Only a live game can still change the score (→ "reachable" matters);
    // a finished game is fixed, a scheduled one has no score yet.
    final canScoreMore = match.status == MatchStatus.live;
    // Baseline: current/final score, or 0-0 for scheduled (→ ascending goals).
    final int ch = scheduled ? 0 : (match.homeScore ?? 0);
    final int ca = scheduled ? 0 : (match.awayScore ?? 0);

    final groups = grouped.entries.map((e) {
      final parts = e.key.split('-');
      final h = int.parse(parts[0]);
      final a = int.parse(parts[1]);

      // Bucket by the points this scoreline scores against the real score
      // (final for finished, current for live): 3 → exact, 1 → result, 0 → lost.
      int bucket = 0;
      if (!scheduled) {
        final pts = computeBetPoints(
            homeBet: h, awayBet: a, homeReal: ch, awayReal: ca);
        bucket = pts == 3 ? 0 : (pts == 1 ? 1 : 2);
      }
      // Live: a scoreline can still happen only if neither side must "un-score".
      final reachable = canScoreMore && h >= ch && a >= ca;

      final distance = (h - ch).abs() + (a - ca).abs();
      final users = e.value
        ..sort((x, y) =>
            x.displayName.toLowerCase().compareTo(y.displayName.toLowerCase()));
      return _ScoreGroup(
        home: h,
        away: a,
        users: users,
        bucket: bucket,
        reachable: reachable,
        distance: distance,
      );
    }).toList();

    groups.sort((x, y) {
      if (x.bucket != y.bucket) return x.bucket.compareTo(y.bucket);
      // Within a bucket, scorelines that can still happen come first (live).
      if (x.reachable != y.reachable) return x.reachable ? -1 : 1;
      if (x.distance != y.distance) return x.distance.compareTo(y.distance);
      if (x.home != y.home) return y.home.compareTo(x.home); // home goals desc
      return y.away.compareTo(x.away);
    });
    return groups;
  }
}

// ─────────────────────────────────────────────
// Top filter widgets
// ─────────────────────────────────────────────
class _BucketChips extends StatelessWidget {
  final int? selected;
  final bool finished;
  final AppLocalizations l;
  final ValueChanged<int?> onSelect;

  const _BucketChips({
    required this.selected,
    required this.finished,
    required this.l,
    required this.onSelect,
  });

  Widget _chip(String label, bool sel, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: sel,
      onSelected: (_) => onTap(),
      labelPadding: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

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

class _ScoreSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _ScoreSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
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

// ─────────────────────────────────────────────
// Match header (teams + score/status)
// ─────────────────────────────────────────────
class _MatchHeader extends ConsumerWidget {
  final MatchModel match;
  final AppLocalizations l;
  const _MatchHeader({required this.match, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final offset = ref.watch(timezoneProvider);

    final hasScore = match.homeScore != null &&
        match.awayScore != null &&
        (match.status == MatchStatus.live ||
            match.status == MatchStatus.finished);

    String statusText;
    Color statusColor;
    switch (match.status) {
      case MatchStatus.finished:
        statusText = l.finalLabel;
        statusColor = cs.primary;
        break;
      case MatchStatus.live:
        statusText = l.liveNow;
        statusColor = cs.error;
        break;
      case MatchStatus.scheduled:
        statusText = match.matchDate != null
            ? _fmtKickoff(match.matchDate!, offset)
            : '';
        statusColor = cs.onSurface.withOpacity(0.6);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _Team(match.homeTeam.name, match.homeTeam.flagUrl)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  hasScore ? '${match.homeScore} - ${match.awayScore}' : l.versusShort,
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(child: _Team(match.awayTeam.name, match.awayTeam.flagUrl)),
            ],
          ),
          const SizedBox(height: 8),
          Text(statusText,
              style: tt.labelSmall
                  ?.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
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

// ─────────────────────────────────────────────
// One scoreline card (score + its bettors)
// ─────────────────────────────────────────────
class _ScoreCard extends StatelessWidget {
  final _ScoreGroup group;
  final MatchModel match;
  final String? currentUid;
  final AppLocalizations l;

  const _ScoreCard({
    required this.group,
    required this.match,
    required this.currentUid,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Points this scoreline scored (or would score) against the real result.
    int? points;
    final hasRealScore = match.homeScore != null &&
        match.awayScore != null &&
        (match.status == MatchStatus.live ||
            match.status == MatchStatus.finished);
    if (hasRealScore) {
      points = computeBetPoints(
        homeBet: group.home,
        awayBet: group.away,
        homeReal: match.homeScore!,
        awayReal: match.awayScore!,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
                  child: Text(
                    '${group.home} - ${group.away}',
                    style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: cs.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${group.users.length}',
                  style: tt.labelMedium
                      ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
                ),
                const Spacer(),
                if (points != null) _PointsBadge(points: points),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final u in group.users)
                  _UserChip(name: u.displayName, isMe: u.userId == currentUid),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final String name;
  final bool isMe;
  const _UserChip({required this.name, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isMe
            ? cs.primary.withOpacity(0.15)
            : cs.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe ? cs.primary.withOpacity(0.5) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
          color: isMe ? cs.primary : cs.onSurface,
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(child: Divider(color: cs.outline.withOpacity(0.3))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────
class _Centered extends StatelessWidget {
  final String text;
  const _Centered({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ),
    );
  }
}

class _AccessGate extends StatelessWidget {
  final int done;
  final int total;
  final AppLocalizations l;
  const _AccessGate({required this.done, required this.total, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 56, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(l.completeBetsToView,
              textAlign: TextAlign.center,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(l.completeBetsToViewSub,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.6))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$done/$total',
                style: tt.titleMedium
                    ?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

String _fmtKickoff(DateTime d, Duration offset) {
  final t = d.toUtc().add(offset);
  return '${t.day.toString().padLeft(2, '0')}/'
      '${t.month.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

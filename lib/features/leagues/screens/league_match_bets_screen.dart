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
import 'package:copa2026/shared/utils/bet_filter.dart';
import 'package:copa2026/shared/widgets/bet_filter_bar.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/l10n/team_translator.dart';

/// "View bets": pick a game (with the two-level quick filter) and see every
/// member of a cohort's prediction for it, grouped by scoreline. Reached from
/// the "Ver apostas" button on a league card (cohort = league members) or from
/// the Ranking Geral (cohort = every participant, passed via [members]).
class LeagueMatchBetsScreen extends ConsumerStatefulWidget {
  /// League whose members form the cohort. Null when [members] is supplied
  /// directly (e.g. the whole pool, opened from the Ranking Geral).
  final String? leagueId;

  /// Title shown in the app bar (league name, or "Ranking" for the pool).
  final String leagueName;

  /// Pre-supplied cohort, used instead of fetching by [leagueId]. When set, the
  /// screen compares exactly this set of users.
  final List<RankingEntry>? members;

  /// When set, enables the "primeiros colocados" feature: a filter that keeps
  /// only the bets of users ranked 1..[prizeTopN], and a prize border on those
  /// users' chips. Null disables it (e.g. inside a private league).
  final int? prizeTopN;

  const LeagueMatchBetsScreen({
    super.key,
    this.leagueId,
    required this.leagueName,
    this.members,
    this.prizeTopN,
  }) : assert(leagueId != null || members != null,
            'Provide a leagueId or an explicit members list');

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
    // Cohort whose bets we compare: a pre-supplied list (e.g. the whole pool,
    // from the Ranking Geral) or a league's members fetched by id.
    final membersAsync = widget.members != null
        ? AsyncValue<List<RankingEntry>>.data(widget.members!)
        : ref.watch(myLeaguesRankingProvider(widget.leagueId!));
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
                        leagueName: widget.leagueName,
                        members: members,
                        prizeTopN: widget.prizeTopN,
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
  final String leagueName;
  final List<RankingEntry> members;
  final int? prizeTopN;

  const _MatchSelectTile({
    required this.match,
    required this.allMatches,
    required this.leagueName,
    required this.members,
    required this.prizeTopN,
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
            prizeTopN: prizeTopN,
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

  /// When set, enables the top-[prizeTopN] filter + prize border on those
  /// users' chips (Ranking Geral only). Null disables it (private leagues).
  final int? prizeTopN;

  const LeagueScorelinesScreen({
    super.key,
    required this.leagueName,
    required this.matchId,
    required this.members,
    this.prizeTopN,
  });

  @override
  ConsumerState<LeagueScorelinesScreen> createState() =>
      _LeagueScorelinesScreenState();
}

class _LeagueScorelinesScreenState
    extends ConsumerState<LeagueScorelinesScreen> {
  int? _bucketFilter; // null = all; 0/1/2 (finished & live only)
  final _searchCtrl = TextEditingController();

  // Busca aditiva: acumula tokens de placar ("1-0") e/ou trechos de nome de
  // usuário. Um placar é exibido se casar com QUALQUER token ativo (união), de
  // modo que "1-0", "2-0" e "ana" juntos revelam os três de uma vez.
  final List<String> _scoreFilters = [];
  final List<String> _userFilters = [];

  // Override de expansão por placar ("h-a"): presente = estado escolhido pelo
  // toque (true aberto / false recolhido); ausente = usa o padrão (recolhido,
  // ou auto-aberto quando um filtro de "quem" trouxe o grupo). Assim até os
  // grupos auto-abertos (nome/Top N) podem ser recolhidos no toque.
  final Map<String, bool> _expandOverride = {};

  // Cache dos grupos do build atual, para que ao adicionar um filtro novo se
  // saiba quais placares ele afeta (e expandi-los) sem reprocessar os bets.
  List<_ScoreGroup> _groupsCache = const [];

  // Filtro "primeiros colocados": quando ligado, exibe só os palpites dos
  // usuários no top [prizeTopN] do Ranking Geral. Só existe quando prizeTopN
  // está definido (Ranking Geral) e o grupo tem mais gente que o próprio top.
  bool _onlyTop = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _hasFilters => _scoreFilters.isNotEmpty || _userFilters.isNotEmpty;

  /// Usuário na zona de premiação (rank 1..prizeTopN do Ranking Geral).
  bool _isPrize(RankingEntry u) =>
      widget.prizeTopN != null && u.rank >= 1 && u.rank <= widget.prizeTopN!;

  /// Existe gente suficiente para o filtro "Top N" fazer sentido?
  bool get _topFilterAvailable =>
      widget.prizeTopN != null && widget.members.length > widget.prizeTopN!;

  bool get _anyFilter => _hasFilters || _onlyTop;

  /// Aplica os filtros como UNIÃO no nível do apostador e devolve a "visão" do
  /// grupo (placar + apostadores visíveis), ou null se nenhum casar.
  ///
  /// Regras (qualquer uma inclui o chip):
  /// • token de placar  → o placar inteiro qualifica (todos os apostadores);
  /// • token de nome    → só os apostadores cujo nome casa;
  /// • "Top N" ligado   → só os apostadores premiados.
  ///
  /// Assim "Danilo" + "2-1" + Top N mostra: todo o 2-1, os palpites do Danilo e
  /// os palpites do top N — somados (cumulativo), com a contagem recalculada.
  _ScoreGroup? _viewGroup(_ScoreGroup g) {
    if (!_anyFilter) return g; // sem filtro: grupo cheio
    if (_scoreFilters.contains('${g.home}-${g.away}')) return g;
    final users = g.users
        .where((u) =>
            (_userFilters.isNotEmpty && _userHit(u)) ||
            (_onlyTop && _isPrize(u)))
        .toList();
    if (users.isEmpty) return null;
    return _ScoreGroup(
      home: g.home,
      away: g.away,
      users: users,
      bucket: g.bucket,
      reachable: g.reachable,
      distance: g.distance,
    );
  }

  /// Classifica um termo enviado como placar ("2-1", "2x1") ou trecho de nome
  /// e o adiciona à lista de filtros correspondente (sem duplicar).
  void _addToken(String raw) {
    if (raw.trim().isEmpty) return;
    final token = classifyFilterToken(raw);
    setState(() {
      if (token.isScore) {
        if (!_scoreFilters.contains(token.value)) {
          _scoreFilters.add(token.value);
          _expandAffectedBy(scoreToken: token.value);
        }
      } else if (!_userFilters
          .any((u) => u.toLowerCase() == token.value.toLowerCase())) {
        _userFilters.add(token.value);
        _expandAffectedBy(userToken: token.value);
      }
      _searchCtrl.clear();
    });
  }

  /// Ao adicionar um filtro novo, marca como EXPANDIDOS os placares que ele
  /// afeta (sobrepondo um recolhimento anterior). Os demais ficam como estão.
  void _expandAffectedBy(
      {String? scoreToken, String? userToken, bool top = false}) {
    final uq = userToken?.toLowerCase();
    for (final g in _groupsCache) {
      final key = '${g.home}-${g.away}';
      final affected = (scoreToken != null && key == scoreToken) ||
          (uq != null &&
              g.users.any((u) => u.displayName.toLowerCase().contains(uq))) ||
          (top && g.users.any(_isPrize));
      if (affected) _expandOverride[key] = true;
    }
  }

  bool _userHit(RankingEntry u) {
    final n = u.displayName.toLowerCase();
    return _userFilters.any((f) => n.contains(f.toLowerCase()));
  }

  /// Estado padrão (sem override de toque): grupos trazidos por um filtro de
  /// "quem" (nome ou Top N) começam abertos para os chips casados aparecerem;
  /// os demais começam recolhidos (mostram a contagem; expandem ao toque).
  bool _defaultExpanded(String key) {
    final scoreOnly = _scoreFilters.contains(key);
    return !scoreOnly && (_userFilters.isNotEmpty || _onlyTop);
  }

  bool _isExpanded(_ScoreGroup g) {
    final key = '${g.home}-${g.away}';
    return _expandOverride[key] ?? _defaultExpanded(key);
  }

  /// O toque inverte o estado ATUAL e grava o override — assim um grupo
  /// auto-aberto (Top N/nome) pode ser recolhido, e reaberto no toque seguinte.
  void _toggle(_ScoreGroup g) {
    final key = '${g.home}-${g.away}';
    setState(() => _expandOverride[key] = !_isExpanded(g));
  }

  Widget _scoreCard(_ScoreGroup g, MatchModel match, String? currentUid,
      AppLocalizations l) {
    return _ScoreCard(
      group: g,
      match: match,
      currentUid: currentUid,
      l: l,
      expanded: _isExpanded(g),
      onToggle: () => _toggle(g),
      isHit: _userHit,
      isPrize: _isPrize,
    );
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
    _groupsCache = groups; // p/ _expandAffectedBy ao adicionar filtro novo

    // Lista recolhida e agrupada por seção, estreitada pelo chip de bucket
    // (encerrado/ao vivo) e pelos tokens de busca aditiva (placar/jogador).
    final List<Widget> items = [
      _MatchHeader(match: match, l: l),
      const SizedBox(height: 12),
    ];
    final shown = <_ScoreGroup>[];
    for (final g in groups) {
      final bucketOk =
          scheduled || _bucketFilter == null || g.bucket == _bucketFilter;
      if (!bucketOk) continue;
      final v = _viewGroup(g);
      if (v != null) shown.add(v);
    }
    if (shown.isEmpty) {
      items.add(_Centered(text: l.leagueBetsNobody));
    } else if (scheduled) {
      for (final g in shown) {
        items.add(_scoreCard(g, match, currentUid, l));
      }
    } else {
      int? lastBucket;
      for (final g in shown) {
        if (_bucketFilter == null && g.bucket != lastBucket) {
          items.add(_SectionHeader(label: _bucketLabel(g.bucket, finished, l)));
          lastBucket = g.bucket;
        }
        items.add(_scoreCard(g, match, currentUid, l));
      }
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
          // Busca aditiva (placar OU jogador) + chips dos filtros ativos +
          // chips de bucket (só encerrado/ao vivo, que têm placar real).
          if (groups.isNotEmpty) ...[
            _SearchTokenField(
              controller: _searchCtrl,
              hint: l.searchScoreOrPlayer,
              onSubmit: _addToken,
            ),
            // Filtro "primeiros colocados": mostra só os palpites do top N do
            // Ranking Geral (só no Ranking Geral, com gente suficiente).
            if (_topFilterAvailable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    avatar: Icon(
                      Icons.emoji_events_outlined,
                      size: 16,
                      color: _onlyTop ? kPrizeHighlight : null,
                    ),
                    label: Text(l.topNFilter(widget.prizeTopN!)),
                    selected: _onlyTop,
                    onSelected: (v) => setState(() {
                      _onlyTop = v;
                      if (v) _expandAffectedBy(top: true);
                    }),
                    selectedColor: kPrizeHighlight.withOpacity(0.18),
                    checkmarkColor: kPrizeHighlight,
                    side: BorderSide(
                      color: _onlyTop
                          ? kPrizeHighlight.withOpacity(0.6)
                          : Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.4),
                    ),
                  ),
                ),
              ),
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
        bucket = bucketForPoints(pts);
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

/// Search box that turns each submitted term into a filter token. Typing a
/// scoreline ("2-1") or a name and pressing enter (or the + button) calls
/// [onSubmit]; the parent classifies and accumulates it.
class _SearchTokenField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmit;

  const _SearchTokenField({
    required this.controller,
    required this.hint,
    required this.onSubmit,
  });

  @override
  State<_SearchTokenField> createState() => _SearchTokenFieldState();
}

class _SearchTokenFieldState extends State<_SearchTokenField> {
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

/// Removable chips for the active search tokens (scorelines + usernames), plus
/// a "limpar" action. Scoreline chips carry a scoreboard icon, name chips a
/// person icon, so the two kinds read apart at a glance.
class _ActiveFilters extends StatelessWidget {
  final List<String> scores;
  final List<String> users;
  final ValueChanged<String> onRemoveScore;
  final ValueChanged<String> onRemoveUser;
  final VoidCallback onClear;

  const _ActiveFilters({
    required this.scores,
    required this.users,
    required this.onRemoveScore,
    required this.onRemoveUser,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final s in scores)
            _filterChip(
              context,
              icon: Icons.scoreboard_outlined,
              label: s,
              onDeleted: () => onRemoveScore(s),
            ),
          for (final u in users)
            _filterChip(
              context,
              icon: Icons.person_outline,
              label: u,
              onDeleted: () => onRemoveUser(u),
            ),
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

  Widget _filterChip(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onDeleted}) {
    final cs = Theme.of(context).colorScheme;
    return InputChip(
      avatar: Icon(icon, size: 16, color: cs.primary),
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      onDeleted: onDeleted,
      deleteIconColor: cs.onSurface.withOpacity(0.5),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: cs.primary.withOpacity(0.08),
      side: BorderSide(color: cs.primary.withOpacity(0.25)),
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
// One scoreline card (collapsed: score + bettor count; expands to the bettors)
// ─────────────────────────────────────────────
class _ScoreCard extends StatelessWidget {
  final _ScoreGroup group;
  final MatchModel match;
  final String? currentUid;
  final AppLocalizations l;

  /// Whether the bettor list is shown. Collapsed cards show only the scoreline
  /// and how many people bet it; tapping toggles via [onToggle].
  final bool expanded;
  final VoidCallback onToggle;

  /// Marks a bettor matched by an active username filter, to highlight it.
  final bool Function(RankingEntry) isHit;

  /// Marks a bettor in the prize zone (top N of the Ranking Geral).
  final bool Function(RankingEntry) isPrize;

  const _ScoreCard({
    required this.group,
    required this.match,
    required this.currentUid,
    required this.l,
    required this.expanded,
    required this.onToggle,
    required this.isHit,
    required this.isPrize,
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
                    child: Text(
                      '${group.home} - ${group.away}',
                      style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800, color: cs.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.person_outline,
                      size: 15, color: cs.onSurface.withOpacity(0.45)),
                  const SizedBox(width: 2),
                  Text(
                    '${group.users.length}',
                    style: tt.labelMedium
                        ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
                  ),
                  const Spacer(),
                  if (points != null) _PointsBadge(points: points),
                  const SizedBox(width: 6),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
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
                        isHit: isHit(u),
                        isPrize: isPrize(u),
                      ),
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

  /// Matched by an active username filter (the player the viewer searched for).
  final bool isHit;

  /// In the prize zone (top N of the Ranking Geral) — keeps an amber border.
  final bool isPrize;
  const _UserChip({
    required this.name,
    required this.isMe,
    this.isHit = false,
    this.isPrize = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Cores ortogonais para não colidirem:
    // • fundo/texto: "você" = tom primário claro; busca = preenchido sólido
    //   (pop forte); neutro caso contrário.
    // • borda: premiação (top N) = âmbar, sobrepondo qualquer um — assim um
    //   premiado buscado mostra fundo sólido + borda âmbar.
    final (Color bg, Color fg) = isMe
        ? (cs.primary.withOpacity(0.15), cs.primary)
        : isHit
            ? (cs.primary, cs.onPrimary)
            : (cs.surfaceContainerHighest.withOpacity(0.6), cs.onSurface);
    final Color border = isPrize
        ? kPrizeHighlight.withOpacity(0.75)
        : isMe
            ? cs.primary.withOpacity(0.5)
            : isHit
                ? cs.primary
                : Colors.transparent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: isPrize ? 1.5 : 1),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight:
              (isMe || isHit || isPrize) ? FontWeight.w700 : FontWeight.w500,
          color: fg,
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

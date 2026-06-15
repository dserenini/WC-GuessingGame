import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/profile/providers/profile_stats_provider.dart';
import 'package:copa2026/features/profile/providers/stat_rankings_provider.dart';
import 'package:copa2026/features/profile/widgets/bet_comparison_card.dart';
import 'package:copa2026/shared/providers/reveal_config_provider.dart';
import 'package:copa2026/shared/utils/bet_points.dart';

/// Read-only view of another user's bets, reached by tapping their name in a
/// ranking. Each match shows B's bet with the viewer's own bet faded beneath it,
/// gated by [canRevealMatch]. Access requires the viewer to have placed at least
/// [kRevealMinBets] of their own bets (anti-copy gate).
class VisitorProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final RankingEntry? entry;

  /// When set, the bet list is filtered to only the matches relevant to that
  /// statistic (e.g. Brazil games, exact hits, near misses…), instead of
  /// showing every match. [contextLabel] is the stat name shown in the header.
  final StatRanking? statFilter;
  final String? contextLabel;

  const VisitorProfileScreen({
    super.key,
    required this.userId,
    this.entry,
    this.statFilter,
    this.contextLabel,
  });

  @override
  ConsumerState<VisitorProfileScreen> createState() =>
      _VisitorProfileScreenState();
}

class _VisitorProfileScreenState extends ConsumerState<VisitorProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Consistência da comparação: a SUA aposta (allBetsProvider — global e de
    // vida longa) costumava vir do cache enquanto a do jogador
    // (userBetsProvider — criado na hora) vinha fresca. Após uma pontuação ao
    // vivo, isso fazia o SEU ponto aparecer desatualizado (0) ao lado do dele
    // (atualizado). Ao abrir o perfil de qualquer jogador, forçamos os dois — e
    // os jogos, p/ placar/status — a buscar do servidor JUNTOS. Para jogo
    // encerrado o badge lê bet.points do banco (ver bet_comparison_card.dart).
    // Deferido para depois do primeiro frame: ref.invalidate dentro do
    // initState acessa o ProviderScope (inherited widget) antes do initState
    // concluir, o que dispara um assert em modo debug (invisível em release).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(allBetsProvider);
      ref.invalidate(userBetsProvider(widget.userId));
      ref.invalidate(allMatchesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final name = widget.entry?.displayName ?? '';
    final isSelf = widget.userId == ref.watch(currentUserProvider)?.id;
    final myStatsAsync = ref.watch(profileStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isSelf ? Icons.person_outline : Icons.visibility_outlined,
                      size: 13, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(isSelf ? l.youLabel : l.visitorMode,
                      style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: myStatsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Error(message: e.toString()),
        data: (myStats) {
          // Access gate: viewers who filled at least kRevealMinBets of their own
          // bets may peek (não precisa mais preencher todos os jogos).
          // Bypassed in debug builds with kDebugForceReveal, for local testing.
          final required = myStats.totalMatches < kRevealMinBets
              ? myStats.totalMatches
              : kRevealMinBets;
          // Viewing your own bets is always allowed: no anti-copy gate applies.
          final gateOpen = isSelf ||
              (kDebugMode && kDebugForceReveal) ||
              myStats.totalBets >= required;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allMatchesProvider);
              ref.invalidate(userBetsProvider(widget.userId));
              ref.invalidate(allBetsProvider);
              ref.invalidate(revealConfigProvider);
              ref.invalidate(profileStatsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _VisitorHeader(
                    name: name, entry: widget.entry, l: l, contextLabel: widget.contextLabel),
                if (!gateOpen)
                  _AccessGate(
                    done: myStats.totalBets,
                    total: required,
                    l: l,
                  )
                else
                  _BetList(
                    userId: widget.userId,
                    bName: isSelf ? l.statsYou : name,
                    statFilter: widget.statFilter,
                    isSelf: isSelf,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header (green card mirroring the profile look)
// ─────────────────────────────────────────────
class _VisitorHeader extends StatelessWidget {
  final String name;
  final RankingEntry? entry;
  final AppLocalizations l;
  final String? contextLabel;
  const _VisitorHeader(
      {required this.name,
      required this.entry,
      required this.l,
      this.contextLabel});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryGreen, kPrimaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.25),
            backgroundImage: entry?.avatarUrl != null ? NetworkImage(entry!.avatarUrl!) : null,
            child: entry?.avatarUrl == null
                ? Text(initial,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                if (contextLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    contextLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ] else if (entry != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${l.rankPositionShort(entry!.rank)} · ${l.rankingBetsCount(entry!.totalBets)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          // Stat-filtered view: the metric value is already shown on the card
          // the user came from, so the global "pts" total is omitted here.
          if (entry != null && contextLabel == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry!.totalPoints}',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                Text('pts', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bet list (matches + comparison cards)
// ─────────────────────────────────────────────
/// Quick-filter dimensions for the bet list. Both are single-select and
/// independent: the user picks one [_ScopeFilter] (round / day / none) and one
/// [_StatusFilter] (finished / unfinished / none), and they combine.
enum _ScopeFilter { all, round1, round2, round3, day }

enum _StatusFilter { all, finished, unfinished }

/// Bet-outcome filter (multi-select): exact score (3 pts), correct result
/// (1 pt) or missed (0 pts). Evaluated against the **screen owner's** bet.
enum _Outcome { exact, result, lost }

class _BetList extends ConsumerStatefulWidget {
  final String userId;
  final String bName;
  final StatRanking? statFilter;

  /// Self view: the bets shown are the viewer's own, so the comparison row is
  /// dropped and every match is revealed (no anti-copy gating for your own bets).
  final bool isSelf;

  const _BetList(
      {required this.userId,
      required this.bName,
      this.statFilter,
      this.isSelf = false});

  @override
  ConsumerState<_BetList> createState() => _BetListState();
}

class _BetListState extends ConsumerState<_BetList> {
  _ScopeFilter _scope = _ScopeFilter.all;
  _StatusFilter _status = _StatusFilter.all;
  final Set<_Outcome> _outcomes = {};

  /// Round 1..3 derived from the sequential `api_match_id` (1-24, 25-48, 49-72).
  /// Each matchday has 24 games and the ids are assigned in chronological order,
  /// so integer-dividing the id reproduces the round without a DB column.
  int? _roundOf(MatchModel m) {
    final id = int.tryParse(m.apiMatchId ?? '');
    if (id == null) return null;
    return ((id - 1) ~/ 24) + 1;
  }

  bool _passScope(MatchModel m, Set<String> dayIds) {
    switch (_scope) {
      case _ScopeFilter.all:
        return true;
      case _ScopeFilter.round1:
        return _roundOf(m) == 1;
      case _ScopeFilter.round2:
        return _roundOf(m) == 2;
      case _ScopeFilter.round3:
        return _roundOf(m) == 3;
      case _ScopeFilter.day:
        return dayIds.contains(m.id);
    }
  }

  bool _passStatus(MatchModel m) {
    switch (_status) {
      case _StatusFilter.all:
        return true;
      case _StatusFilter.finished:
        return m.status == MatchStatus.finished;
      case _StatusFilter.unfinished:
        return m.status != MatchStatus.finished; // live + scheduled
    }
  }

  /// Points the screen owner's [bet] scored on [m]: persisted points once the
  /// game is finished, provisional points while it is live, and null when there
  /// is no determined outcome yet (scheduled, or the owner didn't bet). Mirrors
  /// the badge logic in bet_comparison_card.dart.
  int? _ownerPoints(MatchModel m, BetModel? bet) {
    if (bet == null) return null;
    if (m.status == MatchStatus.finished) return bet.points;
    if (m.status == MatchStatus.live &&
        m.homeScore != null &&
        m.awayScore != null) {
      return computeBetPoints(
        homeBet: bet.homeScoreBet,
        awayBet: bet.awayScoreBet,
        homeReal: m.homeScore!,
        awayReal: m.awayScore!,
      );
    }
    return null;
  }

  bool _passOutcome(MatchModel m, BetModel? ownerBet) {
    if (_outcomes.isEmpty) return true; // no outcome filter active
    final pts = _ownerPoints(m, ownerBet);
    if (pts == null) return false; // no determined outcome → excluded
    if (_outcomes.contains(_Outcome.exact) && pts == 3) return true;
    if (_outcomes.contains(_Outcome.result) && pts == 1) return true;
    if (_outcomes.contains(_Outcome.lost) && pts == 0) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(allMatchesProvider);
    final bBetsAsync = ref.watch(userBetsProvider(widget.userId));
    final aBetsAsync = ref.watch(allBetsProvider);
    final cfgAsync = ref.watch(revealConfigProvider);

    final matches = matchesAsync.valueOrNull;
    final bBets = bBetsAsync.valueOrNull;
    final aBets = aBetsAsync.valueOrNull;
    final cfg = cfgAsync.valueOrNull;

    // The "Do Contra" filter needs cross-pool data from a dedicated view.
    final contrarianIds = widget.statFilter == StatRanking.contrarian
        ? ref.watch(contrarianMatchesProvider(widget.userId)).valueOrNull
        : const <String>{};

    if (matches == null ||
        bBets == null ||
        aBets == null ||
        cfg == null ||
        contrarianIds == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Stat drill-downs arrive pre-filtered to a curated subset; the quick
    // filters only make sense on the full bet list, so the bar is hidden there.
    final showFilters = widget.statFilter == null;

    final base = widget.statFilter == null
        ? matches
        : _applyStatFilter(widget.statFilter!, matches, bBets, contrarianIds);

    final dayIds = showFilters && _scope == _ScopeFilter.day
        ? ref.watch(matchesOfDayProvider).map((m) => m.id).toSet()
        : const <String>{};

    final visible = showFilters
        ? base
            .where((m) =>
                _passScope(m, dayIds) &&
                _passStatus(m) &&
                _passOutcome(m, bBets[m.id]))
            .toList()
        : base;

    return Column(
      children: [
        if (showFilters)
          _FilterBar(
            scope: _scope,
            status: _status,
            outcomes: _outcomes,
            l: l,
            onScope: (s) => setState(() => _scope = s),
            onStatus: (s) => setState(() {
              _status = s;
              // Outcome (exact/result/missed) only consolidates once a game is
              // over, so picking "not finished" would always return empty —
              // force the outcome filter back to "all".
              if (s == _StatusFilter.unfinished) _outcomes.clear();
            }),
            onToggleOutcome: (o) => setState(() {
              if (!_outcomes.remove(o)) _outcomes.add(o);
            }),
            onClearOutcomes: () => setState(_outcomes.clear),
          ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            child: Center(
              child: Text(
                showFilters ? l.filterNoGames : l.statsNoGames,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ),
          )
        else
          for (final m in visible)
            BetComparisonCard(
              match: m,
              betB: bBets[m.id],
              betA: aBets[m.id],
              bDisplayName: widget.bName,
              revealed: widget.isSelf || canRevealMatch(m, matches, cfg),
              showViewerRow: !widget.isSelf,
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Quick-filter bar: two single-select chip rows (scope + status)
// ─────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final _ScopeFilter scope;
  final _StatusFilter status;
  final Set<_Outcome> outcomes;
  final AppLocalizations l;
  final ValueChanged<_ScopeFilter> onScope;
  final ValueChanged<_StatusFilter> onStatus;
  final ValueChanged<_Outcome> onToggleOutcome;
  final VoidCallback onClearOutcomes;

  const _FilterBar({
    required this.scope,
    required this.status,
    required this.outcomes,
    required this.l,
    required this.onScope,
    required this.onStatus,
    required this.onToggleOutcome,
    required this.onClearOutcomes,
  });

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {bool enabled = true}) {
    // Tight chips so a row fits on a single line instead of wrapping: trimmed
    // internal padding, smaller label, and a denser visual density.
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: selected,
      onSelected: enabled ? (_) => onTap() : null,
      labelPadding: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Margin matches the score/player banners (horizontal 16) and chips Wrap to
    // the next line so the bar never exceeds the banners' width.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              _chip(l.filterAll, scope == _ScopeFilter.all,
                  () => onScope(_ScopeFilter.all)),
              _chip(l.filterRound1, scope == _ScopeFilter.round1,
                  () => onScope(_ScopeFilter.round1)),
              _chip(l.filterRound2, scope == _ScopeFilter.round2,
                  () => onScope(_ScopeFilter.round2)),
              _chip(l.filterRound3, scope == _ScopeFilter.round3,
                  () => onScope(_ScopeFilter.round3)),
              _chip(l.filterDay, scope == _ScopeFilter.day,
                  () => onScope(_ScopeFilter.day)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              _chip(l.filterAll, status == _StatusFilter.all,
                  () => onStatus(_StatusFilter.all)),
              _chip(l.filterFinished, status == _StatusFilter.finished,
                  () => onStatus(_StatusFilter.finished)),
              _chip(l.filterUnfinished, status == _StatusFilter.unfinished,
                  () => onStatus(_StatusFilter.unfinished)),
            ],
          ),
          const SizedBox(height: 8),
          // Outcome row is multi-select: "Todos" is active when nothing is
          // picked; the others toggle independently and accumulate. Disabled
          // while "not finished" is active, since scores aren't consolidated yet.
          Builder(builder: (_) {
            final outcomeEnabled = status != _StatusFilter.unfinished;
            return Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                _chip(l.filterAll, outcomes.isEmpty, onClearOutcomes),
                _chip(l.filterExact, outcomes.contains(_Outcome.exact),
                    () => onToggleOutcome(_Outcome.exact),
                    enabled: outcomeEnabled),
                _chip(l.filterResult, outcomes.contains(_Outcome.result),
                    () => onToggleOutcome(_Outcome.result),
                    enabled: outcomeEnabled),
                _chip(l.filterLost, outcomes.contains(_Outcome.lost),
                    () => onToggleOutcome(_Outcome.lost),
                    enabled: outcomeEnabled),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Selects the matches relevant to a given statistic for the tapped player.
/// Mirrors the criteria of the SQL ranking views so the detail matches the
/// number shown on the card.
List<MatchModel> _applyStatFilter(
  StatRanking stat,
  List<MatchModel> matches,
  Map<String, BetModel> bBets,
  Set<String> contrarianIds,
) {
  bool isBrazil(MatchModel m) =>
      m.homeTeam.name == 'Brasil' || m.awayTeam.name == 'Brasil';
  bool finished(MatchModel m) =>
      m.status == MatchStatus.finished &&
      m.homeScore != null &&
      m.awayScore != null;

  switch (stat) {
    case StatRanking.brazilPoints:
      return matches
          .where((m) => isBrazil(m) && bBets[m.id] != null)
          .toList();
    case StatRanking.exactScore:
      return matches.where((m) => (bBets[m.id]?.points ?? -1) == 3).toList();
    case StatRanking.nearMiss:
      return matches.where((m) {
        final b = bBets[m.id];
        if (b == null || !finished(m) || b.points >= 3) return false;
        final d = (b.homeScoreBet - m.homeScore!).abs() +
            (b.awayScoreBet - m.awayScore!).abs();
        return d == 1;
      }).toList();
    case StatRanking.regularity:
      return matches.where((m) {
        final b = bBets[m.id];
        return b != null && finished(m) && b.points > 0;
      }).toList();
    case StatRanking.boldness:
      return matches.where((m) {
        final b = bBets[m.id];
        if (b == null) return false;
        return (b.homeScoreBet - b.awayScoreBet).abs() >= 5 ||
            (b.homeScoreBet + b.awayScoreBet) >= 7;
      }).toList();
    case StatRanking.dailyTop:
      final ids = _bestDayMatchIds(matches, bBets);
      return matches.where((m) => ids.contains(m.id)).toList();
    case StatRanking.contrarian:
      return matches.where((m) => contrarianIds.contains(m.id)).toList();
  }
}

/// Match ids of the player's best single day (highest summed points), grouped
/// in São Paulo time (UTC-3) to match the `daily_top_rankings` view.
Set<String> _bestDayMatchIds(
    List<MatchModel> matches, Map<String, BetModel> bBets) {
  const spOffset = Duration(hours: -3);
  final Map<String, int> dayPoints = {};
  final Map<String, List<String>> dayMatchIds = {};

  for (final m in matches) {
    if (m.status != MatchStatus.finished || m.matchDate == null) continue;
    final b = bBets[m.id];
    if (b == null) continue;
    final sp = m.matchDate!.toUtc().add(spOffset);
    final key = '${sp.year}-${sp.month}-${sp.day}';
    dayPoints[key] = (dayPoints[key] ?? 0) + b.points;
    dayMatchIds.putIfAbsent(key, () => []).add(m.id);
  }

  if (dayPoints.isEmpty) return const {};
  var bestKey = dayPoints.keys.first;
  for (final e in dayPoints.entries) {
    if (e.value > dayPoints[bestKey]!) bestKey = e.key;
  }
  return dayMatchIds[bestKey]!.toSet();
}

// ─────────────────────────────────────────────
// Access gate (viewer hasn't filled all bets)
// ─────────────────────────────────────────────
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
        children: [
          Icon(Icons.lock_outline, size: 56, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            l.completeBetsToView,
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            l.completeBetsToViewSub,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$done/$total',
              style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  const _Error({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ),
    );
  }
}

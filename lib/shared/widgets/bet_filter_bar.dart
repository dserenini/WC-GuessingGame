import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:copa2026/shared/models/match.dart';

/// Shared quick-filter model for any "list of bets" screen (visitor profile and
/// league match bets). Three independent dimensions:
/// - [BetScope]: single-select round / day grouping.
/// - [BetStatus]: single-select finished / unfinished.
/// - [BetOutcome]: multi-select exact / result / missed (optional — only the
///   first two dimensions are shown when `showOutcome` is false).
enum BetScope { all, round1, round2, round3, day }

enum BetStatus { all, finished, unfinished }

enum BetOutcome { exact, result, lost }

/// Round 1..3 derived from the sequential `api_match_id` (1-24, 25-48, 49-72).
/// Each matchday has 24 games and ids are assigned chronologically, so an
/// integer division reproduces the round without a DB column.
int? betRoundOf(MatchModel m) {
  final id = int.tryParse(m.apiMatchId ?? '');
  if (id == null) return null;
  return ((id - 1) ~/ 24) + 1;
}

bool betPassScope(BetScope scope, MatchModel m, Set<String> dayIds) {
  switch (scope) {
    case BetScope.all:
      return true;
    case BetScope.round1:
      return betRoundOf(m) == 1;
    case BetScope.round2:
      return betRoundOf(m) == 2;
    case BetScope.round3:
      return betRoundOf(m) == 3;
    case BetScope.day:
      return dayIds.contains(m.id);
  }
}

bool betPassStatus(BetStatus status, MatchModel m) {
  switch (status) {
    case BetStatus.all:
      return true;
    case BetStatus.finished:
      return m.status == MatchStatus.finished;
    case BetStatus.unfinished:
      return m.status != MatchStatus.finished; // live + scheduled
  }
}

/// Two (or three) rows of compact single-line chips. The outcome row is shown
/// only when [showOutcome] is true, and is disabled while [status] is
/// "unfinished" (points only consolidate once a game is over).
class BetFilterBar extends StatelessWidget {
  final BetScope scope;
  final BetStatus status;
  final ValueChanged<BetScope> onScope;
  final ValueChanged<BetStatus> onStatus;

  final bool showOutcome;
  final Set<BetOutcome> outcomes;
  final ValueChanged<BetOutcome>? onToggleOutcome;
  final VoidCallback? onClearOutcomes;

  const BetFilterBar({
    super.key,
    required this.scope,
    required this.status,
    required this.onScope,
    required this.onStatus,
    this.showOutcome = false,
    this.outcomes = const {},
    this.onToggleOutcome,
    this.onClearOutcomes,
  });

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {bool enabled = true}) {
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
    final l = AppLocalizations.of(context)!;
    // Margin matches the score/player banners (horizontal 16); chips Wrap to the
    // next line so the bar never exceeds the banners' width.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              _chip(l.filterAll, scope == BetScope.all,
                  () => onScope(BetScope.all)),
              _chip(l.filterRound1, scope == BetScope.round1,
                  () => onScope(BetScope.round1)),
              _chip(l.filterRound2, scope == BetScope.round2,
                  () => onScope(BetScope.round2)),
              _chip(l.filterRound3, scope == BetScope.round3,
                  () => onScope(BetScope.round3)),
              _chip(l.filterDay, scope == BetScope.day,
                  () => onScope(BetScope.day)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              _chip(l.filterAll, status == BetStatus.all,
                  () => onStatus(BetStatus.all)),
              _chip(l.filterFinished, status == BetStatus.finished,
                  () => onStatus(BetStatus.finished)),
              _chip(l.filterUnfinished, status == BetStatus.unfinished,
                  () => onStatus(BetStatus.unfinished)),
            ],
          ),
          if (showOutcome) ...[
            const SizedBox(height: 8),
            // Multi-select; "Todos" active when nothing is picked. Disabled while
            // "not finished" is active, since scores aren't consolidated yet.
            Builder(builder: (_) {
              final outcomeEnabled = status != BetStatus.unfinished;
              return Wrap(
                spacing: 6,
                runSpacing: 8,
                children: [
                  _chip(l.filterAll, outcomes.isEmpty,
                      () => onClearOutcomes?.call()),
                  _chip(l.filterExact, outcomes.contains(BetOutcome.exact),
                      () => onToggleOutcome?.call(BetOutcome.exact),
                      enabled: outcomeEnabled),
                  _chip(l.filterResult, outcomes.contains(BetOutcome.result),
                      () => onToggleOutcome?.call(BetOutcome.result),
                      enabled: outcomeEnabled),
                  _chip(l.filterLost, outcomes.contains(BetOutcome.lost),
                      () => onToggleOutcome?.call(BetOutcome.lost),
                      enabled: outcomeEnabled),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

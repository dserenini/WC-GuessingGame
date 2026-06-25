import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/models/team.dart';
import 'package:copa2026/shared/models/match.dart' show MatchStatus;
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';
import 'package:copa2026/features/knockout/providers/champion_pick_provider.dart';
import 'package:copa2026/features/knockout/widgets/bracket_tree.dart';
import 'package:copa2026/features/knockout/widgets/knockout_bet_sheet.dart';
import 'package:copa2026/features/knockout/widgets/champion_pick_sheet.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';

/// Abre o popup de detalhes do confronto. Mesmo sem os times definidos, abre
/// em modo somente-leitura mostrando as infos prévias (nº, data, hora, status).
void openKnockoutMatch(BuildContext context, WidgetRef ref, KoMatch m) {
  final cur = (ref.read(koMyBetsProvider).valueOrNull ?? {})[m.id];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => KnockoutMatchSheet(
      match: m,
      initialHome: cur?.$1 ?? 0,
      initialAway: cur?.$2 ?? 0,
      hasBet: cur != null,
    ),
  );
}

class KnockoutScreen extends ConsumerWidget {
  const KnockoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mesmo com a rota acessível, só quem tem acesso (master ligado + inscrição
    // paga, ou admin) vê o conteúdo. Protege deep-link / URL direta.
    final l = AppLocalizations.of(context)!;
    final visible = ref.watch(knockoutVisibleProvider);
    return Scaffold(
      appBar: AppBar(title: Text('⚔️ ${l.koMenu}')),
      drawer: const AppDrawer(),
      body: visible.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _KnockoutLocked(),
        data: (ok) => ok ? const _BracketTab() : const _KnockoutLocked(),
      ),
    );
  }
}

/// Aviso para quem ainda não liberou o mata-mata (inscrição não confirmada).
class _KnockoutLocked extends StatelessWidget {
  const _KnockoutLocked();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: cs.onSurface.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              l.koLockedTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.koLockedDesc,
              style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAVEAMENTO
// ─────────────────────────────────────────────────────────────────────────────
class _BracketTab extends ConsumerWidget {
  const _BracketTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBracket = ref.watch(koBracketViewProvider);
    final matchesAsync = ref.watch(koMatchesProvider);
    final myBets = ref.watch(koMyBetsProvider).valueOrNull ?? const {};
    final championTeamId = ref.watch(koChampionPickProvider).valueOrNull?.teamId;
    final tzOffset = ref.watch(timezoneProvider);

    return Column(
      children: [
        const _ChampionCard(),
        _ViewToggle(isBracket: isBracket),
        Expanded(
          child: matchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorBox(message: '$e'),
            data: (matches) {
              if (matches.isEmpty) {
                return Center(
                    child: Text(AppLocalizations.of(context)!.koBracketUnavailable));
              }
              void onTap(KoMatch m) => openKnockoutMatch(context, ref, m);
              return isBracket
                  ? BracketTree(
                      matches: matches,
                      myBets: myBets,
                      championTeamId: championTeamId,
                      onTap: onTap)
                  : _BracketListView(
                      matches: matches,
                      ref: ref,
                      myBets: myBets,
                      championTeamId: championTeamId,
                      onTap: onTap,
                      tzOffset: tzOffset);
            },
          ),
        ),
      ],
    );
  }
}

class _ViewToggle extends ConsumerWidget {
  final bool isBracket;
  const _ViewToggle({required this.isBracket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: true, label: Text(l.koViewBracket), icon: const Icon(Icons.account_tree_outlined, size: 18)),
          ButtonSegment(value: false, label: Text(l.koViewList), icon: const Icon(Icons.view_list_outlined, size: 18)),
        ],
        selected: {isBracket},
        onSelectionChanged: (s) =>
            ref.read(koBracketViewProvider.notifier).state = s.first,
      ),
    );
  }
}

/// Card do palpite de CAMPEÃO no topo do mata-mata. Antes do 1º jogo: CTA para
/// escolher/trocar. Depois: somente leitura (com bônus se acertou).
class _ChampionCard extends ConsumerWidget {
  const _ChampionCard();

  void _openSheet(BuildContext context, String? currentTeamId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChampionPickSheet(currentTeamId: currentTeamId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final pick = ref.watch(koChampionPickProvider).valueOrNull;
    final teams = ref.watch(koAllTeamsProvider).valueOrNull ?? const <TeamModel>[];
    final firstDate = ref.watch(koFirstMatchDateProvider).valueOrNull;

    // Aberto enquanto não começou o mata-mata (ou ainda sem data definida).
    final open =
        firstDate == null || DateTime.now().toUtc().isBefore(firstDate.toUtc());

    TeamModel? team;
    if (pick != null) {
      for (final t in teams) {
        if (t.id == pick.teamId) {
          team = t;
          break;
        }
      }
    }
    final earnedBonus = pick != null && pick.points > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open ? () => _openSheet(context, pick?.teamId) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.koChampionTitle,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      if (team != null)
                        Row(
                          children: [
                            FlagAvatar(flagUrl: team.flagUrl, radius: 11),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(team.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: cs.primary)),
                            ),
                            if (earnedBonus) ...[
                              const SizedBox(width: 8),
                              _bonusBadge(cs, l.koPlusPoints(pick.points)),
                            ],
                          ],
                        )
                      else
                        Text(open ? l.koChampionSubtitle : l.koChampionEmptyLocked,
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (open)
                  FilledButton.tonal(
                    onPressed: () => _openSheet(context, pick?.teamId),
                    child: Text(pick == null ? l.koChampionCta : l.koChampionChange),
                  )
                else
                  Icon(Icons.lock_outline,
                      size: 18, color: cs.onSurface.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bonusBadge(ColorScheme cs, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: cs.primary)),
      );
}

class _BracketListView extends StatelessWidget {
  final List<KoMatch> matches;
  final WidgetRef ref;
  final Map<String, (int, int)> myBets;
  final String? championTeamId;
  final void Function(KoMatch) onTap;
  final Duration tzOffset;
  const _BracketListView(
      {required this.matches,
      required this.ref,
      required this.myBets,
      required this.championTeamId,
      required this.onTap,
      required this.tzOffset});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rounds = <String, List<KoMatch>>{};
    for (final r in kKoRounds) {
      // Na lista, ordena pelo nº oficial do jogo (73, 74, 75…); cai no slot
      // (ordem da árvore) se algum jogo não tiver número.
      final list = matches.where((m) => m.round == r).toList()
        ..sort((a, b) =>
            (a.matchNo ?? a.slot).compareTo(b.matchNo ?? b.slot));
      if (list.isNotEmpty) rounds[r] = list;
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(koMatchesProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          for (final round in kKoRounds)
            if (rounds[round] != null) ...[
              _RoundHeader(label: koRoundLabel(l, round), count: rounds[round]!.length),
              for (final m in rounds[round]!)
                _GameCard(
                    match: m,
                    myBet: myBets[m.id],
                    championTeamId: championTeamId,
                    onTap: () => onTap(m),
                    tzOffset: tzOffset),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _RoundHeader extends StatelessWidget {
  final String label;
  final int count;
  const _RoundHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: cs.primary,
                  letterSpacing: 0.3)),
          const SizedBox(width: 8),
          Text(l.koRoundGamesCount(count),
              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5))),
          const Expanded(child: Divider(indent: 12)),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final KoMatch match;
  final (int, int)? myBet;
  final String? championTeamId;
  final VoidCallback? onTap;
  final Duration tzOffset;
  const _GameCard(
      {required this.match,
      this.myBet,
      this.championTeamId,
      this.onTap,
      required this.tzOffset});

  /// A seleção escolhida como campeã está neste confronto? (realce dourado)
  bool get _hasChampion =>
      championTeamId != null &&
      (match.home?.id == championTeamId || match.away?.id == championTeamId);

  int? get _points {
    if (!match.isFinished || myBet == null || match.homeScore == null || match.awayScore == null) {
      return null;
    }
    return koBetPoints(
        match.round, myBet!.$1, myBet!.$2, match.homeScore!, match.awayScore!);
  }

  @override
  Widget build(BuildContext context) {
    final advId = match.advancing?.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      // Realce dourado quando a seleção-campeã do usuário joga neste confronto.
      shape: _hasChampion
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: kGold, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(match.gameNoLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: _side(context, match.home, match.homeSlotLabel, advId, alignEnd: true)),
                  _scoreBox(context),
                  Expanded(child: _side(context, match.away, match.awaySlotLabel, advId, alignEnd: false)),
                ],
              ),
              const SizedBox(height: 6),
              _betStrip(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _betStrip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final hasReal = match.status != MatchStatus.scheduled &&
        match.homeScore != null &&
        match.awayScore != null;
    // Agendado com palpite: o palpite já aparece no centro do card → não repete.
    if (!hasReal && myBet != null) return const SizedBox.shrink();
    final pts = _points;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.edit_note, size: 14, color: cs.onSurface.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(
          myBet == null ? l.koNoBet : l.koBetValue(myBet!.$1, myBet!.$2),
          style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: myBet == null
                  ? cs.onSurface.withOpacity(0.45)
                  : cs.onSurface.withOpacity(0.75)),
        ),
        if (pts != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: (pts > 0 ? cs.primary : cs.outline).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6)),
            child: Text('+$pts',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: pts > 0 ? cs.primary : cs.onSurface.withOpacity(0.6))),
          ),
        ],
      ],
    );
  }

  Widget _scoreBox(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasReal = match.status != MatchStatus.scheduled &&
        match.homeScore != null &&
        match.awayScore != null;

    // Live / Finalizado → placar REAL (com badge AO VIVO).
    if (hasReal) {
      final live = match.status == MatchStatus.live;
      final pens = (match.homePens != null && match.awayPens != null)
          ? '\n(${match.homePens}-${match.awayPens} pen)'
          : '';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (live)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: Text(AppLocalizations.of(context)!.koLiveBadge,
                    style: const TextStyle(
                        fontSize: 7.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            Text('${match.homeScore} - ${match.awayScore}$pens',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
      );
    }
    // Agendado com palpite → mostra o PALPITE como placar (cor primária).
    if (myBet != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('${myBet!.$1} - ${myBet!.$2}',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: cs.primary)),
      );
    }
    // Agendado sem palpite → data/hora no fuso escolhido pelo usuário.
    final d = match.matchDate?.toUtc().add(tzOffset);
    final time = d == null
        ? '—'
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}\n${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(time,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
    );
  }

  Widget _side(BuildContext context, TeamModel? team, String? fallbackLabel,
      String? advId,
      {required bool alignEnd}) {
    final cs = Theme.of(context).colorScheme;
    final isAdv = team != null && advId != null && team.id == advId;
    final isChampion =
        team != null && championTeamId != null && team.id == championTeamId;
    final name =
        team?.name ?? fallbackLabel ?? AppLocalizations.of(context)!.koTbd;

    Widget flag = FlagAvatar(flagUrl: team?.flagUrl, radius: 14);
    if (isChampion) {
      flag = Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: kGold, width: 2),
        ),
        child: flag,
      );
    }

    final children = <Widget>[
      flag,
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          name,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: (isAdv || isChampion) ? FontWeight.w800 : FontWeight.w500,
            color: team == null
                ? cs.onSurface.withOpacity(fallbackLabel != null ? 0.75 : 0.4)
                : isChampion
                    ? kGold
                    : isAdv
                        ? cs.primary
                        : cs.onSurface,
          ),
        ),
      ),
    ];

    return Row(
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd ? children.reversed.toList() : children,
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(AppLocalizations.of(context)!.koLoadError(message),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:copa2026/shared/models/team.dart';
import 'package:copa2026/shared/models/match.dart' show MatchStatus;
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';
import 'package:copa2026/features/knockout/widgets/bracket_tree.dart';
import 'package:copa2026/features/knockout/widgets/knockout_bet_sheet.dart';

/// Abre o popup de detalhes do confronto (resultado/ao vivo + seu palpite).
void openKnockoutMatch(BuildContext context, WidgetRef ref, KoMatch m) {
  if (!m.teamsKnown) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confronto ainda não definido.')));
    return;
  }
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
    return Scaffold(
      appBar: AppBar(title: const Text('⚔️ Mata-Mata')),
      drawer: const AppDrawer(),
      body: const _BracketTab(),
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

    return Column(
      children: [
        _ViewToggle(isBracket: isBracket),
        Expanded(
          child: matchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorBox(message: '$e'),
            data: (matches) {
              if (matches.isEmpty) {
                return const Center(child: Text('Chaveamento ainda não disponível.'));
              }
              void onTap(KoMatch m) => openKnockoutMatch(context, ref, m);
              return isBracket
                  ? BracketTree(matches: matches, myBets: myBets, onTap: onTap)
                  : _BracketListView(
                      matches: matches, ref: ref, myBets: myBets, onTap: onTap);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: true, label: Text('Bracket'), icon: Icon(Icons.account_tree_outlined, size: 18)),
          ButtonSegment(value: false, label: Text('Lista'), icon: Icon(Icons.view_list_outlined, size: 18)),
        ],
        selected: {isBracket},
        onSelectionChanged: (s) =>
            ref.read(koBracketViewProvider.notifier).state = s.first,
      ),
    );
  }
}

class _BracketListView extends StatelessWidget {
  final List<KoMatch> matches;
  final WidgetRef ref;
  final Map<String, (int, int)> myBets;
  final void Function(KoMatch) onTap;
  const _BracketListView(
      {required this.matches,
      required this.ref,
      required this.myBets,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rounds = <String, List<KoMatch>>{};
    for (final r in kKoRounds) {
      final list = matches.where((m) => m.round == r).toList()
        ..sort((a, b) => a.slot.compareTo(b.slot));
      if (list.isNotEmpty) rounds[r] = list;
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(koMatchesProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          for (final round in kKoRounds)
            if (rounds[round] != null) ...[
              _RoundHeader(label: koRoundLabel(round), count: rounds[round]!.length),
              for (final m in rounds[round]!)
                _GameCard(match: m, myBet: myBets[m.id], onTap: () => onTap(m)),
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
          Text('· $count jogos',
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
  final VoidCallback? onTap;
  const _GameCard({required this.match, this.myBet, this.onTap});

  int? get _points {
    if (!match.isFinished || myBet == null || match.homeScore == null || match.awayScore == null) {
      return null;
    }
    if (myBet!.$1 == match.homeScore && myBet!.$2 == match.awayScore) return 3;
    final bd = myBet!.$1.compareTo(myBet!.$2);
    final rd = match.homeScore!.compareTo(match.awayScore!);
    return bd == rd ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final advId = match.advancing?.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _side(context, match.home, advId, alignEnd: true)),
                  _scoreBox(context),
                  Expanded(child: _side(context, match.away, advId, alignEnd: false)),
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
          myBet == null ? 'Sem palpite' : 'Palpite ${myBet!.$1} × ${myBet!.$2}',
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
                child: const Text('AO VIVO',
                    style: TextStyle(
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
    // Agendado sem palpite → horário.
    final d = match.matchDate?.toLocal();
    final time = d == null
        ? 'x'
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(time,
          style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5))),
    );
  }

  Widget _side(BuildContext context, TeamModel? team, String? advId,
      {required bool alignEnd}) {
    final cs = Theme.of(context).colorScheme;
    final isAdv = team != null && advId != null && team.id == advId;
    final name = team?.name ?? 'A definir';

    final children = <Widget>[
      FlagAvatar(flagUrl: team?.flagUrl, radius: 14),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          name,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isAdv ? FontWeight.w800 : FontWeight.w500,
            color: team == null
                ? cs.onSurface.withOpacity(0.4)
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
        child: Text('Erro ao carregar: $message',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ),
    );
  }
}

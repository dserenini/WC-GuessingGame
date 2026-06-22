import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:copa2026/l10n/app_localizations.dart';


import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/ranking/providers/ranking_provider.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';
import 'package:copa2026/features/leagues/screens/league_match_bets_screen.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';

/// Escopo do Ranking Geral: tabela acumulada ("Geral") ou recortada por rodada
/// da fase de grupos (1, 2, 3). Cada rodada tem sua própria view/RANK no banco.
enum RankScope { general, round1, round2, round3 }

extension RankScopeX on RankScope {
  /// Número da rodada para a view `user_round_rankings`; null para "Geral".
  int? get round => switch (this) {
        RankScope.general => null,
        RankScope.round1 => 1,
        RankScope.round2 => 2,
        RankScope.round3 => 3,
      };
}

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  RankScope _scope = RankScope.general;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (index >= 0 && _itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.4,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final currentUid = ref.watch(currentUserProvider)?.id;

    // Lista completa de participantes (Ranking Geral acumulado), usada pelo
    // botão "Ver apostas" para comparar palpites por jogo entre TODOS. Mantida
    // assinada mesmo fora do escopo Geral para o botão responder de primeira.
    final allParticipants = ref.watch(rankingProvider).valueOrNull;

    // O Mata-Mata no Ranking (toggle + view) só existe para quem PARTICIPA
    // (knockoutVisibleProvider = master ligado E knockout_unlocked OU admin).
    // Vira o PADRÃO a partir de kKoRankingDefaultFrom (29/06 15:00 GMT+0); antes
    // disso, o participante abre na fase de grupos. Não-participante nunca vê.
    final iParticipate = ref.watch(knockoutVisibleProvider).valueOrNull ?? false;
    final koIsDefault =
        iParticipate && DateTime.now().toUtc().isAfter(kKoRankingDefaultFrom);
    final showKo =
        iParticipate && (ref.watch(rankingViewKnockoutProvider) ?? koIsDefault);

    // Mata-Mata: ranking zerado (koUserRankingProvider). Fase de grupos: "Geral"
    // usa a view acumulada (user_rankings); rodadas usam user_round_rankings.
    final rankingAsync = showKo
        ? ref.watch(koUserRankingProvider)
        : (_scope == RankScope.general
            ? ref.watch(rankingProvider)
            : ref.watch(roundRankingProvider(_scope.round!)));

    return Scaffold(
      appBar: AppBar(
        title: Text('🏆 ${l.ranking}'),
        leadingWidth: 100,
        leading: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const NotificationBell(),
          ],
        ),
        actions: [
          // "Ver apostas": comparativo de palpites por jogo entre TODOS os
          // participantes. Só após o prazo global (ninguém espia antes do fim
          // das apostas), igual às ligas privadas. Destacado em verde para
          // chamar atenção (ícone preenchido + fundo tonal).
          if (isBettingLocked)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: IconButton(
                icon: const Icon(Icons.scoreboard),
                tooltip: l.viewBets,
                style: IconButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (allParticipants == null || allParticipants.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.waitDataLoad)),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LeagueMatchBetsScreen(
                        leagueName: l.ranking,
                        members: allParticipants,
                        prizeTopN: kPrizeTopN,
                      ),
                    ),
                  );
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(
                showKo
                    ? koUserRankingProvider
                    : (_scope == RankScope.general
                        ? rankingProvider
                        : roundRankingProvider(_scope.round!))),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          if (iParticipate)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('Mata-Mata')),
                  ButtonSegment(value: false, label: Text('Fase de Grupos')),
                ],
                selected: {showKo},
                onSelectionChanged: (s) => ref
                    .read(rankingViewKnockoutProvider.notifier)
                    .state = s.first,
              ),
            ),
          // Recorte por rodada só na fase de grupos (o mata-mata zera e não
          // tem rodadas).
          if (!showKo)
            _RankScopeBar(
              scope: _scope,
              l: l,
              onChanged: (s) => setState(() => _scope = s),
            ),
          Expanded(
            child: rankingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (entries) {
          final q = _query.trim().toLowerCase();
          final filtered = q.isEmpty
              ? entries
              : entries
                  .where((e) => e.displayName.toLowerCase().contains(q))
                  .toList();

          RankingEntry? myEntry;
          for (final e in entries) {
            if (e.userId == currentUid) {
              myEntry = e;
              break;
            }
          }
          final myIndexInList =
              filtered.indexWhere((e) => e.userId == currentUid);

          // Realce de premiação — SOMENTE no Ranking Geral: os 11 primeiros
          // colocados (rank 1..11) e o último colocado (maior rank) recebem um
          // destaque âmbar no card. No ranking por rodada não há realce: as
          // medalhas já marcam o top 3 premiado. `lastRank` é calculado sobre a
          // lista completa (não a filtrada pela busca).
          final isGeneralScope = _scope == RankScope.general;
          final lastRank =
              entries.fold<int>(0, (m, e) => e.rank > m ? e.rank : m);
          bool isPrizeEntry(RankingEntry e) =>
              isGeneralScope &&
              e.rank >= 1 &&
              (e.rank <= kPrizeTopN || e.rank == lastRank);

          return Column(
            children: [
              _RankingSearchField(
                controller: _searchCtrl,
                hint: l.searchPlayer,
                onChanged: (v) => setState(() => _query = v),
              ),
              Expanded(
                child: Stack(
                  children: [
                    if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l.searchPlayer,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.4),
                            ),
                          ),
                        ),
                      )
                    else
                      ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _positionsListener,
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 88),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => RankingTile(
                          entry: filtered[i],
                          isMe: filtered[i].userId == currentUid,
                          isPrize: isPrizeEntry(filtered[i]),
                          l: l,
                        ),
                      ),
                    // ── Sticky "You" bar (docks top/bottom, hides when inline) ──
                    if (myEntry != null)
                      _StickyYouBar(
                        entry: myEntry,
                        myIndexInList: myIndexInList,
                        positionsListener: _positionsListener,
                        isPrize: isPrizeEntry(myEntry),
                        l: l,
                        onTap: () {
                          if (_query.isNotEmpty) {
                            setState(() {
                              _query = '';
                              _searchCtrl.clear();
                            });
                            final fullIndex = entries
                                .indexWhere((e) => e.userId == currentUid);
                            WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _scrollToIndex(fullIndex));
                          } else {
                            _scrollToIndex(myIndexInList);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SCOPE FILTER BAR (Geral / Rodada 1 / 2 / 3)
// ─────────────────────────────────────────────
// Linha de chips que troca a fonte de dados do ranking: "Geral" (acumulado) ou
// uma rodada específica da fase de grupos. Sempre visível (acima da busca),
// mesmo durante o carregamento.
class _RankScopeBar extends StatelessWidget {
  final RankScope scope;
  final AppLocalizations l;
  final ValueChanged<RankScope> onChanged;

  const _RankScopeBar({
    required this.scope,
    required this.l,
    required this.onChanged,
  });

  Widget _chip(String label, RankScope value) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: scope == value,
      onSelected: (_) => onChanged(value),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(l.rankingScopeGeneral, RankScope.general),
            const SizedBox(width: 6),
            _chip(l.filterRound1, RankScope.round1),
            const SizedBox(width: 6),
            _chip(l.filterRound2, RankScope.round2),
            const SizedBox(width: 6),
            _chip(l.filterRound3, RankScope.round3),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SEARCH FIELD
// ─────────────────────────────────────────────
class _RankingSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _RankingSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
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
// STICKY "YOU" BAR
// ─────────────────────────────────────────────
// Mostra a linha do usuário sempre visível. Reage à rolagem via
// ItemPositionsListener: se a linha real está acima da viewport → encaixa no
// topo; se está abaixo → encaixa no rodapé; se está visível → some (a linha
// inline assume). Quando o usuário não está na lista filtrada, fica no rodapé.
enum _Dock { top, bottom, hidden }

class _StickyYouBar extends StatelessWidget {
  final RankingEntry entry;
  final int myIndexInList;
  final ItemPositionsListener positionsListener;
  final bool isPrize;
  final AppLocalizations l;
  final VoidCallback onTap;

  const _StickyYouBar({
    required this.entry,
    required this.myIndexInList,
    required this.positionsListener,
    required this.isPrize,
    required this.l,
    required this.onTap,
  });

  _Dock _resolveDock(Iterable<ItemPosition> positions) {
    if (myIndexInList < 0) return _Dock.bottom;
    if (positions.isEmpty) return _Dock.bottom;

    var minIdx = positions.first.index;
    var maxIdx = positions.first.index;
    var visible = false;
    for (final p in positions) {
      if (p.index < minIdx) minIdx = p.index;
      if (p.index > maxIdx) maxIdx = p.index;
      // Considera "visível" só se a linha realmente aparece na viewport
      // (parte dela entre as bordas), não apenas presente na lista virtual.
      if (p.index == myIndexInList &&
          p.itemTrailingEdge > 0.06 &&
          p.itemLeadingEdge < 0.94) {
        visible = true;
      }
    }
    if (visible) return _Dock.hidden;
    if (myIndexInList < minIdx) return _Dock.top;
    return _Dock.bottom;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Iterable<ItemPosition>>(
      valueListenable: positionsListener.itemPositions,
      builder: (context, positions, _) {
        final dock = _resolveDock(positions);
        if (dock == _Dock.hidden) return const SizedBox.shrink();

        return Align(
          alignment:
              dock == _Dock.top ? Alignment.topCenter : Alignment.bottomCenter,
          child: _YouBarCard(
            entry: entry,
            l: l,
            isPrize: isPrize,
            dockedTop: dock == _Dock.top,
            onTap: onTap,
          ),
        );
      },
    );
  }
}

// Reusa o mesmo visual das linhas do ranking (estilo "isMe": leve tom da cor
// primária + borda), só que opaco e com sombra para "flutuar" sobre a lista.
// Uma setinha ▲/▼ indica se sua posição real está acima ou abaixo.
class _YouBarCard extends StatelessWidget {
  final RankingEntry entry;
  final AppLocalizations l;
  final bool isPrize;
  final bool dockedTop;
  final VoidCallback onTap;

  const _YouBarCard({
    required this.entry,
    required this.l,
    required this.isPrize,
    required this.dockedTop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final rankColor = switch (entry.rank) {
      1 => kGold,
      2 => kSilver,
      3 => kBronze,
      _ => cs.onSurface.withOpacity(0.4),
    };
    final rankEmoji = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '${entry.rank}',
    };

    // Fundo opaco (some o conteúdo da lista por trás) com o leve tom primário do
    // "você". O realce de premiação é discreto: só a BORDA fica âmbar quando o
    // usuário está na zona de premiação; o fundo segue primário.
    final cardColor = Theme.of(context).cardColor;
    final tinted = Color.alphaBlend(cs.primary.withOpacity(0.10), cardColor);
    final borderColor = isPrize
        ? kPrizeHighlight.withOpacity(0.45)
        : cs.primary.withOpacity(0.4);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: tinted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    rankEmoji,
                    textAlign: TextAlign.center,
                    style: tt.titleMedium?.copyWith(
                      color: rankColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primary.withOpacity(0.15),
                  backgroundImage: entry.avatarUrl != null
                      ? NetworkImage(entry.avatarUrl!)
                      : null,
                  child: entry.avatarUrl == null
                      ? Text(
                          entry.displayName.isNotEmpty
                              ? entry.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l.youLabel,
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.totalPoints}',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: entry.rank <= 3 ? rankColor : cs.onSurface,
                      ),
                    ),
                    Text(
                      'pts',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  dockedTop
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: cs.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RankingTile extends StatelessWidget {
  final RankingEntry entry;
  final bool isMe;
  final AppLocalizations l;

  /// Optional second line under the name. When null, only the name is shown
  /// (general ranking). Leagues pass the user's overall-ranking position here.
  final String? subtitle;

  /// Quando true, destaca o card com a cor de premiação (âmbar) — usado só no
  /// Ranking Geral para os 11 primeiros colocados + o último. Puramente visual.
  final bool isPrize;

  const RankingTile(
      {super.key,
      required this.entry,
      required this.isMe,
      required this.l,
      this.subtitle,
      this.isPrize = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final rankColor = switch (entry.rank) {
      1 => kGold,
      2 => kSilver,
      3 => kBronze,
      _ => cs.onSurface.withOpacity(0.4),
    };

    final rankEmoji = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '${entry.rank}',
    };

    // Tapping a name opens that user's bets. Other players are gated until
    // betting is locked (so nobody peeks before the deadline); your own row is
    // always tappable, since reviewing your own bets carries no copy risk.
    final tappable = isMe || isBettingLocked;

    // Realce discreto de premiação: APENAS a borda fica âmbar (sem preencher o
    // fundo). O fundo continua marcando só o "você" (tom primário). Os dois
    // sinais ficam ortogonais: fundo = você, borda âmbar = premiado. Se for as
    // duas coisas, o card tem fundo primário + borda âmbar.
    final Color bgColor = isMe
        ? cs.primary.withOpacity(0.08)
        : cs.surfaceContainerHighest.withOpacity(0.5);
    final Color borderColor = isPrize
        ? kPrizeHighlight.withOpacity(0.45)
        : isMe
            ? cs.primary.withOpacity(0.3)
            : Colors.transparent;
    final double borderWidth = (isPrize || isMe) ? 1.5 : 0;

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: bgColor,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 36,
              child: Text(
                rankEmoji,
                textAlign: TextAlign.center,
                style: tt.titleMedium?.copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.primary.withOpacity(0.15),
              backgroundImage: entry.avatarUrl != null
                  ? NetworkImage(entry.avatarUrl!)
                  : null,
              child: entry.avatarUrl == null
                  ? Text(
                      entry.displayName.isNotEmpty
                          ? entry.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayName,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                ],
              ),
            ),
            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.totalPoints}',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: entry.rank <= 3 ? rankColor : cs.onSurface,
                  ),
                ),
                Text(
                  'pts',
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            if (tappable) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.3)),
            ],
          ],
        ),
      ),
    );

    if (!tappable) return tile;
    return InkWell(
      onTap: () => context.push('/user/${entry.userId}', extra: entry),
      borderRadius: BorderRadius.circular(14),
      child: tile,
    );
  }
}

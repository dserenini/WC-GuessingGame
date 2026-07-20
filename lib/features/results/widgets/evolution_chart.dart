import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/ranking/providers/ranking_provider.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';
import 'package:copa2026/features/results/providers/evolution_provider.dart';
import 'package:copa2026/features/results/providers/evolution_selection_provider.dart';

/// Cor da SUA linha (sempre fixa, em destaque).
const _meColor = Color(0xFF2E7D32);

/// Paleta cíclica das linhas dos demais usuários (na ordem em que foram
/// adicionados). Sem limite de seleção → as cores se repetem após o fim.
const _palette = <Color>[
  Color(0xFF1976D2),
  Color(0xFFF57C00),
  Color(0xFF7B1FA2),
  Color(0xFF00897B),
  Color(0xFFC2185B),
  Color(0xFF5D4037),
  Color(0xFF455A64),
  Color(0xFFEF6C00),
  Color(0xFF3949AB),
  Color(0xFFD81B60),
];

Color _colorForIndex(int i) => _palette[i % _palette.length];

/// Aba "Evolução": comparador da POSIÇÃO no ranking ao longo do tempo (por jogo
/// ou por dia). Sua linha é fixa; você vai acumulando usuários para comparar
/// (busca livre ou escopada a uma liga). Eixo Y dinâmico pela faixa do conjunto.
class EvolutionTab extends ConsumerWidget {
  final EvolutionScope scope;
  const EvolutionTab({super.key, this.scope = EvolutionScope.groups});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final granularity = ref.watch(evolutionGranularityProvider(scope));
    final dataAsync = ref
        .watch(evolutionDataProvider((granularity: granularity, scope: scope)));

    return Column(
      children: [
        _Controls(l: l, granularity: granularity, scope: scope),
        _SelectionChips(scope: scope),
        Expanded(
          child: dataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (data) => data.isEmpty
                ? _empty(context, l.resultsEmpty)
                : _Chart(data: data, l: l, scope: scope),
          ),
        ),
      ],
    );
  }

  Widget _empty(BuildContext context, String msg) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurface.withOpacity(0.55)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLES — toggle jogo/dia + adicionar usuário (centralizados)
// ─────────────────────────────────────────────────────────────────────────────
class _Controls extends ConsumerWidget {
  final AppLocalizations l;
  final EvolutionGranularity granularity;
  final EvolutionScope scope;
  const _Controls(
      {required this.l, required this.granularity, required this.scope});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SegmentedButton<EvolutionGranularity>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: EvolutionGranularity.perGame,
                label: Text(l.evolutionByGame),
                icon: const Icon(Icons.sports_soccer, size: 16),
              ),
              ButtonSegment(
                value: EvolutionGranularity.perDay,
                label: Text(l.evolutionByDay),
                icon: const Icon(Icons.calendar_today, size: 16),
              ),
            ],
            selected: {granularity},
            onSelectionChanged: (s) => ref
                .read(evolutionGranularityProvider(scope).notifier)
                .state = s.first,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l.compareWith,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7))),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _openAddSheet(context),
                child: _PillButton(
                  icon: Icons.person_add_alt_1,
                  label: l.addUser,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddUserSheet(scope: scope),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PillButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHIPS — Você (fixo) + cada usuário adicionado (removível, cor = cor da linha)
// ─────────────────────────────────────────────────────────────────────────────
class _SelectionChips extends ConsumerWidget {
  final EvolutionScope scope;
  const _SelectionChips({required this.scope});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final selected = ref.watch(evolutionSelectionProvider(scope)).toList();
    final ranking = ref.watch(scope == EvolutionScope.knockout
                ? koUserRankingProvider
                : rankingProvider)
            .valueOrNull ??
        const [];
    final nameOf = {for (final e in ranking) e.userId: e.displayName};

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          Chip(
            visualDensity: VisualDensity.compact,
            avatar: const CircleAvatar(
                radius: 7, backgroundColor: _meColor),
            label: Text(l.evolutionYou,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          for (var i = 0; i < selected.length; i++)
            InputChip(
              visualDensity: VisualDensity.compact,
              avatar: CircleAvatar(
                  radius: 7, backgroundColor: _colorForIndex(i)),
              label: Text(nameOf[selected[i]] ?? '—'),
              onDeleted: () => ref
                  .read(evolutionSelectionProvider(scope).notifier)
                  .remove(selected[i]),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRÁFICO
// ─────────────────────────────────────────────────────────────────────────────
class _Chart extends ConsumerWidget {
  final EvolutionData data;
  final AppLocalizations l;
  final EvolutionScope scope;
  const _Chart({required this.data, required this.l, required this.scope});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final me = ref.watch(currentUserProvider)?.id;
    final selected = ref.watch(evolutionSelectionProvider(scope)).toList();
    final byUser = data.byUser;

    // Linhas a desenhar: Você (se tiver série) + adicionados presentes nos dados.
    final lines = <_Line>[];
    if (me != null && byUser.containsKey(me)) {
      lines.add(_Line(byUser[me]!, _meColor, 4, isMe: true));
    }
    for (var i = 0; i < selected.length; i++) {
      final id = selected[i];
      if (id == me || !byUser.containsKey(id)) continue;
      lines.add(_Line(byUser[id]!, _colorForIndex(i), 2.5));
    }

    if (lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l.resultsEmpty,
              textAlign: TextAlign.center,
              style: tt.bodyMedium
                  ?.copyWith(color: cs.onSurface.withOpacity(0.55))),
        ),
      );
    }

    // Janela do eixo Y = melhor..pior do CONJUNTO desenhado (exatos). A folga
    // fica no min/maxY (visual), pra os rótulos extremos não colarem na borda.
    var best = 1 << 30;
    var worst = 0;
    for (final ln in lines) {
      for (final p in ln.points) {
        if (p.rank < best) best = p.rank;
        if (p.rank > worst) worst = p.rank;
      }
    }
    final top = best; // melhor (nº menor) → topo
    final bottom = worst; // pior (nº maior) → base
    final span = bottom - top;
    final yStep = span <= 0 ? 1 : (span / 4).ceil();
    // Rótulos do Y: garante que melhor e pior SEMPRE apareçam.
    final yTicks = <int>{top, bottom};
    for (var r = top; r < bottom; r += yStep) {
      yTicks.add(r);
    }

    // Melhor/pior/final da SUA linha → marcadores no gráfico + legenda no topo.
    // (os pontos já vêm ordenados por x, então o último é a posição mais recente.)
    int? meBest, meWorst, meFinal;
    double? meFinalX;
    for (final ln in lines) {
      if (!ln.isMe || ln.points.isEmpty) continue;
      for (final p in ln.points) {
        if (meBest == null || p.rank < meBest) meBest = p.rank;
        if (meWorst == null || p.rank > meWorst) meWorst = p.rank;
      }
      meFinal = ln.points.last.rank;
      meFinalX = ln.points.last.x.toDouble();
    }

    // Faixa fixa do eixo X no modo "por jogo": grupos = 1..72; mata-mata =
    // 73..104 (nº oficial dos jogos). Mostra todos, mesmo os não finalizados.
    // Modo "por dia" usa índice ordinal.
    final ko = scope == EvolutionScope.knockout;
    final xFirst = ko ? 73 : 1;
    final xLast = ko ? 104 : 72;
    // Espaçamento dos rótulos no eixo X: KO tem menos jogos → de 4 em 4.
    final gameStep = ko ? 4 : 6;
    final xCount = data.xLabels.length;
    final dayStep = xCount <= 0 ? 1 : (xCount / 8).ceil();
    // Folga no eixo X (além do 1º e do último ponto) pra os marcadores das
    // pontas não colarem/serem cortados nas laterais.
    final lastDay = (xCount - 1).clamp(1, 1 << 30);
    final minX = data.byGame ? (xFirst - 2.5) : -1.0;
    final maxX =
        data.byGame ? (xLast + 2).toDouble() : (lastDay + 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.evolutionAxisPosition,
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurface.withOpacity(0.6))),
              if (meBest != null)
                _MarkerLabel(
                    color: const Color(0xFFFFB300),
                    text: '${l.evolutionBest}: ${meBest}º'),
              if (meWorst != null)
                _MarkerLabel(
                    color: const Color(0xFFC62828),
                    text: '${l.evolutionWorst}: ${meWorst}º'),
              if (meFinal != null)
                _MarkerLabel(
                    color: _meColor,
                    filled: true,
                    text: '${l.evolutionFinal}: ${meFinal}º'),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 22, 16),
            child: LineChart(
              LineChartData(
                // Eixo invertido: plotamos -rank, então o 1º (rank menor) fica
                // no topo. minY/maxY também negativos. Folga generosa (2.6) pra
                // os anéis de melhor/pior/final não colarem/serem cortados.
                minY: -bottom.toDouble() - 2.6,
                maxY: -top.toDouble() + 2.6,
                minX: minX,
                maxX: maxX,
                lineTouchData: const LineTouchData(enabled: false),
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yStep.toDouble(),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: cs.onSurface.withOpacity(0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final rank = (-value).round();
                        if (!yTicks.contains(rank)) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text('${rank}º',
                              style: tt.labelSmall?.copyWith(
                                  color: cs.onSurface.withOpacity(0.5))),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      // Por jogo: passo por escopo (6 grupos / 4 KO). Dia: ~8.
                      interval: data.byGame ? gameStep.toDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        if (data.byGame) {
                          final g = value.round();
                          if (g < xFirst || g > xLast) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('$g',
                                style: tt.labelSmall?.copyWith(
                                    color: cs.onSurface.withOpacity(0.5))),
                          );
                        }
                        final i = value.round();
                        if (i < 0 ||
                            i >= data.xLabels.length ||
                            i % dayStep != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(data.xLabels[i],
                              style: tt.labelSmall?.copyWith(
                                  color: cs.onSurface.withOpacity(0.5))),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  for (final ln in lines)
                    LineChartBarData(
                      spots: [
                        for (final p in ln.points)
                          FlSpot(p.x.toDouble(), -p.rank.toDouble()),
                      ],
                      isCurved: false,
                      color: ln.color,
                      barWidth: ln.width,
                      isStrokeCapRound: true,
                      // Só a SUA linha tem pontos. Final = ponto cheio (verde);
                      // melhor/pior = anéis (âmbar/vermelho).
                      dotData: FlDotData(
                        show: ln.isMe,
                        getDotPainter: (spot, pct, bar, idx) {
                          final rank = (-spot.y).round();
                          if (meFinalX != null &&
                              (spot.x - meFinalX).abs() < 0.001) {
                            return FlDotCirclePainter(
                              radius: 5.5,
                              color: _meColor,
                              strokeColor: Colors.white,
                              strokeWidth: 2,
                            );
                          }
                          if (rank == meBest) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: Colors.white,
                              strokeColor: const Color(0xFFFFB300),
                              strokeWidth: 3,
                            );
                          }
                          if (rank == meWorst) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: Colors.white,
                              strokeColor: const Color(0xFFC62828),
                              strokeWidth: 3,
                            );
                          }
                          return FlDotCirclePainter(
                            radius: 2.5,
                            color: ln.color,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Line {
  final List<EvolutionPoint> points;
  final Color color;
  final double width;
  final bool isMe;
  const _Line(this.points, this.color, this.width, {this.isMe = false});
}

/// Etiqueta "melhor: Xº" / "pior: Yº" / "final: Zº". `filled` = ponto cheio
/// (usado no final); senão, anel da cor do marcador.
class _MarkerLabel extends StatelessWidget {
  final Color color;
  final String text;
  final bool filled;
  const _MarkerLabel(
      {required this.color, required this.text, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.white,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 5),
        Text(text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — busca/adiciona qualquer usuário do bolão
// ─────────────────────────────────────────────────────────────────────────────
class _AddUserSheet extends ConsumerStatefulWidget {
  final EvolutionScope scope;
  const _AddUserSheet({required this.scope});

  @override
  ConsumerState<_AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends ConsumerState<_AddUserSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final me = ref.watch(currentUserProvider)?.id;
    final selected = ref.watch(evolutionSelectionProvider(widget.scope));

    // Sugestões: participantes do escopo atual (grupos ou mata-mata).
    final candidatesAsync = ref.watch(widget.scope == EvolutionScope.knockout
        ? koUserRankingProvider
        : rankingProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: l.searchPlayer,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: candidatesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (entries) {
                  final q = _query.trim().toLowerCase();
                  final list = entries
                      .where((e) => e.userId != me)
                      .where((e) =>
                          q.isEmpty ||
                          e.displayName.toLowerCase().contains(q))
                      .toList();
                  if (list.isEmpty) {
                    return Center(
                      child: Text(l.searchPlayer,
                          style: TextStyle(
                              color: cs.onSurface.withOpacity(0.4))),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final e = list[i];
                      final isSel = selected.contains(e.userId);
                      return ListTile(
                        dense: true,
                        onTap: () => ref
                            .read(evolutionSelectionProvider(widget.scope)
                                .notifier)
                            .toggle(e.userId),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: cs.primary.withOpacity(0.15),
                          backgroundImage: e.avatarUrl != null
                              ? NetworkImage(e.avatarUrl!)
                              : null,
                          child: e.avatarUrl == null
                              ? Text(
                                  e.displayName.isNotEmpty
                                      ? e.displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        title: Text(e.displayName),
                        trailing: Icon(
                          isSel ? Icons.check_circle : Icons.add_circle_outline,
                          color: isSel ? cs.primary : cs.onSurface.withOpacity(0.4),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

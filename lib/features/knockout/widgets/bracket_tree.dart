import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/shared/models/team.dart';
import 'package:copa2026/shared/models/match.dart' show MatchStatus;
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';

/// Árvore do chaveamento (16-avos → final) com linhas conectoras, navegável por
/// pan/zoom. Ao abrir, a câmera foca o PRIMEIRO card da fase atual (frontier).
/// A cada partida recém-finalizada (diff de avanços entre rebuilds), a bandeira
/// do vencedor percorre a linha até o slot da fase seguinte, o perdedor esmaece
/// e o conector acende — animação POR AVANÇO, não por rodada.
class BracketTree extends StatefulWidget {
  final List<KoMatch> matches;
  final Map<String, (int, int)> myBets; // ko_match_id → (home, away)
  final String? championTeamId; // seleção-campeã escolhida pelo usuário (realce)
  final void Function(KoMatch match)? onTap;
  const BracketTree(
      {super.key,
      required this.matches,
      this.myBets = const {},
      this.championTeamId,
      this.onTap});

  @override
  State<BracketTree> createState() => _BracketTreeState();
}

class _BracketTreeState extends State<BracketTree>
    with SingleTickerProviderStateMixin {
  final _controller = TransformationController();
  bool _fitted = false;
  late final AnimationController _advance;
  Size? _viewport;

  // Feeders ('round:slot') que avançaram no último diff e devem animar agora.
  // Mantido após o término p/ habilitar o replay; os travelers somem ao concluir.
  Set<String> _animKeys = {};

  static const _cols = ['16avos', 'oitavas', 'quartas', 'semis', 'final'];
  static const double _cardW = 150;
  static const double _cardH = 62; // +nº do jogo no topo → precisa de mais altura
  static const double _vGap = 14;
  static const double _colW = 190;
  static const double _unit = _cardH + _vGap;
  static const double _rowDy = 10; // distância do centro do card até cada linha
  static const double _flagInset = 16; // x do centro da bandeira dentro do card
  static const double _camMargin = 16; // margem do foco inicial (topo-esquerda)

  @override
  void initState() {
    super.initState();
    _advance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    // Reveal de boas-vindas: na 1ª abertura, anima UMA vez os avanços da rodada
    // mais recente já decidida (ex.: 16avos → oitavas dos jogos finalizados).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final keys = _latestAdvances();
      if (keys.isNotEmpty) {
        setState(() => _animKeys = keys);
        _advance.forward(from: 0);
      }
    });
  }

  /// Avanços da rodada mais profunda que já tem jogos finalizados com vencedor
  /// (os "últimos avanços"). Usado só no reveal de boas-vindas.
  Set<String> _latestAdvances() {
    int deepest = -1;
    for (var pc = 0; pc < _cols.length - 1; pc++) {
      if (widget.matches.any(
          (m) => m.round == _cols[pc] && m.isFinished && m.advancing != null)) {
        deepest = pc;
      }
    }
    if (deepest < 0) return {};
    return {
      for (final m in widget.matches)
        if (m.round == _cols[deepest] && m.isFinished && m.advancing != null)
          '${m.round}:${m.slot}'
    };
  }

  @override
  void didUpdateWidget(covariant BracketTree old) {
    super.didUpdateWidget(old);
    // Diff de avanços: quem passou a ter vencedor desde o último build → anima.
    final keys = _advancedSince(old.matches, widget.matches);
    if (keys.isNotEmpty) {
      setState(() => _animKeys = keys);
      _advance.forward(from: 0);
    }
  }

  /// Lógica de "diff de avanços" isolada do desenho: chaves 'round:slot' dos
  /// jogos que passaram de "sem vencedor" para "finalizado com `advancing`".
  Set<String> _advancedSince(List<KoMatch> oldM, List<KoMatch> nowM) {
    final oldById = {for (final m in oldM) m.id: m};
    final out = <String>{};
    for (final m in nowM) {
      final nowAdv = m.isFinished && m.advancing != null;
      final was = oldById[m.id];
      final wasAdv = was != null && was.isFinished && was.advancing != null;
      if (nowAdv && !wasAdv) out.add('${m.round}:${m.slot}');
    }
    return out;
  }

  @override
  void dispose() {
    _advance.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ── Câmera ──────────────────────────────────────────────────────────────
  // Zoom: fases iniciais (16as/8as) mostram ~metade dos jogos (janela de 8
  // linhas); a partir das quartas, mostram todos (altura cheia do bracket).
  double _zoomFor(Size vp, {required bool wholeHeight}) {
    const canvasH = 16 * _unit;
    final windowH = wholeHeight ? canvasH : 8 * _unit;
    return (vp.height / windowH).clamp(0.4, 1.5);
  }

  // Foca um card (col, cellCy) no canto SUPERIOR-ESQUERDO da viewport (margem
  // fixa), revelando os cards seguintes abaixo/à direita.
  Matrix4 _cameraForCell(int col, double cellCy, Size vp) {
    final k = _zoomFor(vp, wholeHeight: col >= 2);
    final tx = _camMargin - k * (col * _colW);
    final ty = _camMargin - k * (cellCy - _cardH / 2);
    return Matrix4(k, 0, 0, 0, 0, k, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
  }

  VoidCallback? _tapFor(KoMatch? m) =>
      (m == null || widget.onTap == null) ? null : () => widget.onTap!(m);

  (int, int)? _betFor(KoMatch? m) => m == null ? null : widget.myBets[m.id];

  // Time efetivo de um lado do card: o real, ou — se a rodada ainda não foi
  // preenchida no banco — o VENCEDOR do confronto alimentador (preenche o
  // "Venc. Jogo X" assim que o jogo de origem é decidido).
  TeamModel? _resolvedTeam(Map<String, KoMatch> byKey, int c, int s,
      {required bool home}) {
    final m = byKey['${_cols[c]}:$s'];
    final own = home ? m?.home : m?.away;
    if (own != null || c == 0) return own;
    final fSlot = home ? s * 2 - 1 : s * 2;
    return byKey['${_cols[c - 1]}:$fSlot']?.advancing;
  }

  // Progresso de "entrega" (0→1) de um time herdado cujo confronto alimentador
  // está animando agora: a seleção surge no slot conforme a bandeira chega.
  // null = sem entrega em curso (mostra normal).
  double? _deliveryT(Map<String, KoMatch> byKey, int c, int s,
      {required bool home}) {
    if (c == 0 || _animKeys.isEmpty || _advance.isCompleted) return null;
    final own = home ? byKey['${_cols[c]}:$s']?.home : byKey['${_cols[c]}:$s']?.away;
    if (own != null) return null; // já era real, não foi "entregue" pela anim
    final fSlot = home ? s * 2 - 1 : s * 2;
    final fKey = '${_cols[c - 1]}:$fSlot';
    if (!_animKeys.contains(fKey) || byKey[fKey]?.advancing == null) return null;
    // O time só surge quando a bandeira CHEGA (último trecho do voo), não antes.
    final v = Curves.easeOut.transform(_advance.value);
    return ((v - 0.8) / 0.2).clamp(0.0, 1.0);
  }

  // Opacidade do perdedor: card animando esmaece 1.0→0.4; estável 0.4 se
  // finalizado, 1.0 caso contrário.
  double _loserOpacityFor(String key, bool finished) {
    if (_animKeys.contains(key)) {
      return 1.0 - 0.6 * Curves.easeOut.transform(_advance.value);
    }
    return finished ? 0.4 : 1.0;
  }

  // Posição ao longo do "cotovelo" start → (midX,startY) → (midX,endY) → end.
  Offset _along(Offset s, Offset e, double t) {
    final midX = s.dx + (e.dx - s.dx) / 2;
    final p1 = Offset(midX, s.dy);
    final p2 = Offset(midX, e.dy);
    if (t < 1 / 3) return Offset.lerp(s, p1, t * 3)!;
    if (t < 2 / 3) return Offset.lerp(p1, p2, (t - 1 / 3) * 3)!;
    return Offset.lerp(p2, e, (t - 2 / 3) * 3)!;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Fase atual (frontier) p/ focar: a rodada mais RASA que ainda não teve
    // TODOS os jogos finalizados. O foco só avança pra próxima fase quando a
    // anterior encerra por completo. Tudo encerrado → foca a final.
    int frontier = _cols.length - 1;
    for (var c = 0; c < _cols.length; c++) {
      final games = widget.matches.where((m) => m.round == _cols[c]);
      if (games.isEmpty) continue;
      if (games.any((m) => !m.isFinished)) {
        frontier = c;
        break;
      }
    }

    final byKey = <String, KoMatch>{};
    for (final m in widget.matches) {
      byKey['${m.round}:${m.slot}'] = m;
    }

    final cy = <String, double>{};
    for (var s = 1; s <= 16; s++) {
      cy['16avos:$s'] = (s - 1) * _unit + _cardH / 2;
    }
    for (var c = 1; c < _cols.length; c++) {
      final count = 16 >> c;
      final prev = _cols[c - 1];
      for (var s = 1; s <= count; s++) {
        cy['${_cols[c]}:$s'] =
            ((cy['$prev:${s * 2 - 1}'] ?? 0) + (cy['$prev:${s * 2}'] ?? 0)) / 2;
      }
    }

    final canvasW = (_cols.length - 1) * _colW + _cardW;
    final canvasH = 16 * _unit;

    final segments = <_Seg>[];
    for (var c = 1; c < _cols.length; c++) {
      final count = 16 >> c;
      final prev = _cols[c - 1];
      final px = (c - 1) * _colW + _cardW;
      final x = c * _colW;
      for (var s = 1; s <= count; s++) {
        final childCy = cy['${_cols[c]}:$s'];
        if (childCy == null) continue;
        for (final f in [s * 2 - 1, s * 2]) {
          final fCy = cy['$prev:$f'];
          if (fCy == null) continue;
          final fKey = '$prev:$f';
          final feeder = byKey[fKey];
          segments.add(_Seg(px, fCy, x, childCy, feeder?.isFinished ?? false,
              _animKeys.contains(fKey)));
        }
      }
    }

    return LayoutBuilder(builder: (context, box) {
      final vh = box.maxHeight.isFinite ? box.maxHeight : 600.0;
      _viewport = Size(box.maxWidth, vh);
      if (!_fitted && box.maxWidth.isFinite) {
        // Abre focado na fase atual (1ª rodada não totalmente encerrada):
        // PRIMEIRO card (slot 1) dessa coluna no topo-esquerda.
        _controller.value = _cameraForCell(
            frontier, cy['${_cols[frontier]}:1'] ?? _cardH / 2, _viewport!);
        _fitted = true;
      }
      return Stack(
        children: [
          InteractiveViewer(
            transformationController: _controller,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(80),
            minScale: 0.3,
            maxScale: 2.5,
            child: AnimatedBuilder(
              animation: _advance,
              builder: (context, _) => SizedBox(
                width: canvasW,
                height: canvasH,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ConnectorPainter(
                          segments: segments,
                          base: cs.outline,
                          live: cs.primary,
                          t: Curves.easeOut.transform(_advance.value),
                        ),
                      ),
                    ),
                    // Cards
                    for (var c = 0; c < _cols.length; c++)
                      for (var s = 1; s <= (16 >> c); s++)
                        if (cy['${_cols[c]}:$s'] != null)
                          Positioned(
                            left: c * _colW,
                            top: cy['${_cols[c]}:$s']! - _cardH / 2,
                            width: _cardW,
                            height: _cardH,
                            child: _BracketCard(
                              match: byKey['${_cols[c]}:$s'],
                              home: _resolvedTeam(byKey, c, s, home: true),
                              away: _resolvedTeam(byKey, c, s, home: false),
                              homeDeliveryT: _deliveryT(byKey, c, s, home: true),
                              awayDeliveryT: _deliveryT(byKey, c, s, home: false),
                              loserOpacity: _loserOpacityFor('${_cols[c]}:$s',
                                  byKey['${_cols[c]}:$s']?.isFinished ?? false),
                              bet: _betFor(byKey['${_cols[c]}:$s']),
                              championTeamId: widget.championTeamId,
                              onTap: _tapFor(byKey['${_cols[c]}:$s']),
                            ),
                          ),
                    // 3º lugar (avulso)
                    if (byKey['3lugar:1'] != null)
                      Positioned(
                        left: (_cols.length - 1) * _colW,
                        top: canvasH - _cardH - 8,
                        width: _cardW,
                        height: _cardH,
                        child: _BracketCard(
                          match: byKey['3lugar:1'],
                          home: byKey['3lugar:1']?.home,
                          away: byKey['3lugar:1']?.away,
                          loserOpacity: _loserOpacityFor(
                              '3lugar:1', byKey['3lugar:1']?.isFinished ?? false),
                          label: AppLocalizations.of(context)!.koThirdPlaceShort,
                          bet: _betFor(byKey['3lugar:1']),
                          championTeamId: widget.championTeamId,
                          onTap: _tapFor(byKey['3lugar:1']),
                        ),
                      ),
                    // Bandeiras viajando (avanços recém-finalizados)
                    ..._travelers(cy, byKey),
                  ],
                ),
              ),
            ),
          ),
          // Replay do último avanço (só quando há um para reanimar).
          if (_animKeys.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: cs.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _advance.forward(from: 0),
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(Icons.replay, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  /// Tokens (bandeiras) dos avanços ativos percorrendo o caminho. Some ao
  /// concluir (mantemos `_animKeys` só p/ o replay).
  List<Widget> _travelers(Map<String, double> cy, Map<String, KoMatch> byKey) {
    if (_animKeys.isEmpty || _advance.isCompleted) return const [];
    final t = Curves.easeOut.transform(_advance.value);
    if (t <= 0) return const [];

    final tokens = <Widget>[];
    for (final key in _animKeys) {
      final sep = key.indexOf(':');
      final round = key.substring(0, sep);
      final fSlot = int.tryParse(key.substring(sep + 1));
      if (fSlot == null) continue;
      final pc = _cols.indexOf(round); // coluna do feeder
      if (pc < 0 || pc + 1 >= _cols.length) continue; // final/3lugar: sem destino
      final c = pc + 1; // coluna de destino
      final feeder = byKey[key];
      final adv = feeder?.advancing;
      if (adv == null) continue;

      final s = (fSlot + 1) ~/ 2; // slot de destino
      final destIsHome = fSlot.isOdd; // ímpar = casa do confronto seguinte
      final fCy = cy[key];
      final childCy = cy['${_cols[c]}:$s'];
      if (fCy == null || childCy == null) continue;
      final advIsHome = adv.id == feeder!.home?.id;

      final start = Offset(
        pc * _colW + _cardW,
        fCy + (advIsHome ? -_rowDy : _rowDy),
      );
      final end = Offset(
        c * _colW + _flagInset,
        childCy + (destIsHome ? -_rowDy : _rowDy),
      );
      final p = _along(start, end, t);
      tokens.add(Positioned(
        left: p.dx - 11,
        top: p.dy - 11,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: FlagAvatar(flagUrl: adv.flagUrl, radius: 11),
        ),
      ));
    }
    return tokens;
  }
}

class _Seg {
  final double x1, y1, x2, y2;
  final bool live; // feeder finalizado → conector aceso
  final bool animating; // feeder no batch de avanço atual → ramp 0→1
  _Seg(this.x1, this.y1, this.x2, this.y2, this.live, this.animating);
}

class _ConnectorPainter extends CustomPainter {
  final List<_Seg> segments;
  final Color base;
  final Color live;
  final double t; // 0..1 da animação de avanço
  _ConnectorPainter({
    required this.segments,
    required this.base,
    required this.live,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in segments) {
      final midX = s.x1 + (s.x2 - s.x1) / 2;
      final path = Path()
        ..moveTo(s.x1, s.y1)
        ..lineTo(midX, s.y1)
        ..lineTo(midX, s.y2)
        ..lineTo(s.x2, s.y2);

      // Estrutura do chaveamento: SEMPRE visível (mesmo sem nada decidido).
      canvas.drawPath(
        path,
        Paint()
          ..color = base.withOpacity(0.4)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );

      // Destaque do vencedor: aceso constante p/ feeders finalizados; ramp 0→1
      // só p/ os avanços em animação.
      if (s.live) {
        final r = s.animating ? t : 1.0;
        if (r > 0) {
          canvas.drawPath(
            path,
            Paint()
              ..color = live.withOpacity(r)
              ..strokeWidth = 2.0
              ..style = PaintingStyle.stroke,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.t != t || old.segments.length != segments.length;
}

class _BracketCard extends StatelessWidget {
  final KoMatch? match;
  // Times EFETIVOS exibidos (já resolvidos: reais ou herdados do vencedor do
  // confronto alimentador). Null → mostra o rótulo do slot ("Venc. Jogo X").
  final TeamModel? home;
  final TeamModel? away;
  // Fade-in (0→1) de um time herdado sendo "entregue" pela animação; null = sem.
  final double? homeDeliveryT;
  final double? awayDeliveryT;
  final String? label;
  final VoidCallback? onTap;
  final double loserOpacity;
  final (int, int)? bet; // palpite do usuário (home, away)
  final String? championTeamId; // realce dourado da seleção-campeã
  const _BracketCard({
    this.match,
    this.home,
    this.away,
    this.homeDeliveryT,
    this.awayDeliveryT,
    this.label,
    this.onTap,
    this.loserOpacity = 0.4,
    this.bet,
    this.championTeamId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = match;
    final advId = m?.advancing?.id;
    final finished = m?.isFinished ?? false;
    // A seleção-campeã do usuário aparece neste confronto? (borda dourada)
    final hasChampion = championTeamId != null &&
        (home?.id == championTeamId || away?.id == championTeamId);
    // Rótulo do topo: o explícito (ex.: "3º lugar") ou o nº oficial do jogo.
    final topLabel =
        label ?? (m?.matchNo != null ? 'Jogo ${m!.matchNo}' : null);

    // Tem placar real/ao vivo? (live ou finished com placar)
    final hasReal = m != null &&
        (m.status == MatchStatus.live || finished) &&
        m.homeScore != null &&
        m.awayScore != null;
    // Agendado → mostra o PALPITE no card; live/finished → mostra o REAL.
    final homeShown = hasReal ? m.homeScore : bet?.$1;
    final awayShown = hasReal ? m.awayScore : bet?.$2;
    final scoreIsBet = !hasReal && bet != null;
    // Selo abaixo só quando há placar real (aí o palpite vai pra baixo).
    final showPill = hasReal && bet != null;
    // Cor do selo = CATEGORIA do acerto vs placar REAL (live ou final): verde
    // (cravando o placar), amarelo (só o resultado), cinza (errando). O texto é
    // os PONTOS quando o jogo encerra (+5/+3/+1/+0) ou o palpite ainda ao vivo.
    int hitCat = 0;
    String pillText = '';
    if (hasReal && bet != null) {
      final b = bet!;
      hitCat = _hitCategory(b.$1, b.$2, m.homeScore!, m.awayScore!);
      pillText = finished
          ? '+${koBetPoints(m.round, b.$1, b.$2, m.homeScore!, m.awayScore!)}'
          : '${b.$1}-${b.$2}';
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasChampion ? kGold : cs.outline.withOpacity(0.5),
                width: hasChampion ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (topLabel != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(topLabel,
                        style: TextStyle(fontSize: 8, color: cs.onSurface.withOpacity(0.65))),
                  ),
                _teamRow(context, home, homeShown, advId, finished, scoreIsBet, m?.homeSlotLabel, homeDeliveryT),
                Divider(height: 4, color: cs.outline.withOpacity(0.15)),
                _teamRow(context, away, awayShown, advId, finished, scoreIsBet, m?.awaySlotLabel, awayDeliveryT),
              ],
            ),
          ),
          // Selo abaixo do card: cor opaca pela categoria; texto = +pts (encerrado)
          // ou palpite ao vivo.
          if (showPill)
            Positioned(
              bottom: -7,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _pillColors(hitCat).$1,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pillText,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: _pillColors(hitCat).$2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Categoria do palpite vs placar real: 2 = cravou o placar, 1 = só o
  // resultado, 0 = errou o resultado. Independe da fase (a cor é sobre acerto,
  // não sobre pontos — 3 pts numa final é "só resultado" = amarelo).
  int _hitCategory(int bh, int ba, int rh, int ra) {
    if (bh == rh && ba == ra) return 2;
    if (bh.compareTo(ba) == rh.compareTo(ra)) return 1;
    return 0;
  }

  // (fundo, texto) do selo por categoria: verde (cravada), amarelo (resultado),
  // cinza (erro). Tudo opaco. O amarelo segue o tom do badge de pontos do
  // ranking/perfil visitante (Colors.amber → ver bet_comparison_card.dart).
  (Color, Color) _pillColors(int cat) {
    switch (cat) {
      case 2:
        return (kPrimaryGreenLight, Colors.white);
      case 1:
        return (Colors.amber, Colors.black87);
      default:
        return (const Color(0xFF757575), Colors.white);
    }
  }

  Widget _teamRow(BuildContext context, TeamModel? team, int? score,
      String? advId, bool finished, bool scoreIsBet, String? fallbackLabel,
      [double? deliveryT]) {
    final cs = Theme.of(context).colorScheme;
    final show = team != null;
    final isAdv = show && advId != null && team.id == advId;
    final isChampion = show && championTeamId != null && team.id == championTeamId;
    // Entrega em curso → o time surge (fade-in) conforme a bandeira chega.
    final opacity = deliveryT ??
        ((finished && show && !isAdv) ? loserOpacity : 1.0);

    return Opacity(
      opacity: opacity,
      child: Row(
        children: [
          FlagAvatar(flagUrl: show ? team.flagUrl : null, radius: 8),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              show
                  ? team.name
                  : (fallbackLabel ?? AppLocalizations.of(context)!.koTbd),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    (isAdv || isChampion) ? FontWeight.w800 : FontWeight.w500,
                color: isChampion
                    ? kGold
                    : show
                        ? cs.onSurface
                        : cs.onSurface
                            .withOpacity(fallbackLabel != null ? 0.75 : 0.4),
              ),
            ),
          ),
          if (show && score != null)
            Text('$score',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: scoreIsBet
                        ? cs.primary
                        : (isAdv ? cs.primary : cs.onSurface.withOpacity(0.7)))),
        ],
      ),
    );
  }
}

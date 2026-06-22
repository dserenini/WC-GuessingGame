import 'package:flutter/material.dart';

import 'package:copa2026/shared/models/team.dart';
import 'package:copa2026/shared/models/match.dart' show MatchStatus;
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';

/// Árvore do chaveamento (16-avos → final) com linhas conectoras, navegável por
/// pan/zoom. Ao abrir (ou no botão ↻), toca a ANIMAÇÃO DE PROGRESSÃO: fase a
/// fase, o perdedor esmaece e a bandeira do vencedor percorre a linha até se
/// instalar no slot da fase seguinte.
class BracketTree extends StatefulWidget {
  final List<KoMatch> matches;
  final Map<String, (int, int)> myBets; // ko_match_id → (home, away)
  final void Function(KoMatch match)? onTap;
  const BracketTree(
      {super.key, required this.matches, this.myBets = const {}, this.onTap});

  @override
  State<BracketTree> createState() => _BracketTreeState();
}

class _BracketTreeState extends State<BracketTree>
    with SingleTickerProviderStateMixin {
  final _controller = TransformationController();
  bool _fitted = false;
  late final AnimationController _intro;
  Size? _viewport;

  static const _cols = ['16avos', 'oitavas', 'quartas', 'semis', 'final'];
  static const double _cardW = 150;
  static const double _cardH = 62; // +nº do jogo no topo → precisa de mais altura
  static const double _vGap = 14;
  static const double _colW = 190;
  static const double _unit = _cardH + _vGap;
  static const double _rowDy = 10; // distância do centro do card até cada linha
  static const double _flagInset = 16; // x do centro da bandeira dentro do card

  // Nº de transições a animar = ATÉ a fase atual (frontier). 0 = ainda nos
  // 16-avos (nada avançou) → sem animação. Calculado no build a partir dos dados.
  int _animPhases = 0;
  bool _kicked = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addListener(_followCamera);
  }

  /// Auto-pan: durante a animação, move a câmera pra focar na fase ativa
  /// (desliza da esquerda p/ direita acompanhando as bandeiras que avançam).
  void _followCamera() {
    final vp = _viewport;
    if (vp == null || vp.width <= 0) return;
    if (_intro.status == AnimationStatus.forward) {
      _controller.value = _cameraFor(_pf, vp);
    }
  }

  // Câmera SEMPRE com zoom, focada na fase atual:
  //  - Zoom vertical pela fase: 16as/8as mostram ~metade dos jogos (janela de
  //    8 linhas); a partir das quartas, mostra todos (altura cheia do bracket).
  //  - Horizontal: 16as estático centraliza; nas fases seguintes a coluna ativa
  //    (pf) encosta no extremo direito (a câmera desliza p/ a direita na anim).
  Matrix4 _cameraFor(double pf, Size vp) {
    const canvasH = 16 * _unit;
    final windowH = (_animPhases <= 1) ? 8 * _unit : canvasH;
    final k = (vp.height / windowH).clamp(0.4, 1.5);

    final double tx;
    if (_animPhases == 0) {
      tx = vp.width / 2 - k * (_cardW / 2); // centraliza os 16-avos
    } else {
      final rightCol = pf.clamp(0.0, _animPhases.toDouble());
      final rightCanvasX = rightCol * _colW + _cardW; // borda direita da coluna ativa
      tx = vp.width - 16 - k * rightCanvasX;
    }
    final ty = vp.height / 2 - k * (canvasH / 2);
    return Matrix4(k, 0, 0, 0, 0, k, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
  }

  @override
  void dispose() {
    _intro.dispose();
    _controller.dispose();
    super.dispose();
  }

  double get _pf => _intro.value * _animPhases; // progresso em "fases" (0.._animPhases)

  // Round c já preenchido? (0 = 16-avos sempre revelado)
  bool _revealed(int c) => c == 0 || _pf >= c - 0.02;

  // Opacidade do perdedor num card finalizado do round k (esmaece na fase k+1).
  double _loserOpacity(int k) => 1.0 - 0.6 * (_pf - k).clamp(0.0, 1.0);

  VoidCallback? _tapFor(KoMatch? m) =>
      (m == null || widget.onTap == null) ? null : () => widget.onTap!(m);

  (int, int)? _betFor(KoMatch? m) => m == null ? null : widget.myBets[m.id];

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

    // Fase atual (frontier): a rodada mais profunda (além dos 16-avos) que já
    // tem seleções definidas. 0 = ainda nos 16-avos → sem animação.
    int frontier = 0;
    for (var c = 1; c < _cols.length; c++) {
      if (widget.matches.any((m) => m.round == _cols[c] && m.home != null)) {
        frontier = c;
      }
    }
    _animPhases = frontier;
    if (!_kicked) {
      _kicked = true;
      if (frontier > 0) {
        _intro.duration = Duration(milliseconds: frontier * 1800);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _intro.forward();
        });
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
          final feeder = byKey['$prev:$f'];
          segments.add(_Seg(px, fCy, x, childCy, feeder?.isFinished ?? false, c));
        }
      }
    }

    return LayoutBuilder(builder: (context, box) {
      final vh = box.maxHeight.isFinite ? box.maxHeight : 600.0;
      _viewport = Size(box.maxWidth, vh);
      if (!_fitted && box.maxWidth.isFinite) {
        // Sempre abre com zoom focado na fase atual (não fit-to-width).
        _controller.value = _cameraFor(0, _viewport!);
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
              animation: _intro,
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
                          pf: _pf,
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
                              reveal: _revealed(c),
                              loserOpacity: _loserOpacity(c),
                              bet: _betFor(byKey['${_cols[c]}:$s']),
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
                          reveal: _animPhases > 0 ? _pf >= _animPhases - 0.5 : false,
                          loserOpacity: 0.4,
                          label: '3º lugar',
                          bet: _betFor(byKey['3lugar:1']),
                          onTap: _tapFor(byKey['3lugar:1']),
                        ),
                      ),
                    // Bandeiras viajando (vencedores indo pra próxima fase)
                    ..._travelers(cy, byKey),
                  ],
                ),
              ),
            ),
          ),
          // Replay (só quando há animação, i.e., já passamos dos 16-avos)
          if (_animPhases > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: cs.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _intro.forward(from: 0),
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

  /// Tokens (bandeiras) que percorrem o caminho durante a fase corrente.
  List<Widget> _travelers(Map<String, double> cy, Map<String, KoMatch> byKey) {
    final phase = _pf.floor() + 1; // 1.._animPhases
    if (phase > _animPhases) return const [];
    final localT = (_pf - (phase - 1)).clamp(0.0, 1.0);
    if (localT <= 0) return const [];

    final c = phase; // round de destino
    final prev = _cols[c - 1];
    final tokens = <Widget>[];

    for (var s = 1; s <= (16 >> c); s++) {
      final childCy = cy['${_cols[c]}:$s'];
      if (childCy == null) continue;
      for (final isHome in [true, false]) {
        final fSlot = isHome ? s * 2 - 1 : s * 2;
        final feeder = byKey['$prev:$fSlot'];
        final adv = feeder?.advancing;
        if (adv == null) continue;
        final fCy = cy['$prev:$fSlot']!;
        final advIsHome = adv.id == feeder!.home?.id;

        final start = Offset(
          (c - 1) * _colW + _cardW,
          fCy + (advIsHome ? -_rowDy : _rowDy),
        );
        final end = Offset(
          c * _colW + _flagInset,
          childCy + (isHome ? -_rowDy : _rowDy),
        );
        final p = _along(start, end, localT);
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
    }
    return tokens;
  }
}

class _Seg {
  final double x1, y1, x2, y2;
  final bool live;
  final int col;
  _Seg(this.x1, this.y1, this.x2, this.y2, this.live, this.col);
}

class _ConnectorPainter extends CustomPainter {
  final List<_Seg> segments;
  final Color base;
  final Color live;
  final double pf; // progresso em fases
  _ConnectorPainter({
    required this.segments,
    required this.base,
    required this.live,
    required this.pf,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in segments) {
      final r = (pf - (s.col - 1)).clamp(0.0, 1.0); // acende durante a fase col
      if (r <= 0) continue;
      final p = Paint()
        ..color = (s.live ? live : base).withOpacity((s.live ? 1.0 : 0.35) * r)
        ..strokeWidth = s.live ? 2.0 : 1.2
        ..style = PaintingStyle.stroke;
      final midX = s.x1 + (s.x2 - s.x1) / 2;
      final path = Path()
        ..moveTo(s.x1, s.y1)
        ..lineTo(midX, s.y1)
        ..lineTo(midX, s.y2)
        ..lineTo(s.x2, s.y2);
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.pf != pf || old.segments.length != segments.length;
}

class _BracketCard extends StatelessWidget {
  final KoMatch? match;
  final String? label;
  final VoidCallback? onTap;
  final bool reveal; // mostra as seleções? (false = "A definir")
  final double loserOpacity;
  final (int, int)? bet; // palpite do usuário (home, away)
  const _BracketCard({
    this.match,
    this.label,
    this.onTap,
    this.reveal = true,
    this.loserOpacity = 0.4,
    this.bet,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = match;
    final advId = m?.advancing?.id;
    final finished = m?.isFinished ?? false;
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

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outline.withOpacity(0.25)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (topLabel != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(topLabel,
                        style: TextStyle(fontSize: 8, color: cs.onSurface.withOpacity(0.5))),
                  ),
                _teamRow(context, m?.home, homeShown, advId, finished, scoreIsBet, m?.homeSlotLabel),
                Divider(height: 4, color: cs.outline.withOpacity(0.15)),
                _teamRow(context, m?.away, awayShown, advId, finished, scoreIsBet, m?.awaySlotLabel),
              ],
            ),
          ),
          // Palpite do usuário abaixo do card (só quando há placar real).
          if (showPill)
            Positioned(
              bottom: -7,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${bet!.$1}-${bet!.$2}',
                      style: const TextStyle(
                          fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _teamRow(BuildContext context, TeamModel? team, int? score,
      String? advId, bool finished, bool scoreIsBet, String? fallbackLabel) {
    final cs = Theme.of(context).colorScheme;
    final show = reveal && team != null;
    final isAdv = show && advId != null && team.id == advId;
    final opacity = (finished && show && !isAdv) ? loserOpacity : 1.0;

    return Opacity(
      opacity: opacity,
      child: Row(
        children: [
          FlagAvatar(flagUrl: show ? team.flagUrl : null, radius: 8),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              show ? team.name : (fallbackLabel ?? 'A definir'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isAdv ? FontWeight.w800 : FontWeight.w500,
                color: show ? cs.onSurface : cs.onSurface.withOpacity(0.4),
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

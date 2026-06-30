import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/ranking/providers/ranking_provider.dart';
import 'package:copa2026/shared/models/bet.dart';

/// Aba "Seleção do Bolão": escalação lúdica montada com o ranking (geral) da fase
/// de grupos. Os 11 primeiros viram os titulares — mapeados a posições do campo —
/// e o ÚLTIMO colocado vira o Técnico. Formação 4-3-2-1:
///   1º → Centroavante · 2º/3º → Pontas · 4º → Meia · 5º/6º → Volantes ·
///   7º–10º → Defesa/Laterais · 11º → Goleiro · último → Técnico.
class LineupTab extends ConsumerWidget {
  const LineupTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final rankingAsync = ref.watch(rankingProvider);
    final currentUid = ref.watch(currentUserProvider)?.id;

    return rankingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (entries) {
        // Só entram na seleção quem realmente jogou: no mínimo 10 pontos. Isso
        // evita que o "técnico" (último colocado) seja alguém sem participação
        // (0 pontos). Ordena por rank e, em caso de empate, por user_id — assim
        // quem fica em campo vs. no banco é ESTÁVEL entre carregamentos (o RANK()
        // da view não desempata além dos critérios, e o Postgres pode variar a
        // ordem dos empatados).
        final eligible = entries.where((e) => e.totalPoints >= 10).toList()
          ..sort((a, b) {
            final r = a.rank.compareTo(b.rank);
            return r != 0 ? r : a.userId.compareTo(b.userId);
          });

        // Precisa de pelo menos 12 elegíveis (11 titulares + 1 técnico).
        if (eligible.length < 12) {
          final cs = Theme.of(context).colorScheme;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l.resultsLineupEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurface.withOpacity(0.55)),
              ),
            ),
          );
        }

        final starters = eligible.take(11).toList(); // índices 0..10 = 1º..11º
        final coach = eligible.last;

        // Empate na FRONTEIRA da escalação: quem dividiu a 11ª colocação com o
        // titular do gol (mesmo rank), mas ficou de fora do corte, não é
        // descartado — vai para o banco de reservas (mesmo badge da colocação).
        final cutRank = eligible[10].rank;
        final reserves = eligible
            .skip(11)
            .where((e) => e.rank == cutRank && e.userId != coach.userId)
            .toList();

        // Mapa por posição no ranking (1-based) para montar as linhas.
        RankingEntry at(int rankPos) => starters[rankPos - 1];

        return LayoutBuilder(
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(l.lineupTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                _Field(
                  rows: [
                    // De cima (ataque) para baixo (gol).
                    [_P(at(1), l.posStriker)],
                    [_P(at(2), l.posWinger), _P(at(3), l.posWinger)],
                    [_P(at(4), l.posPlaymaker)],
                    [_P(at(5), l.posDefensiveMid), _P(at(6), l.posDefensiveMid)],
                    [
                      _P(at(7), l.posDefense),
                      _P(at(8), l.posDefense),
                      _P(at(9), l.posDefense),
                      _P(at(10), l.posDefense),
                    ],
                    [_P(at(11), l.posGoalkeeper)],
                  ],
                  currentUid: currentUid,
                  l: l,
                ),
                const SizedBox(height: 16),
                _Bench(
                  reserves: reserves,
                  coach: coach,
                  currentUid: currentUid,
                  l: l,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Par (jogador, rótulo de posição) para montar um token no campo.
class _P {
  final RankingEntry entry;
  final String position;
  const _P(this.entry, this.position);
}

class _Field extends StatelessWidget {
  final List<List<_P>> rows;
  final String? currentUid;
  final AppLocalizations l;

  const _Field({required this.rows, required this.currentUid, required this.l});

  // Altura fixa por linha (acomoda o balão de raio 35 + nome) → evita overflow
  // tanto na linha de 4 zagueiros quanto em telas largas; largura é limitada.
  static const double _rowHeight = 110;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          width: double.infinity,
          height: rows.length * _rowHeight + 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            ),
          ),
          child: CustomPaint(
            painter: _PitchPainter(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Column(
                children: [
                  for (final row in rows)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final p in row)
                            _PlayerToken(
                              p: p,
                              isMe: p.entry.userId == currentUid,
                              l: l,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerToken extends StatelessWidget {
  final _P p;
  final bool isMe;
  final AppLocalizations l;

  const _PlayerToken({required this.p, required this.isMe, required this.l});

  @override
  Widget build(BuildContext context) {
    final e = p.entry;

    // Borda por colocação: pódio (1º/2º/3º) ganha ouro/prata/bronze; demais,
    // branco. O "você" não muda a cor da borda (pode ser pódio também) — é
    // marcado por um brilho/glow extra em volta do balão.
    final ringColor = switch (e.rank) {
      1 => kGold,
      2 => kSilver,
      3 => kBronze,
      _ => Colors.white,
    };
    final isPodium = e.rank <= 3;
    final ringWidth = isPodium ? 3.5 : 2.5;

    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // scaleDown: mantém o raio 35 onde couber e encolhe só em telas muito
          // estreitas (linha de 4 zagueiros) para não estourar o layout.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: ringWidth),
                    boxShadow: [
                      // Pódio brilha na cor da medalha; "você" ganha glow extra.
                      if (isPodium)
                        BoxShadow(
                          color: ringColor.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      if (isMe)
                        const BoxShadow(
                          color: Colors.white,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white.withOpacity(0.92),
                    backgroundImage:
                        e.avatarUrl != null ? NetworkImage(e.avatarUrl!) : null,
                    child: e.avatarUrl == null
                        ? Text(
                            e.displayName.isNotEmpty
                                ? e.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: kPrimaryGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                            ),
                          )
                        : null,
                  ),
                ),
                // Badge da colocação no ranking (pódio herda a cor da medalha).
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isPodium ? ringColor : kPrimaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '${e.rank}',
                      style: TextStyle(
                        color: e.rank == 1 ? Colors.black87 : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            e.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Colors.black87, blurRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banco: o Técnico (último colocado) e, quando houver empate na fronteira da
/// 11ª colocação, o(s) reserva(s) que dividiram a posição com o titular do gol.
class _Bench extends StatelessWidget {
  final List<RankingEntry> reserves;
  final RankingEntry coach;
  final String? currentUid;
  final AppLocalizations l;

  const _Bench({
    required this.reserves,
    required this.coach,
    required this.currentUid,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Reservas (empate na 11ª) primeiro, técnico por último. Cada um divide
    // igualmente a largura do banco (Expanded) e fica centralizado no seu espaço.
    final tokens = <Widget>[
      for (final r in reserves)
        _BenchToken(
          entry: r,
          isMe: r.userId == currentUid,
          isCoach: false,
          l: l,
        ),
      _BenchToken(
        entry: coach,
        isMe: coach.userId == currentUid,
        isCoach: true,
        l: l,
      ),
    ];

    // Mesma largura/limite do campo (ver _Field) para alinhar os dois blocos.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_seat, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(l.bench,
                      style:
                          tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final t in tokens) Expanded(child: t),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenchToken extends StatelessWidget {
  final RankingEntry entry;
  final bool isMe;
  final bool isCoach;
  final AppLocalizations l;

  const _BenchToken({
    required this.entry,
    required this.isMe,
    required this.isCoach,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMe ? kGold : cs.outline.withOpacity(0.4),
                    width: isMe ? 3 : 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primary.withOpacity(0.12),
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
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
              ),
              // Técnico: badge com 👔. Reserva: badge com a colocação.
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                  child: isCoach
                      ? const Text('👔', style: TextStyle(fontSize: 13))
                      : Text(
                          '${entry.rank}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            entry.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            isCoach ? l.coach : l.reserveGoalkeeper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: tt.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            isCoach ? l.lastPlace : l.tied,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Linhas brancas do gramado: borda, meio-campo, círculo central e as duas
/// grandes áreas. Puramente decorativo.
class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      const Radius.circular(12),
    );
    canvas.drawRRect(r, paint);

    // Meio-campo + círculo central.
    final midY = size.height / 2;
    canvas.drawLine(Offset(4, midY), Offset(size.width - 4, midY), paint);
    canvas.drawCircle(Offset(size.width / 2, midY), size.width * 0.13, paint);

    // Grandes áreas (topo e base).
    final boxW = size.width * 0.5;
    final boxH = size.height * 0.14;
    final left = (size.width - boxW) / 2;
    canvas.drawRect(Rect.fromLTWH(left, 4, boxW, boxH), paint);
    canvas.drawRect(
        Rect.fromLTWH(left, size.height - 4 - boxH, boxW, boxH), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

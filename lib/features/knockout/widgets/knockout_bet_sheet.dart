import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/shared/models/team.dart';
import 'package:copa2026/shared/models/match.dart' show MatchStatus;
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';

/// Popup de detalhes de um confronto do mata-mata:
/// status + placar real/ao vivo, seu palpite (editável até 30 min antes) e pontos.
class KnockoutMatchSheet extends ConsumerStatefulWidget {
  final KoMatch match;
  final int initialHome;
  final int initialAway;
  final bool hasBet;

  const KnockoutMatchSheet({
    super.key,
    required this.match,
    required this.initialHome,
    required this.initialAway,
    required this.hasBet,
  });

  @override
  ConsumerState<KnockoutMatchSheet> createState() => _KnockoutMatchSheetState();
}

class _KnockoutMatchSheetState extends ConsumerState<KnockoutMatchSheet> {
  late int _home = widget.initialHome;
  late int _away = widget.initialAway;
  bool _saving = false;

  KoMatch get m => widget.match;

  /// Data/hora do jogo no fuso escolhido pelo usuário (match_date é UTC).
  DateTime? get _localDate =>
      m.matchDate?.toUtc().add(ref.read(timezoneProvider));

  /// Apostas abertas: times definidos, ainda agendado e faltando >30 min pro jogo.
  bool get _open =>
      m.teamsKnown &&
      m.status == MatchStatus.scheduled &&
      m.matchDate != null &&
      DateTime.now()
          .toUtc()
          .isBefore(m.matchDate!.toUtc().subtract(const Duration(minutes: 30)));

  /// Motivo de a edição estar bloqueada (null quando aberta ou já encerrada com
  /// palpite registrado num jogo passado — aí o read-only fala por si).
  String? _lockReason(AppLocalizations l) {
    if (_open) return null;
    if (!m.teamsKnown) return l.koLockTeamsUndefined;
    if (m.status != MatchStatus.scheduled) return l.koLockStarted;
    return l.koLockClosed30min;
  }

  int? get _points {
    if (!m.isFinished || !widget.hasBet || m.homeScore == null || m.awayScore == null) {
      return null;
    }
    return koBetPoints(m.round, _home, _away, m.homeScore!, m.awayScore!);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(knockoutActionsProvider)
          .saveBet(koMatchId: m.id, home: _home, away: _away);
      if (mounted) Navigator.pop(context); // salva silencioso (igual aos grupos)
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.koSaveError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    ref.watch(timezoneProvider); // reconstrói se o fuso mudar
    final d = _localDate;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: cs.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2)),
              ),
              // Cabeçalho: #ID · Status · (data) — igual à fase de grupos
              Row(
                children: [
                  Text(m.gameNoLabel,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
                  const SizedBox(width: 8),
                  _statusChip(context, l),
                  const Spacer(),
                  if (d != null)
                    Text(
                      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Fase
              Align(
                alignment: Alignment.centerLeft,
                child: Text(koRoundLabel(l, m.round),
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: cs.primary)),
              ),
              const SizedBox(height: 12),

              // Confronto + placar real/ao vivo (ou horário)
              Row(
                children: [
                  Expanded(child: _teamHeader(m.home, m.homeSlotLabel)),
                  _resultCenter(cs),
                  Expanded(child: _teamHeader(m.away, m.awaySlotLabel)),
                ],
              ),

              const Divider(height: 28),

              // Seu palpite
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l.koYourBet,
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withOpacity(0.7))),
              ),
              const SizedBox(height: 8),
              if (_open)
                _editor(cs, l)
              else ...[
                _readonlyBet(cs),
                if (_lockReason(l) != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 13, color: cs.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(_lockReason(l)!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: cs.onSurface.withOpacity(0.6))),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Centro: resultado/ao vivo, ou horário se ainda não começou.
  Widget _resultCenter(ColorScheme cs) {
    if (m.status == MatchStatus.scheduled) {
      final d = _localDate;
      final txt = d == null
          ? '—'
          : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}\n${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(txt,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.6))),
      );
    }
    final live = m.status == MatchStatus.live;
    final pens = (m.homePens != null && m.awayPens != null)
        ? ' (${m.homePens}-${m.awayPens} pen)'
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(4)),
              child: Text(AppLocalizations.of(context)!.koLiveBadge,
                  style: const TextStyle(
                      fontSize: 8, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          Text('${m.homeScore ?? '-'} - ${m.awayScore ?? '-'}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          if (pens.isNotEmpty)
            Text(pens.trim(),
                style: TextStyle(fontSize: 9, color: cs.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (m.status) {
      MatchStatus.scheduled => (l.statusScheduled, cs.outline),
      MatchStatus.live => (l.statusLive, Colors.red),
      MatchStatus.finished => (l.statusFinished, cs.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _teamHeader(TeamModel? team, String? fallbackLabel) {
    return Column(
      children: [
        FlagAvatar(flagUrl: team?.flagUrl, radius: 18),
        const SizedBox(height: 4),
        Text(team?.name ?? fallbackLabel ?? AppLocalizations.of(context)!.koTbd,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _editor(ColorScheme cs, AppLocalizations l) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepper(_home, (v) => setState(() => _home = v)),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10), child: Text('–')),
            _stepper(_away, (v) => setState(() => _away = v)),
          ],
        ),
        // Semifinal/Final valem mais: avisa o usuário no editor.
        if (koIsFinalsRound(m.round)) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 13, color: cs.primary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(l.koFinalsScoringNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: cs.primary)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.hasBet ? l.koUpdateBet : l.koConfirmBet),
          ),
        ),
      ],
    );
  }

  Widget _readonlyBet(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    final pts = _points;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.hasBet ? '$_home  –  $_away' : l.koNoBet,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: widget.hasBet ? cs.onSurface : cs.onSurface.withOpacity(0.5)),
        ),
        if (pts != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: (pts > 0 ? cs.primary : cs.outline).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6)),
            child: Text(l.koPlusPoints(pts),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: pts > 0 ? cs.primary : cs.onSurface.withOpacity(0.6))),
          ),
        ],
      ],
    );
  }

  Widget _stepper(int value, ValueChanged<int> onChanged) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(value + 1),
          icon: Icon(Icons.keyboard_arrow_up, color: cs.primary),
        ),
        Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged((value - 1).clamp(0, 99)),
          icon: Icon(Icons.keyboard_arrow_down, color: cs.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }
}

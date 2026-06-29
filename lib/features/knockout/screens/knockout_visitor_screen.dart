import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/shared/models/match.dart' show MatchStatus;
import 'package:copa2026/shared/models/bet.dart' show RankingEntry;
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';
import 'package:copa2026/l10n/team_translator.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';

/// Perfil visitante do MATA-MATA: palpites de KO de outro usuário, revelando só
/// jogos finalizados/ao vivo/fechados (30 min antes). A RLS `ko_bet_read`
/// garante que jogos ainda abertos nem vêm do servidor (anti-cópia).
class KnockoutVisitorScreen extends ConsumerWidget {
  final String userId;
  final RankingEntry? entry;
  const KnockoutVisitorScreen({super.key, required this.userId, this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final currentUid = ref.watch(currentUserProvider)?.id;
    final isSelf = userId == currentUid;
    final name = entry?.displayName ?? '';

    final matchesAsync = ref.watch(koMatchesProvider);
    final bBetsAsync = ref.watch(koUserBetsProvider(userId));
    final myBetsAsync = ref.watch(koMyBetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(name.isEmpty ? l.koMenu : name,
                  overflow: TextOverflow.ellipsis),
            ),
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
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Builder(builder: (context) {
        final matches = matchesAsync.valueOrNull;
        final bBets = bBetsAsync.valueOrNull;
        final myBets = myBetsAsync.valueOrNull;
        if (matches == null || bBets == null || myBets == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final sorted = [...matches]
          ..sort((a, b) =>
              (a.matchDate ?? DateTime(0)).compareTo(b.matchDate ?? DateTime(0)));
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(koMatchesProvider);
            ref.invalidate(koUserBetsProvider(userId));
            ref.invalidate(koMyBetsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              for (final m in sorted)
                _KoCompareCard(
                  match: m,
                  revealed: isSelf || koMatchRevealed(m),
                  bBet: bBets[m.id],
                  myBet: isSelf ? null : myBets[m.id],
                  isSelf: isSelf,
                  l: l,
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _KoCompareCard extends ConsumerWidget {
  final KoMatch match;
  final bool revealed;
  final (int, int)? bBet;
  final (int, int)? myBet;
  final bool isSelf;
  final AppLocalizations l;

  const _KoCompareCard({
    required this.match,
    required this.revealed,
    required this.bBet,
    required this.myBet,
    required this.isSelf,
    required this.l,
  });

  String _fmtTime(DateTime d, Duration offset) {
    final t = d.toUtc().add(offset);
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final offset = ref.watch(timezoneProvider);

    final hasRealScore = (match.status == MatchStatus.live ||
            match.status == MatchStatus.finished) &&
        match.homeScore != null &&
        match.awayScore != null;

    int? bPoints;
    if (revealed && bBet != null && hasRealScore) {
      bPoints = koBetPoints(
          match.round, bBet!.$1, bBet!.$2, match.homeScore!, match.awayScore!);
    }

    final homeName = match.homeText;
    final awayName = match.awayText;

    final header = Row(
      children: [
        Text(koRoundLabel(l, match.round).toUpperCase(),
            style: tt.labelSmall
                ?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (!revealed && match.matchDate != null)
          Text(_fmtTime(match.matchDate!, offset),
              style: tt.labelSmall
                  ?.copyWith(color: cs.onSurface.withOpacity(0.5))),
        if (hasRealScore)
          Text('${match.homeScore} - ${match.awayScore}',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );

    final teams = Row(
      children: [
        Expanded(
          child: Column(children: [
            FlagAvatar(flagUrl: match.home?.flagUrl, radius: 20),
            const SizedBox(height: 6),
            Text(translateTeam(context, homeName),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: revealed && bBet != null
              ? Text('${bBet!.$1} - ${bBet!.$2}',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800))
              : Icon(revealed ? Icons.remove : Icons.lock_outline,
                  color: cs.onSurface.withOpacity(0.35)),
        ),
        Expanded(
          child: Column(children: [
            FlagAvatar(flagUrl: match.away?.flagUrl, radius: 20),
            const SizedBox(height: 6),
            Text(translateTeam(context, awayName),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    );

    final footer = <Widget>[];
    if (revealed && bPoints != null) {
      footer.add(_PointsBadge(points: bPoints));
    }
    if (revealed && !isSelf && myBet != null) {
      footer.add(Text('${l.statsYou}: ${myBet!.$1} - ${myBet!.$2}',
          style: tt.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.6))));
    }

    final card = Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          children: [
            header,
            const SizedBox(height: 12),
            teams,
            if (footer.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: cs.outline.withOpacity(0.15)),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: footer,
              ),
            ],
          ],
        ),
      ),
    );

    return revealed ? card : Opacity(opacity: 0.55, child: card);
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = points >= 3
        ? (cs.primary.withOpacity(0.15), cs.primary)
        : points >= 1
            ? (Colors.amber.withOpacity(0.18), Colors.amber.shade800)
            : (cs.onSurface.withOpacity(0.08), cs.onSurface.withOpacity(0.55));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(points > 0 ? '+$points' : '0',
          style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/profile/providers/stat_rankings_provider.dart';
import 'package:copa2026/features/profile/screens/visitor_profile_screen.dart';
import 'package:copa2026/shared/models/bet.dart';

/// Card de um ranking estatístico (família A): cabeçalho + pódio (carro-chefe)
/// ou top-3 compacto, com a linha "Você" sempre visível e botão "ver todos".
class StatRankingCard extends ConsumerWidget {
  final StatRanking stat;
  final String icon;
  final String title;
  final String subtitle;
  final String unit;
  final bool podium;

  const StatRankingCard({
    super.key,
    required this.stat,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.unit,
    this.podium = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final currentUid = ref.watch(currentUserProvider)?.id;
    final async = ref.watch(statRankingProvider(stat));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.55),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l.statsError, style: TextStyle(color: cs.error)),
            ),
            data: (entries) =>
                _buildBody(context, entries, currentUid, l),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<RankingEntry> entries,
    String? currentUid,
    AppLocalizations l,
  ) {
    final cs = Theme.of(context).colorScheme;

    // No early tournament everyone is at zero; show a friendly empty state.
    if (entries.isEmpty || entries.first.totalPoints == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l.statsEmpty,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.5),
              ),
        ),
      );
    }

    final top3 = entries.take(3).toList();
    final me = _findMe(entries, currentUid);
    final meInTop3 = me != null && top3.any((e) => e.userId == me.userId);

    return Column(
      children: [
        if (podium)
          _Podium(
            top3: top3,
            unit: unit,
            currentUid: currentUid,
            stat: stat,
            label: title,
          )
        else
          ...top3.map((e) => _StatRankRow(
                entry: e,
                isMe: e.userId == currentUid,
                unit: unit,
                l: l,
                stat: stat,
                label: title,
              )),
        if (me != null && !meInTop3) ...[
          const SizedBox(height: 6),
          _StatRankRow(
            entry: me,
            isMe: true,
            unit: unit,
            l: l,
            stat: stat,
            label: title,
          ),
        ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StatRankingDetailScreen(
                  stat: stat,
                  icon: icon,
                  title: title,
                  unit: unit,
                ),
              ),
            ),
            child: Text(l.statsSeeAll),
          ),
        ),
      ],
    );
  }
}

RankingEntry? _findMe(List<RankingEntry> entries, String? uid) {
  if (uid == null) return null;
  for (final e in entries) {
    if (e.userId == uid) return e;
  }
  return null;
}

void _openUser(
    BuildContext context, RankingEntry entry, StatRanking stat, String label) {
  // Same gate as the global ranking: only after betting is locked, never for self.
  if (!isBettingLocked) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => VisitorProfileScreen(
        userId: entry.userId,
        entry: entry,
        statFilter: stat,
        contextLabel: label,
      ),
    ),
  );
}

Color _rankColor(int rank, ColorScheme cs) => switch (rank) {
      1 => kGold,
      2 => kSilver,
      3 => kBronze,
      _ => cs.onSurface.withOpacity(0.4),
    };

String _rankBadge(int rank) => switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank',
    };

CircleAvatar _avatar(RankingEntry e, ColorScheme cs, {double radius = 18}) =>
    CircleAvatar(
      radius: radius,
      backgroundColor: cs.primary.withOpacity(0.15),
      backgroundImage: e.avatarUrl != null ? NetworkImage(e.avatarUrl!) : null,
      child: e.avatarUrl == null
          ? Text(
              e.displayName.isNotEmpty ? e.displayName[0].toUpperCase() : '?',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
            )
          : null,
    );

/// Linha compacta de ranking estatístico (rank + avatar + nome + valor/unidade).
class _StatRankRow extends StatelessWidget {
  final RankingEntry entry;
  final bool isMe;
  final String unit;
  final AppLocalizations l;
  final StatRanking stat;
  final String label;

  const _StatRankRow({
    required this.entry,
    required this.isMe,
    required this.unit,
    required this.l,
    required this.stat,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rankColor = _rankColor(entry.rank, cs);
    final tappable = isBettingLocked && !isMe;

    final row = Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isMe ? cs.primary.withOpacity(0.1) : Colors.transparent,
        border: Border.all(
          color: isMe ? cs.primary.withOpacity(0.3) : Colors.transparent,
          width: isMe ? 1.5 : 0,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              _rankBadge(entry.rank),
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: rankColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _avatar(entry, cs, radius: 15),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMe ? l.statsYou : entry.displayName,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                color: isMe ? cs.primary : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.totalPoints}',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: entry.rank <= 3 ? rankColor : cs.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: tt.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.45)),
          ),
          if (tappable)
            Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withOpacity(0.3)),
        ],
      ),
    );

    if (!tappable) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openUser(context, entry, stat, label),
      child: row,
    );
  }
}

/// Pódio top-3 (ordem visual: 2º · 1º · 3º) para o card carro-chefe.
class _Podium extends StatelessWidget {
  final List<RankingEntry> top3;
  final String unit;
  final String? currentUid;
  final StatRanking stat;
  final String label;

  const _Podium({
    required this.top3,
    required this.unit,
    this.currentUid,
    required this.stat,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Show the first up-to-3 entries by list order (1st = center/maior, com
    // coroa; 2nd = esquerda; 3rd = direita). Usar posição na lista — e não o
    // número do rank — garante 3 espaços mesmo com empates (dense rank).
    Widget spot(int index, double avatarRadius) {
      if (index >= top3.length) return const Expanded(child: SizedBox());
      final e = top3[index];
      return Expanded(
        child: _PodiumSpot(
          entry: e,
          unit: unit,
          avatarRadius: avatarRadius,
          isMe: e.userId == currentUid,
          showCrown: index == 0,
          stat: stat,
          label: label,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [spot(1, 22), spot(0, 28), spot(2, 22)],
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  final RankingEntry entry;
  final String unit;
  final double avatarRadius;
  final bool isMe;
  final bool showCrown;
  final StatRanking stat;
  final String label;

  const _PodiumSpot({
    required this.entry,
    required this.unit,
    required this.avatarRadius,
    required this.isMe,
    this.showCrown = false,
    required this.stat,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rankColor = _rankColor(entry.rank, cs);
    final tappable = isBettingLocked && !isMe;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCrown)
          const Text('👑', style: TextStyle(fontSize: 16))
        else
          const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: rankColor, width: 2),
          ),
          child: _avatar(entry, cs, radius: avatarRadius),
        ),
        const SizedBox(height: 4),
        Text(
          isMe ? AppLocalizations.of(context)!.statsYou : entry.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: tt.labelSmall?.copyWith(
            fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
            color: isMe ? cs.primary : cs.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          '${entry.totalPoints}',
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: rankColor,
          ),
        ),
        Text(
          unit,
          style: tt.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.45)),
        ),
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: content,
    );

    if (!tappable) return padded;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openUser(context, entry, stat, label),
      child: padded,
    );
  }
}

/// Lista completa de um ranking estatístico ("ver todos").
class StatRankingDetailScreen extends ConsumerWidget {
  final StatRanking stat;
  final String icon;
  final String title;
  final String unit;

  const StatRankingDetailScreen({
    super.key,
    required this.stat,
    required this.icon,
    required this.title,
    required this.unit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final currentUid = ref.watch(currentUserProvider)?.id;
    final async = ref.watch(statRankingProvider(stat));

    return Scaffold(
      appBar: AppBar(title: Text('$icon $title')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l.statsError, style: TextStyle(color: cs.error)),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(child: Text(l.statsEmpty));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              return _StatRankRow(
                entry: e,
                isMe: e.userId == currentUid,
                unit: unit,
                l: l,
                stat: stat,
                label: title,
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/ranking/providers/ranking_provider.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final rankingAsync = ref.watch(rankingProvider);
    final currentUid = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: Text('ðŸ† ${l.ranking}')),
      drawer: const AppDrawer(),
      body: rankingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (entries) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: entries.length,
          itemBuilder: (_, i) {
            final entry = entries[i];
            final isMe = entry.userId == currentUid;
            return RankingTile(entry: entry, isMe: isMe);
          },
        ),
      ),
    );
  }
}

class RankingTile extends StatelessWidget {
  final RankingEntry entry;
  final bool isMe;

  const RankingTile({super.key, required this.entry, required this.isMe});

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isMe
            ? cs.primary.withOpacity(0.08)
            : cs.surfaceContainerHighest.withOpacity(0.5),
        border: Border.all(
          color: isMe ? cs.primary.withOpacity(0.3) : Colors.transparent,
          width: isMe ? 1.5 : 0,
        ),
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
                      entry.username.isNotEmpty
                          ? entry.username[0].toUpperCase()
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
                    entry.username,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${entry.totalBets} apostas',
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
          ],
        ),
      ),
    );
  }
}

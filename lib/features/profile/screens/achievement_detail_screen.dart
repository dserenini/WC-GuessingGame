import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/profile/providers/achievements_provider.dart';
import 'package:copa2026/features/profile/screens/my_matches_detail_screen.dart';

/// Full view of a single achievement: emblem, description, progress / unlock
/// date, rarity, and the matches that earned it.
class AchievementDetailScreen extends StatelessWidget {
  final AchievementState state;
  final String name;
  final String emoji;
  final String description;
  final DateTime? unlockedAt;
  final int? pct;
  final String? tierLabel;

  const AchievementDetailScreen({
    super.key,
    required this.state,
    required this.name,
    required this.emoji,
    required this.description,
    this.unlockedAt,
    this.pct,
    this.tierLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final on = state.unlocked;
    final title = tierLabel == null ? name : '$name · $tierLabel';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? kGold.withOpacity(0.18) : cs.onSurface.withOpacity(0.06),
                    border: Border.all(
                        color: on ? kGold : cs.onSurface.withOpacity(0.15), width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: on ? 1 : 0.45,
                    child: Text(emoji, style: const TextStyle(fontSize: 44)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(title,
                    textAlign: TextAlign.center,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(description,
                    textAlign: TextAlign.center,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.65))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Status
          if (on) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: kGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, size: 16, color: kGold),
                    const SizedBox(width: 6),
                    Text(
                      unlockedAt != null
                          ? '${l.achUnlockedOn} ${_fmt(unlockedAt!)}'
                          : l.achUnlocked,
                      style: tt.labelLarge
                          ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.progress,
                minHeight: 12,
                backgroundColor: cs.primary.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('${state.current} / ${state.target}',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],

          const SizedBox(height: 16),
          if (pct != null)
            Center(
              child: Text('$pct% ${l.achRarityOf}',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6))),
            ),

          if (state.evidence.isNotEmpty) ...[
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MyMatchesDetailScreen(
                  title: name,
                  matchIds: state.evidence.toSet(),
                ),
              )),
              icon: const Icon(Icons.sports_soccer, size: 18),
              label: Text(l.achViewGames),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')}/${l.year}';
  }
}

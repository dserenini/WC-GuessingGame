import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/profile/providers/achievements_provider.dart';
import 'package:copa2026/features/profile/screens/achievement_detail_screen.dart';
import 'package:copa2026/features/profile/screens/advanced_stats_screen.dart';

/// (emoji, name, description) for an achievement key.
({String emoji, String name, String desc}) achMeta(String key, AppLocalizations l) {
  switch (key) {
    case 'exatos_bronze':
    case 'exatos_prata':
    case 'exatos_ouro':
      return (emoji: '🎯', name: l.achExactTitle, desc: l.achExactDesc);
    case 'empate':
      return (emoji: '🤝', name: l.achEmpateName, desc: l.achEmpateDesc);
    case 'ousadia':
      return (emoji: '🎲', name: l.achOusadiaName, desc: l.achOusadiaDesc);
    case 'embalado_bronze':
    case 'embalado_prata':
    case 'embalado_ouro':
      return (emoji: '🔥', name: l.achEmbaladoName, desc: l.achEmbaladoDesc);
    case 'diacheio':
      return (emoji: '📅', name: l.achDiaCheioName, desc: l.achDiaCheioDesc);
    case 'voltamundo':
      return (emoji: '🌍', name: l.achVoltaName, desc: l.achVoltaDesc);
    case 'donogrupo':
      return (emoji: '👑', name: l.achDonoName, desc: l.achDonoDesc);
    case 'brasil':
      return (emoji: '🇧🇷', name: l.achBrasilName, desc: l.achBrasilDesc);
    case 'profeta':
      return (emoji: '🧙', name: l.achProfetaName, desc: l.achProfetaDesc);
    case 'panela':
      return (emoji: '🏟️', name: l.achPanelaName, desc: l.achPanelaDesc);
    case 'meioseculo':
      return (emoji: '🏅', name: l.achMeioSeculoName, desc: l.achMeioSeculoDesc);
    case 'quasela':
      return (emoji: '😤', name: l.achQuaseName, desc: l.achQuaseDesc);
    default:
      return (emoji: '🏆', name: key, desc: '');
  }
}

int? rarityPct(String key, ({Map<String, int> counts, int total})? rarity) {
  if (rarity == null || rarity.total == 0) return null;
  return ((rarity.counts[key] ?? 0) / rarity.total * 100).round();
}

/// "Conquistas" (family E) tab — collectible badge album.
class AchievementsTab extends ConsumerWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final states = ref.watch(achievementStatesProvider);
    final unlocked =
        ref.watch(achievementSyncProvider).valueOrNull?.unlocked ?? const {};
    final rarity = ref.watch(achievementRarityProvider).valueOrNull;

    if (states == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final byKey = {for (final s in states) s.key: s};
    final exactTiers = [for (final k in kExactTierKeys) byKey[k]!];
    final streakTiers = [for (final k in kStreakTierKeys) byKey[k]!];
    final singles = states.where((s) => !kAchievementTierKeys.contains(s.key)).toList();
    final done = states.where((s) => s.unlocked).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('$done/${states.length}',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
            const SizedBox(width: 6),
            Text(l.statsTabAchievements.toLowerCase(),
                style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6))),
          ],
        ),
        const SizedBox(height: 14),
        _TierCard(
            title: l.achExactTitle,
            emoji: '🎯',
            desc: l.achExactDesc,
            tiers: exactTiers,
            unlocked: unlocked,
            rarity: rarity,
            l: l),
        const SizedBox(height: 12),
        _TierCard(
            title: l.achEmbaladoName,
            emoji: '🔥',
            desc: l.achEmbaladoDesc,
            tiers: streakTiers,
            unlocked: unlocked,
            rarity: rarity,
            l: l),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.12,
          children: [
            for (final s in singles)
              _BadgeCell(
                state: s,
                unlockedAt: unlocked[s.key],
                pct: rarityPct(s.key, rarity),
                l: l,
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Tiered "exact scores" — bronze / prata / ouro side by side
// ─────────────────────────────────────────────
class _TierCard extends StatelessWidget {
  final String title;
  final String emoji;
  final String desc;
  final List<AchievementState> tiers; // [bronze, prata, ouro]
  final Map<String, DateTime> unlocked;
  final ({Map<String, int> counts, int total})? rarity;
  final AppLocalizations l;
  const _TierCard(
      {required this.title,
      required this.emoji,
      required this.desc,
      required this.tiers,
      required this.unlocked,
      required this.rarity,
      required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final labels = [l.achBronze, l.achPrata, l.achOuro];
    final colors = [kBronze, kSilver, kGold];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(desc,
                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.55))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < tiers.length; i++)
                Expanded(
                  child: _TierMedal(
                    state: tiers[i],
                    label: labels[i],
                    color: colors[i],
                    pct: rarityPct(tiers[i].key, rarity),
                    onTap: () => _openDetail(context, tiers[i], unlocked[tiers[i].key],
                        rarityPct(tiers[i].key, rarity), l,
                        tierLabel: labels[i]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierMedal extends StatelessWidget {
  final AchievementState state;
  final String label;
  final Color color;
  final int? pct;
  final VoidCallback onTap;
  const _TierMedal(
      {required this.state,
      required this.label,
      required this.color,
      required this.pct,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final on = state.unlocked;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? color.withOpacity(0.18) : cs.onSurface.withOpacity(0.06),
                border: Border.all(
                    color: on ? color : cs.onSurface.withOpacity(0.15), width: 2),
              ),
              alignment: Alignment.center,
              child: Text('${state.target}',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: on ? color : cs.onSurface.withOpacity(0.4),
                  )),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: on ? cs.onSurface : cs.onSurface.withOpacity(0.5))),
            Text(on && pct != null ? '$pct%' : '${state.current}/${state.target}',
                style: tt.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.45))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Single badge cell
// ─────────────────────────────────────────────
class _BadgeCell extends StatelessWidget {
  final AchievementState state;
  final DateTime? unlockedAt;
  final int? pct;
  final AppLocalizations l;
  const _BadgeCell(
      {required this.state, required this.unlockedAt, required this.pct, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final meta = achMeta(state.key, l);
    final on = state.unlocked;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openDetail(context, state, unlockedAt, pct, l),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: on ? kGold.withOpacity(0.6) : cs.outline.withOpacity(0.15),
              width: on ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? kGold.withOpacity(0.18) : cs.onSurface.withOpacity(0.06),
                border: Border.all(
                    color: on ? kGold : cs.onSurface.withOpacity(0.12), width: 2),
              ),
              alignment: Alignment.center,
              child: Opacity(
                opacity: on ? 1 : 0.45,
                child: Text(meta.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 8),
            Text(meta.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: on ? cs.onSurface : cs.onSurface.withOpacity(0.65))),
            const SizedBox(height: 8),
            if (on)
              Text(pct != null ? '$pct% ${l.achRarityOf}' : '✓',
                  style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600))
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: state.progress,
                        minHeight: 6,
                        backgroundColor: cs.primary.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary.withOpacity(0.5)),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text('${state.current}/${state.target}',
                        style: tt.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _openDetail(BuildContext context, AchievementState state, DateTime? unlockedAt,
    int? pct, AppLocalizations l,
    {String? tierLabel}) {
  final m = achMeta(state.key, l);
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => AchievementDetailScreen(
      state: state,
      name: m.name,
      emoji: m.emoji,
      description: m.desc,
      unlockedAt: unlockedAt,
      pct: pct,
      tierLabel: tierLabel,
    ),
  ));
}

// ─────────────────────────────────────────────
// Celebration dialog when new achievements unlock (shown on the home screen)
// ─────────────────────────────────────────────
void showAchievementCelebration(
    BuildContext context, List<String> keys, AppLocalizations l) {
  showDialog(
    context: context,
    builder: (dialogCtx) => _CelebrationDialog(
      keys: keys,
      l: l,
      onClose: () => Navigator.of(dialogCtx).pop(),
      onView: () {
        Navigator.of(dialogCtx).pop();
        // Deep-link to the Conquistas tab (last tab).
        context.push('/stats', extra: kAchievementsTabIndex);
      },
    ),
  );
}

class _CelebrationDialog extends StatelessWidget {
  final List<String> keys;
  final AppLocalizations l;
  final VoidCallback onClose;
  final VoidCallback onView;
  const _CelebrationDialog(
      {required this.keys, required this.l, required this.onClose, required this.onView});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return AlertDialog(
      scrollable: true,
      title: Text('🎉 ${l.achNewUnlocked}', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final k in keys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kGold.withOpacity(0.18),
                      border: Border.all(color: kGold, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(achMeta(k, l).emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(achMeta(k, l).name,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: onClose, child: Text(l.achClose)),
        FilledButton(onPressed: onView, child: Text(l.achViewAchievement)),
      ],
    );
  }
}

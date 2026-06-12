import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/features/profile/providers/stat_rankings_provider.dart';
import 'package:copa2026/features/profile/widgets/stat_ranking_card.dart';

/// Tela dedicada de "Estatísticas Avançadas" com abas. Esta v1 entrega apenas
/// a aba Rankings (família A); as demais ficam como placeholder para já
/// estabelecer a estrutura de navegação.
class AdvancedStatsScreen extends StatelessWidget {
  const AdvancedStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('📊 ${l.advancedStats}'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l.statsTabRankings),
              Tab(text: l.statsTabPersonal),
              Tab(text: l.statsTabAchievements),
              Tab(text: l.statsTabPool),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _RankingsTab(),
            _ComingSoonTab(label: l.statsTabPersonal),
            _ComingSoonTab(label: l.statsTabAchievements),
            _ComingSoonTab(label: l.statsTabPool),
          ],
        ),
      ),
    );
  }
}

class _RankingsTab extends StatelessWidget {
  const _RankingsTab();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StatRankingCard(
          stat: StatRanking.exactScore,
          icon: '👑',
          title: l.statExactTitle,
          subtitle: l.statExactSub,
          unit: l.statExactUnit,
          podium: true,
        ),
        StatRankingCard(
          stat: StatRanking.brazilPoints,
          icon: '🇧🇷',
          title: l.statBrazilTitle,
          subtitle: l.statBrazilSub,
          unit: l.statPointsUnit,
        ),
        StatRankingCard(
          stat: StatRanking.nearMiss,
          icon: '🎯',
          title: l.statNearMissTitle,
          subtitle: l.statNearMissSub,
          unit: l.statNearMissUnit,
        ),
        StatRankingCard(
          stat: StatRanking.dailyTop,
          icon: '🔥',
          title: l.statDailyTitle,
          subtitle: l.statDailySub,
          unit: l.statPointsUnit,
        ),
        StatRankingCard(
          stat: StatRanking.regularity,
          icon: '📈',
          title: l.statRegularTitle,
          subtitle: l.statRegularSub,
          unit: l.statRegularUnit,
        ),
        StatRankingCard(
          stat: StatRanking.boldness,
          icon: '🎲',
          title: l.statBoldTitle,
          subtitle: l.statBoldSub,
          unit: l.statBoldUnit,
        ),
        StatRankingCard(
          stat: StatRanking.contrarian,
          icon: '🗳️',
          title: l.statContrarianTitle,
          subtitle: l.statContrarianSub,
          unit: l.statContrarianUnit,
        ),
      ],
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  final String label;
  const _ComingSoonTab({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🚧', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l.statsComingSoon,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.55),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

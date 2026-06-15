import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/features/profile/providers/stat_rankings_provider.dart';
import 'package:copa2026/features/profile/widgets/stat_ranking_card.dart';
import 'package:copa2026/features/profile/widgets/personal_stats_cards.dart';
import 'package:copa2026/features/profile/widgets/pool_stats_cards.dart';
import 'package:copa2026/features/profile/widgets/achievements_cards.dart';

/// Tela dedicada de "Estatísticas Avançadas" com abas. Famílias A (Rankings),
/// B (Pessoal), E (Conquistas) e F (Bolão) entregues.
/// Index of the "Conquistas" tab (last), used when deep-linking from the
/// achievement celebration dialog.
const int kAchievementsTabIndex = 3;

class AdvancedStatsScreen extends StatelessWidget {
  final int initialTab;
  const AdvancedStatsScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 4,
      initialIndex: initialTab.clamp(0, 3),
      child: Scaffold(
        appBar: AppBar(
          title: Text('📊 ${l.advancedStats}'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l.statsTabRankings),
              Tab(text: l.statsTabPersonal),
              Tab(text: l.statsTabPool),
              Tab(text: l.statsTabAchievements),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RankingsTab(),
            PersonalStatsTab(),
            PoolStatsTab(),
            AchievementsTab(),
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


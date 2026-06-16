import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/features/profile/providers/stat_rankings_provider.dart';
import 'package:copa2026/features/profile/widgets/stat_ranking_card.dart';
import 'package:copa2026/features/profile/widgets/personal_stats_cards.dart';
import 'package:copa2026/features/profile/widgets/pool_stats_cards.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';

/// Tela dedicada de "Estatísticas Avançadas" com abas. Famílias A (Rankings),
/// B (Pessoal) e F (Bolão). As Conquistas têm página própria (/achievements).
class AdvancedStatsScreen extends StatelessWidget {
  final int initialTab;
  const AdvancedStatsScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text('📊 ${l.advancedStats}'),
          leadingWidth: 100,
          leading: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const NotificationBell(),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l.statsTabRankings),
              Tab(text: l.statsTabPersonal),
              Tab(text: l.statsTabPool),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RankingsTab(),
            PersonalStatsTab(),
            PoolStatsTab(),
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


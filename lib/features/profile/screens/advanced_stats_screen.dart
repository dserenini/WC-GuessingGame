import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/features/profile/providers/stat_rankings_provider.dart';
import 'package:copa2026/features/profile/widgets/stat_ranking_card.dart';
import 'package:copa2026/features/profile/widgets/personal_stats_cards.dart';

/// Tela dedicada de "Estatísticas Avançadas" com abas. Famílias A (Rankings) e
/// B (Pessoal) entregues. As abas "Conquistas" e "Bolão" ficam ocultas até
/// serem implementadas — basta voltar a length: 4 e reincluir as Tabs/children
/// (rótulos l.statsTabAchievements / l.statsTabPool já existem no i18n).
class AdvancedStatsScreen extends StatelessWidget {
  const AdvancedStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('📊 ${l.advancedStats}'),
          bottom: TabBar(
            tabs: [
              Tab(text: l.statsTabRankings),
              Tab(text: l.statsTabPersonal),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RankingsTab(),
            PersonalStatsTab(),
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


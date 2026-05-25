import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final offset = ref.watch(timezoneProvider);
    final dt = DateTime.utc(2026, 6, 11, 2, 59).add(offset);
    final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final gmtStr = 'GMT${offset.inHours >= 0 ? '+' : ''}${offset.inHours}';

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.helpAndRules),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildRuleCard(
            context,
            icon: Icons.scoreboard,
            title: l10n.helpScoring,
            description: l10n.helpScoringDesc,
            color: Colors.green,
          ),
          _buildRuleCard(
            context,
            icon: Icons.timer,
            title: l10n.helpDeadlines,
            description: l10n.helpDeadlinesDesc(dateStr, gmtStr),
            color: Colors.redAccent,
          ),
          _buildRuleCard(
            context,
            icon: Icons.star,
            title: l10n.helpSuperPalpites,
            description: l10n.helpSuperPalpitesDesc,
            color: Colors.amber,
          ),
          _buildRuleCard(
            context,
            icon: Icons.casino,
            title: l10n.helpAgentOfChaosTitle,
            description: l10n.helpAgentOfChaosDesc,
            color: Colors.purpleAccent,
          ),
          _buildRuleCard(
            context,
            icon: Icons.bolt,
            title: l10n.helpEasyBetTitle,
            description: l10n.helpEasyBetDesc,
            color: Colors.deepOrangeAccent,
          ),
          _buildRuleCard(
            context,
            icon: Icons.group,
            title: l10n.helpLeaguesTitle,
            description: l10n.helpLeaguesDesc,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              l10n.appTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRuleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final offset = ref.watch(timezoneProvider);
    final dt = DateTime.utc(2026, 6, 11, 17, 30).add(offset);
    final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final gmtStr = 'GMT${offset.inHours >= 0 ? '+' : ''}${offset.inHours}';
    // Regras do mata-mata só para quem tem acesso (inscrição confirmada).
    final koVisible = ref.watch(knockoutVisibleProvider).valueOrNull ?? false;

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
            icon: Icons.emoji_events,
            title: l10n.prizesTitle,
            description: l10n.prizesCardDesc,
            color: Colors.amber.shade700,
            onTap: () => context.push('/prizes'),
          ),
          _buildRuleCard(
            context,
            icon: Icons.scoreboard,
            title: l10n.helpScoring,
            description: l10n.helpScoringDesc,
            color: Colors.green,
          ),
          _buildRuleCard(
            context,
            icon: Icons.balance,
            title: l10n.helpTiebreakTitle,
            description: l10n.helpTiebreakDesc,
            color: Colors.teal,
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
          // ── Regras do Mata-Mata (só para inscritos) ──
          if (koVisible) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
              child: Text(
                '⚔️ ${l10n.helpKoSection}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            _buildRuleCard(
              context,
              icon: Icons.scoreboard,
              title: l10n.helpKoScoringTitle,
              description: l10n.helpKoScoringDesc,
              color: Colors.green,
            ),
            _buildRuleCard(
              context,
              icon: Icons.emoji_events,
              title: l10n.helpKoChampionTitle,
              description: l10n.helpKoChampionDesc,
              color: Colors.amber.shade700,
            ),
            _buildRuleCard(
              context,
              icon: Icons.timer,
              title: l10n.helpKoDeadlineTitle,
              description: l10n.helpKoDeadlineDesc,
              color: Colors.redAccent,
            ),
            _buildRuleCard(
              context,
              icon: Icons.leaderboard,
              title: l10n.helpKoRankingTitle,
              description: l10n.helpKoRankingDesc,
              color: Colors.indigo,
            ),
          ],
          const SizedBox(height: 16),
          _buildPaymentCard(context, l10n),
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
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final content = Padding(
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
          // Card navegável (ex.: Premiação) ganha uma seta de "abre detalhes".
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ],
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }

  Widget _buildPaymentCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pix Section
            Text(
              l10n.paymentPixTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.paymentPixAmount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.paymentPixKey,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: 'pix@example.com'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.copiedToClipboard)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.paymentPixScan,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 200,
                child: Image.asset('assets/images/pix_qr.png', fit: BoxFit.contain),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(),
            ),
            // IBAN Section
            Text(
              l10n.paymentIbanTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.paymentIbanAmount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.paymentIbanKey,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: 'IT93W0364601600526228392905'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.copiedToClipboard)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/profile/providers/profile_stats_provider.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(profileStatsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('👤 ${l.myProfile}'),
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
      ),
      drawer: const AppDrawer(),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e.toString(),
              style: TextStyle(color: cs.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Avatar & Username Header ──────────────
              _ProfileHeader(stats: stats),
              const SizedBox(height: 24),

              // ── Progress Card ─────────────────────────
              _BetProgressCard(stats: stats, l: l),
              const SizedBox(height: 16),

              // ── Points Card ───────────────────────────
              _PointsCard(stats: stats, l: l),
              const SizedBox(height: 24),

              // ── Super Palpite Card ─────────────────────────
              _SuperPalpiteCard(stats: stats, l: l),
              const SizedBox(height: 24),

              // ── Future stats placeholder ──────────────
              _ComingSoonCard(l: l),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROFILE HEADER
// ─────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final ProfileStats stats;
  const _ProfileHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Avatar circle
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryGreen, kPrimaryGreenLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kPrimaryGreen.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              stats.username.isNotEmpty
                  ? stats.username[0].toUpperCase()
                  : '⚽',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          stats.username,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// BET PROGRESS CARD
// ─────────────────────────────────────────────
class _BetProgressCard extends StatelessWidget {
  final ProfileStats stats;
  final AppLocalizations l;
  const _BetProgressCard({required this.stats, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = stats.totalMatches > 0 ? stats.totalMatches : 72;
    final progress = total > 0 ? stats.totalBets / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('📋', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l.betsFilled,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  '${stats.totalBets}/$total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: cs.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// POINTS CARD
// ─────────────────────────────────────────────
class _PointsCard extends StatelessWidget {
  final ProfileStats stats;
  final AppLocalizations l;
  const _PointsCard({required this.stats, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final betsWithResults = stats.exactHits + stats.resultHits +
        (stats.totalBets - stats.exactHits - stats.resultHits);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l.totalPoints,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryGreen, kPrimaryGreenLight],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stats.totalPoints}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: '🎯',
                    label: l.exactHits,
                    value: '${stats.exactHits}',
                    subtitle: '× 3pts',
                    color: kGold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: '✅',
                    label: l.resultHits,
                    value: '${stats.resultHits}',
                    subtitle: '× 1pt',
                    color: cs.primary,
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

// ─────────────────────────────────────────────
// STAT TILE (reusable mini card)
// ─────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.4),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// COMING SOON CARD
// ─────────────────────────────────────────────
class _ComingSoonCard extends StatelessWidget {
  final AppLocalizations l;
  const _ComingSoonCard({required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          const Text('📊', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estatísticas Avançadas',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Por grupo, rodada, seleção — em breve!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                ),
              ],
            ),
          ),
          Icon(Icons.upcoming_outlined,
              color: cs.onSurface.withOpacity(0.3)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SUPER PALPITE CARD
// ─────────────────────────────────────────────
class _SuperPalpiteCard extends StatelessWidget {
  final ProfileStats stats;
  final AppLocalizations l;
  const _SuperPalpiteCard({required this.stats, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final int remaining = kMaxSuperPalpites - stats.superPalpitesUsed;
    final progress = remaining / kMaxSuperPalpites;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🌟', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Super Palpites',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  '$remaining/$kMaxSuperPalpites',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: cs.outline.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Você tem $remaining alterações após o prazo limite.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

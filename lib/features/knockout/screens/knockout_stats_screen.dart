import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/models/team.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';
import 'package:copa2026/features/knockout/providers/champion_pick_provider.dart';
import 'package:copa2026/features/knockout/providers/knockout_pool_provider.dart';

/// Estatísticas Avançadas do Mata-Mata (página própria, 3 abas):
///   • Rankings KO  — pontos, cravadas e distribuição do palpite de campeão.
///   • Pessoal KO   — seus acertos, aproveitamento e palpite de campeão.
///   • Bolão KO     — agregados: placares populares e previsibilidade dos jogos.
class KnockoutStatsScreen extends StatelessWidget {
  const KnockoutStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text('📊 ${l.koStatsTitle}'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l.koStatsTabRankings),
              Tab(text: l.koStatsTabPersonal),
              Tab(text: l.koStatsTabPool),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_KoRankingsTab(), _KoPersonalTab(), _KoPoolTab()],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABA RANKINGS KO
// ─────────────────────────────────────────────────────────────────────────────
class _KoRankingsTab extends StatelessWidget {
  const _KoRankingsTab();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _KoRankingCard(
          icon: '🏆',
          title: l.koStatPointsTitle,
          subtitle: l.koStatPointsSub,
          unit: l.koStatPointsUnit,
          provider: koUserRankingProvider,
        ),
        _KoRankingCard(
          icon: '👑',
          title: l.koStatExactTitle,
          subtitle: l.koStatExactSub,
          unit: l.koStatExactUnit,
          provider: koExactRankingProvider,
        ),
        const _ChampionDistributionCard(),
      ],
    );
  }
}

/// Card de ranking do mata-mata (top 5 + linha "Você"). Recebe um provider que
/// devolve `List<RankingEntry>` (ko_user_rankings / ko_exact_score_rankings).
class _KoRankingCard extends ConsumerWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String unit;
  final AutoDisposeFutureProvider<List<RankingEntry>> provider;

  const _KoRankingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.unit,
    required this.provider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final uid = ref.watch(currentUserProvider)?.id;
    final async = ref.watch(provider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurface.withOpacity(0.55))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l.statsError, style: TextStyle(color: cs.error)),
            ),
            data: (entries) {
              if (entries.isEmpty || entries.first.totalPoints == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l.statsEmpty,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurface.withOpacity(0.5))),
                );
              }
              final top = entries.take(5).toList();
              final me = _findMe(entries, uid);
              final meInTop = me != null && top.any((e) => e.userId == me.userId);
              return Column(
                children: [
                  ...top.map((e) =>
                      _koRankRow(context, e, e.userId == uid, unit, l)),
                  if (me != null && !meInTop) ...[
                    const Divider(height: 14),
                    _koRankRow(context, me, true, unit, l),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

RankingEntry? _findMe(List<RankingEntry> entries, String? uid) {
  if (uid == null) return null;
  for (final e in entries) {
    if (e.userId == uid) return e;
  }
  return null;
}

Color _rankColor(int rank, ColorScheme cs) => switch (rank) {
      1 => kGold,
      2 => kSilver,
      3 => kBronze,
      _ => cs.onSurface.withOpacity(0.4),
    };

String _rankBadge(int rank) => switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank',
    };

Widget _koRankRow(BuildContext context, RankingEntry e, bool isMe, String unit,
    AppLocalizations l) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  final rankColor = _rankColor(e.rank, cs);
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 3),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: isMe ? cs.primary.withOpacity(0.1) : Colors.transparent,
      border: Border.all(
        color: isMe ? cs.primary.withOpacity(0.3) : Colors.transparent,
        width: isMe ? 1.5 : 0,
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(_rankBadge(e.rank),
              textAlign: TextAlign.center,
              style: tt.bodyMedium
                  ?.copyWith(color: rankColor, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 15,
          backgroundColor: cs.primary.withOpacity(0.15),
          backgroundImage: e.avatarUrl != null ? NetworkImage(e.avatarUrl!) : null,
          child: e.avatarUrl == null
              ? Text(e.displayName.isNotEmpty ? e.displayName[0].toUpperCase() : '?',
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700))
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(isMe ? l.statsYou : e.displayName,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                color: isMe ? cs.primary : null,
              )),
        ),
        const SizedBox(width: 8),
        Text('${e.totalPoints}',
            style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: e.rank <= 3 ? rankColor : cs.onSurface)),
        const SizedBox(width: 4),
        Text(unit,
            style: tt.labelSmall?.copyWith(color: cs.onSurface.withOpacity(0.45))),
      ],
    ),
  );
}

/// Distribuição do palpite de campeão (quantos escolheram cada seleção).
/// Aparece depois que o mata-mata começa (RLS esconde os palpites dos outros).
class _ChampionDistributionCard extends ConsumerWidget {
  const _ChampionDistributionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(koChampionDistributionProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('🏅', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.koChampionDistTitle,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(l.koChampionDistSub,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurface.withOpacity(0.55))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l.statsError, style: TextStyle(color: cs.error)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l.koChampionDistEmpty,
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurface.withOpacity(0.5))),
                );
              }
              final total = list.fold<int>(0, (a, b) => a + b.count);
              return Column(
                children: [
                  for (final c in list.take(10))
                    _distRow(context, c, total),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _distRow(BuildContext context, ChampionCount c, int total) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final pct = total == 0 ? 0.0 : c.count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          FlagAvatar(flagUrl: c.team.flagUrl, radius: 13),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(c.team.name,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Text('${c.count}',
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: cs.outline.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABA PESSOAL KO (cálculo no cliente)
// ─────────────────────────────────────────────────────────────────────────────
class _KoPersonalTab extends ConsumerWidget {
  const _KoPersonalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final matchesAsync = ref.watch(koMatchesProvider);
    final bets = ref.watch(koMyBetsProvider).valueOrNull ?? const {};
    final pick = ref.watch(koChampionPickProvider).valueOrNull;
    final teams = ref.watch(koAllTeamsProvider).valueOrNull ?? const <TeamModel>[];

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l.statsError, style: TextStyle(color: cs.error)),
        ),
      ),
      data: (matches) {
        var betPoints = 0, exacts = 0, dirs = 0, zeros = 0, played = 0, maxPoss = 0;
        KoMatch? finalMatch;
        for (final m in matches) {
          if (m.round == 'final') finalMatch = m;
          if (!m.isFinished || m.homeScore == null || m.awayScore == null) continue;
          final bet = bets[m.id];
          if (bet == null) continue;
          played++;
          final p = koBetPoints(m.round, bet.$1, bet.$2, m.homeScore!, m.awayScore!);
          betPoints += p;
          maxPoss += koIsFinalsRound(m.round) ? 5 : 3;
          if (bet.$1 == m.homeScore && bet.$2 == m.awayScore) {
            exacts++;
          } else if (p > 0) {
            dirs++;
          } else {
            zeros++;
          }
        }
        final bonus = pick?.points ?? 0;
        final pct = maxPoss > 0 ? (betPoints / maxPoss * 100).round() : 0;

        // Status do palpite de campeão.
        final championResolved = finalMatch != null &&
            finalMatch.isFinished &&
            finalMatch.advancing != null;
        TeamModel? champTeam;
        if (pick != null) {
          for (final t in teams) {
            if (t.id == pick.teamId) {
              champTeam = t;
              break;
            }
          }
        }
        final String champStatus = pick == null
            ? l.koChampionStatusNone
            : !championResolved
                ? l.koChampionStatusPending
                : (pick.points > 0
                    ? l.koChampionStatusHit
                    : l.koChampionStatusMiss);

        if (played == 0 && pick == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.koPersonalEmpty,
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium
                      ?.copyWith(color: cs.onSurface.withOpacity(0.6))),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Headline: pontos totais (placar + bônus de campeão).
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text('${betPoints + bonus}',
                      style: tt.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800, color: cs.primary)),
                  Text(l.koPersonalTotalPoints,
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurface.withOpacity(0.7))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Grade de métricas.
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _StatTile(label: l.koPersonalExacts, value: '$exacts'),
                _StatTile(label: l.koPersonalDirs, value: '$dirs'),
                _StatTile(label: l.koPersonalZeros, value: '$zeros'),
                _StatTile(label: l.koPersonalAccuracy, value: '$pct%'),
                _StatTile(label: l.koPersonalPlayed, value: '$played'),
                _StatTile(label: l.koPersonalChampionBonus, value: '$bonus'),
              ],
            ),
            const SizedBox(height: 16),
            // Palpite de campeão + status.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.koChampionTitle,
                            style:
                                tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        if (champTeam != null)
                          Row(
                            children: [
                              FlagAvatar(flagUrl: champTeam.flagUrl, radius: 11),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(champTeam.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Text(champStatus,
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurface.withOpacity(0.65))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurface.withOpacity(0.7))),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: tt.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABA BOLÃO KO (agregados do mata-mata)
// ─────────────────────────────────────────────────────────────────────────────
class _KoPoolTab extends ConsumerWidget {
  const _KoPoolTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final popAsync = ref.watch(koScorePopularityProvider);
    final predAsync = ref.watch(koMatchPredictabilityProvider);
    final matches = ref.watch(koMatchesProvider).valueOrNull ?? const <KoMatch>[];
    final byId = {for (final m in matches) m.id: m};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _poolCard(
          context,
          icon: '📊',
          title: l.koPoolPopularTitle,
          subtitle: l.koPoolPopularSub,
          child: popAsync.when(
            loading: () => _loading(),
            error: (e, _) => _error(context, l),
            data: (list) {
              if (list.isEmpty) return _empty(context, l.koPoolEmpty);
              final maxN = list.first.n;
              return Column(
                children: [for (final s in list.take(6)) _popRow(context, s, maxN)],
              );
            },
          ),
        ),
        predAsync.when(
          loading: () => _poolCard(context,
              icon: '🎲',
              title: l.koPoolUnpredictableTitle,
              subtitle: l.koPoolUnpredictableSub,
              child: _loading()),
          error: (e, _) => _poolCard(context,
              icon: '🎲',
              title: l.koPoolUnpredictableTitle,
              subtitle: l.koPoolUnpredictableSub,
              child: _error(context, l)),
          data: (preds) {
            if (preds.isEmpty) {
              return _poolCard(context,
                  icon: '🎲',
                  title: l.koPoolUnpredictableTitle,
                  subtitle: l.koPoolUnpredictableSub,
                  child: _empty(context, l.koPoolEmpty));
            }
            final unpredictable = [...preds]
              ..sort((a, b) => a.exactCount.compareTo(b.exactCount));
            final everyoneKnew = [...preds]
              ..sort((a, b) => b.exactCount.compareTo(a.exactCount));
            return Column(
              children: [
                _poolCard(
                  context,
                  icon: '🎲',
                  title: l.koPoolUnpredictableTitle,
                  subtitle: l.koPoolUnpredictableSub,
                  child: Column(
                    children: [
                      for (final p in unpredictable.take(5))
                        _predRow(context, l, p, byId[p.matchId]),
                    ],
                  ),
                ),
                _poolCard(
                  context,
                  icon: '🧠',
                  title: l.koPoolEveryoneKnewTitle,
                  subtitle: l.koPoolEveryoneKnewSub,
                  child: Column(
                    children: [
                      for (final p in everyoneKnew.take(5))
                        _predRow(context, l, p, byId[p.matchId]),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _loading() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()));

  Widget _error(BuildContext context, AppLocalizations l) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(l.statsError,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );

  Widget _empty(BuildContext context, String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(msg,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      );

  Widget _poolCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurface.withOpacity(0.55))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _popRow(BuildContext context, KoScorePop s, int maxN) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final pct = maxN == 0 ? 0.0 : s.n / maxN;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(s.label,
                style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: cs.primary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: cs.outline.withOpacity(0.15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${s.n}',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _predRow(BuildContext context, AppLocalizations l,
      KoMatchPredictability p, KoMatch? m) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = m == null ? '—' : '${m.homeText}  ×  ${m.awayText}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(l.koPoolExactOf(p.exactCount, p.totalBets),
              style: tt.bodySmall?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

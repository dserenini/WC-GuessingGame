import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/profile/providers/profile_stats_provider.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';
import 'package:copa2026/shared/providers/locale_provider.dart';
import 'package:copa2026/shared/utils/bet_points.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';
import 'package:copa2026/features/profile/screens/profile_completion_screen.dart';
import 'package:copa2026/l10n/team_translator.dart';

// Usuários cujo idioma já foi gravado na conta nesta sessão (evita backfill
// repetido a cada rebuild da tela).
final Set<String> _localeBackfilled = <String>{};

const List<String> _supportedLocales = ['pt', 'en', 'it'];

/// Mantém o idioma do app alinhado com a conta:
///  - conta tem idioma salvo e diferente do atual -> aplica (usuário voltando
///    em outro aparelho/navegador);
///  - conta ainda sem idioma (usuário antigo) -> grava o idioma local atual na
///    conta (backfill silencioso, uma vez por sessão), vinculando a escolha.
void _syncAccountLocale(WidgetRef ref, ProfileStats stats) {
  final current = ref.read(localeProvider).languageCode;
  final saved = stats.locale?.trim() ?? '';

  if (saved.isNotEmpty) {
    if (_supportedLocales.contains(saved) && saved != current) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(localeProvider.notifier).setLocale(saved);
      });
    }
    return;
  }

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null || _localeBackfilled.contains(user.id)) return;
  _localeBackfilled.add(user.id);
  final lang = _supportedLocales.contains(current) ? current : 'pt';
  _backfillAccountLocale(user.id, lang);
}

Future<void> _backfillAccountLocale(String userId, String lang) async {
  // Fire-and-forget: se a RLS bloquear, apenas não persiste (não trava a UI).
  try {
    await Supabase.instance.client
        .from('profiles')
        .update({'locale': lang})
        .eq('id', userId);
  } catch (_) {}
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // "Jogos do dia" mostra a SUA aposta (allBetsProvider) e o placar/status
    // (allMatchesProvider via matchesOfDayProvider). Ambos são providers globais
    // de vida longa: após uma pontuação ao vivo no servidor não se atualizam
    // sozinhos, então o seu ponto podia ficar velho até um refresh forte. Ao
    // abrir o perfil, forçamos os dois a buscar do servidor. (Mesma correção do
    // perfil visitante.)
    ref.invalidate(allBetsProvider);
    ref.invalidate(allMatchesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(profileStatsProvider);
    final cs = Theme.of(context).colorScheme;

    return statsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              e.toString(),
              style: TextStyle(color: cs.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (stats) {
        // Onboarding pendente enquanto NOME ou TELEFONE faltarem na conta.
        // Fonte única de verdade (banco), então é pedido só uma vez — mesmo em
        // outro aparelho/navegador. O idioma é coletado junto (tela única) mas
        // não bloqueia aqui (ver backfill abaixo para usuários antigos).
        final needsOnboarding = (stats.fullName == null || stats.fullName!.trim().isEmpty) ||
            (stats.phone == null || stats.phone!.trim().isEmpty);
        if (needsOnboarding) {
          return const ProfileCompletionScreen();
        }

        _syncAccountLocale(ref, stats);

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
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileStatsProvider);
              ref.invalidate(allBetsProvider);
              ref.invalidate(allMatchesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Avatar & Username Header ──────────────
                _ProfileHeader(stats: stats),
                const SizedBox(height: 24),

                // ── Matches of the Day ────────────────────
                // (substitui o card "Apostas Preenchidas" agora que a fase de
                //  apostas terminou; _BetProgressCard fica preservado abaixo
                //  para reuso futuro.)
                const _TodayMatchesSection(),

                // ── Points Card ───────────────────────────
                _PointsCard(stats: stats, l: l),
                const SizedBox(height: 24),

                // ── Super Palpite Card ─────────────────────────
                _SuperPalpiteCard(stats: stats, l: l),
                const SizedBox(height: 24),

                // ── Advanced stats entry ──────────────────
                _AdvancedStatsEntryCard(l: l),
              ],
            ),
          ),
        );
      },
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
              (stats.fullName?.isNotEmpty == true ? stats.fullName! : stats.username).isNotEmpty
                  ? (stats.fullName?.isNotEmpty == true ? stats.fullName! : stats.username)[0].toUpperCase()
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stats.fullName?.isNotEmpty == true ? stats.fullName! : stats.username,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: stats.paid ? AppLocalizations.of(context)!.paymentRealized : AppLocalizations.of(context)!.paymentPending,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: stats.paid ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.attach_money, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// MATCHES OF THE DAY
// ─────────────────────────────────────────────
class _TodayMatchesSection extends ConsumerWidget {
  const _TodayMatchesSection();

  String _formatDay(DateTime d, Duration offset) {
    final t = d.toUtc().add(offset);
    return '${t.day.toString().padLeft(2, '0')}/'
        '${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesOfDayProvider);
    if (matches.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bets = ref.watch(allBetsProvider).valueOrNull ?? {};
    final offset = ref.watch(timezoneProvider);
    final dateLabel = matches.first.matchDate != null
        ? _formatDay(matches.first.matchDate!, offset)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header alinhado com o conteúdo dos cards (que têm margin 16 do tema).
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              const Text('⚽', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                l.matchesOfDay,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (dateLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dateLabel,
                    style: tt.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Coluna única de cards full-width (mesma largura de Pontos/Super).
        ...matches.map((m) => _MatchOfDayCard(
              match: m,
              bet: bets[m.id],
              offset: offset,
            )),
        const SizedBox(height: 8),
      ],
    );
  }
}

// Card de jogo no estilo da aba de Grupos (agendado → caixas de placar com o
// palpite) e do Perfil Visitante (ao vivo/encerrado → placar real + rodapé com
// o palpite e os pontos). Somente leitura; toque abre o grupo.
class _MatchOfDayCard extends StatelessWidget {
  final MatchModel match;
  final BetModel? bet;
  final Duration offset;

  const _MatchOfDayCard({
    required this.match,
    required this.bet,
    required this.offset,
  });

  String _formatTime(DateTime d, Duration offset) {
    final t = d.toUtc().add(offset);
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isScheduled = match.status == MatchStatus.scheduled;
    final hasRealScore = (match.status == MatchStatus.live ||
            match.status == MatchStatus.finished) &&
        match.homeScore != null &&
        match.awayScore != null;
    final isPartial = match.status == MatchStatus.live;

    int? points;
    if (bet != null && hasRealScore) {
      points = match.status == MatchStatus.finished
          ? bet!.points
          : computeBetPoints(
              homeBet: bet!.homeScoreBet,
              awayBet: bet!.awayScoreBet,
              homeReal: match.homeScore!,
              awayReal: match.awayScore!,
            );
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/groups/${match.groupLetter}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              // ── Top row: #id + status + kickoff ──
              Row(
                children: [
                  Text(
                    '#${match.apiMatchId ?? match.id.substring(0, 4)}',
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _MatchStatusChip(status: match.status, l: l),
                  const Spacer(),
                  if (isScheduled && match.matchDate != null)
                    Text(
                      _formatTime(match.matchDate!, offset),
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // ── Teams + score ──
              Row(
                children: [
                  Expanded(
                    child: _TeamCol(
                      name: match.homeTeam.name,
                      flagUrl: match.homeTeam.flagUrl,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: hasRealScore
                        ? Text(
                            '${match.homeScore} - ${match.awayScore}',
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ReadOnlyScoreBox(value: bet?.homeScoreBet),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'X',
                                  style: tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface.withOpacity(0.4),
                                  ),
                                ),
                              ),
                              _ReadOnlyScoreBox(value: bet?.awayScoreBet),
                            ],
                          ),
                  ),
                  Expanded(
                    child: _TeamCol(
                      name: match.awayTeam.name,
                      flagUrl: match.awayTeam.flagUrl,
                    ),
                  ),
                ],
              ),
              // ── Footer (ao vivo/encerrado): palpite + pontos ──
              if (hasRealScore) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: cs.outline.withOpacity(0.15)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      bet != null
                          ? '${bet!.homeScoreBet} - ${bet!.awayScoreBet}'
                          : '—',
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (points != null) ...[
                      const SizedBox(width: 8),
                      _MatchPointsBadge(
                          points: points, isPartial: isPartial, l: l),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamCol extends StatelessWidget {
  final String name;
  final String? flagUrl;
  const _TeamCol({required this.name, required this.flagUrl});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        FlagAvatar(flagUrl: flagUrl, radius: 26),
        const SizedBox(height: 8),
        Text(
          translateTeam(context, name),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// Caixa de placar somente leitura — mesmo visual do _ScoreBox da aba de Grupos
// no estado preenchido (tom da cor primária).
class _ReadOnlyScoreBox extends StatelessWidget {
  final int? value;
  const _ReadOnlyScoreBox({required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filled = value != null;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: filled ? cs.primary.withOpacity(0.1) : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled
              ? cs.primary.withOpacity(0.5)
              : cs.outline.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          value?.toString() ?? '—',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: filled ? cs.primary : cs.onSurface.withOpacity(0.35),
              ),
        ),
      ),
    );
  }
}

class _MatchStatusChip extends StatelessWidget {
  final MatchStatus status;
  final AppLocalizations l;
  const _MatchStatusChip({required this.status, required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      MatchStatus.scheduled => (l.statusScheduled, cs.outline),
      MatchStatus.live => (l.statusLive, Colors.red),
      MatchStatus.finished => (l.statusFinished, cs.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MatchPointsBadge extends StatelessWidget {
  final int points;
  final bool isPartial;
  final AppLocalizations l;
  const _MatchPointsBadge({
    required this.points,
    required this.isPartial,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (points) {
      3 => (cs.primary.withOpacity(0.15), cs.primary),
      1 => (Colors.amber.withOpacity(0.18), Colors.amber.shade800),
      _ => (cs.onSurface.withOpacity(0.08), cs.onSurface.withOpacity(0.55)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            points > 0 ? '+$points' : '0',
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          if (isPartial) ...[
            const SizedBox(width: 4),
            Text(
              l.partial,
              style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BET PROGRESS CARD
// ─────────────────────────────────────────────
// ignore: unused_element — preservado para reuso futuro (ver _NextMatchBanner)
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
// ADVANCED STATS ENTRY CARD
// ─────────────────────────────────────────────
class _AdvancedStatsEntryCard extends StatelessWidget {
  final AppLocalizations l;
  const _AdvancedStatsEntryCard({required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/stats'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withOpacity(0.25)),
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
                    l.advancedStats,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.advancedStatsSub,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.55),
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.primary.withOpacity(0.7)),
          ],
        ),
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
                  l.superPalpites,
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
              l.superPalpitesRemaining(remaining),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/features/profile/providers/profile_stats_provider.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';
import 'package:copa2026/shared/providers/phase_provider.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/providers/timezone_provider.dart';
import 'package:copa2026/shared/providers/locale_provider.dart';
import 'package:copa2026/shared/utils/bet_points.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';
import 'package:copa2026/features/profile/screens/profile_completion_screen.dart';
import 'package:copa2026/features/profile/providers/achievements_provider.dart';
import 'package:copa2026/features/profile/widgets/achievements_cards.dart';
import 'package:copa2026/features/profile/screens/visitor_profile_screen.dart';
import 'package:copa2026/shared/widgets/bet_filter_bar.dart';
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
    //
    // Deferido para depois do primeiro frame: chamar ref.invalidate dentro do
    // initState acessa o ProviderScope (inherited widget) antes do initState
    // concluir, o que dispara um assert em modo debug (invisível em release).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(allBetsProvider);
      ref.invalidate(allMatchesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(profileStatsProvider);
    final cs = Theme.of(context).colorScheme;
    // Segregação de fases na Home: na fase knockout, os cards da fase de grupos
    // (jogos do dia, pontos, super palpites) somem. Participantes do mata-mata
    // veem um atalho para o KO; os demais veem "Fase de grupos encerrada".
    final groupOn = ref.watch(groupStageVisibleProvider).valueOrNull ?? true;
    final koVisible = ref.watch(knockoutVisibleProvider).valueOrNull ?? false;
    // Participação na fase de grupos (independente da fase). Quem não participou
    // não vê os cards/Super Palpite de grupos, mesmo na fase mista.
    final groupParticipant =
        ref.watch(groupParticipantProvider).valueOrNull ?? true;

    // Pop a celebration on the home screen when new achievements unlock.
    ref.listen(achievementSyncProvider, (prev, next) {
      final newly = next.valueOrNull?.newlyGranted ?? const <String>[];
      if (newly.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) showAchievementCelebration(context, newly, l);
        });
      }
    });

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
            title: Text('🏠 ${l.home}'),
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

                // ── Jogos do dia ──────────────────────────
                // Independente da fase: reflete os jogos do dia da FASE DE
                // GRUPOS e do MATA-MATA juntos. Cada card leva ao destino certo
                // (grupo ou aba do mata-mata).
                const _TodayMatchesSection(),

                // ── Pontos por fase ───────────────────────
                // Grupos → só pontos de grupos; Mista → grupos + mata-mata;
                // Mata-Mata → só pontos do mata-mata. Cada um respeita também a
                // participação do usuário na fase respectiva.
                if (groupOn && groupParticipant) ...[
                  _PointsCard(stats: stats, l: l),
                  const SizedBox(height: 24),
                ],
                if (koVisible) ...[
                  _KoPointsCard(l: l),
                  const SizedBox(height: 24),
                ],

                // ── Super Palpite: só na fase de grupos e p/ participante ──
                // (removido nas fases que não mostram grupos, ex.: Mata-Mata).
                if (groupOn && groupParticipant) ...[
                  _SuperPalpiteCard(stats: stats, l: l),
                  const SizedBox(height: 24),
                ],
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
// KO POINTS CARD — pontos do MATA-MATA na Home (espelha o card de Pontos da
// fase de grupos). Toque abre a aba do mata-mata.
// ─────────────────────────────────────────────
class _KoPointsCard extends ConsumerWidget {
  final AppLocalizations l;
  const _KoPointsCard({required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final points = ref.watch(myKoPointsProvider).valueOrNull ?? 0;
    final exact = ref.watch(myKoExactHitsProvider).valueOrNull ?? 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/knockout'),
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
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('⚔️', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${l.totalPoints} · ${l.koMenu}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
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
                      '$points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StatTile(
                icon: '🎯',
                label: l.exactHits,
                value: '$exact',
                subtitle: l.koMenu,
                color: kGold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MATCHES OF THE DAY
// ─────────────────────────────────────────────
/// Date-only (year/month/day) in the user's timezone, used to group matches by
/// matchday and to drive the day picker.
DateTime _localDate(DateTime utc, Duration offset) {
  final t = utc.toUtc().add(offset);
  return DateTime(t.year, t.month, t.day);
}

class _TodayMatchesSection extends ConsumerStatefulWidget {
  const _TodayMatchesSection();

  @override
  ConsumerState<_TodayMatchesSection> createState() =>
      _TodayMatchesSectionState();
}

class _TodayMatchesSectionState extends ConsumerState<_TodayMatchesSection> {
  // null → follow the current tournament day; set → a user-picked matchday.
  DateTime? _selectedDay;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  Future<void> _pickDay(BuildContext context, List<DateTime> matchDays,
      DateTime current) async {
    final days = matchDays.toSet();
    final sorted = matchDays.toList()..sort();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: sorted.first,
      lastDate: sorted.last,
      selectableDayPredicate: (d) =>
          days.contains(DateTime(d.year, d.month, d.day)),
    );
    if (picked != null) {
      setState(() =>
          _selectedDay = DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final offset = ref.watch(timezoneProvider);
    final groupBets =
        ref.watch(allBetsProvider).valueOrNull ?? const <String, BetModel>{};
    final groupMatches =
        ref.watch(allMatchesProvider).valueOrNull ?? const <MatchModel>[];
    final koMatches =
        ref.watch(koMatchesProvider).valueOrNull ?? const <KoMatch>[];
    final koBets =
        ref.watch(koMyBetsProvider).valueOrNull ?? const <String, (int, int)>{};

    // "Jogos do dia" segue a FASE do torneio (igual ao resto do app):
    //   • grupos entram nas fases Grupos/Mista (groupStageVisible);
    //   • mata-mata entra nas fases Mista/Mata-Mata, e só p/ quem participa
    //     (knockoutVisible — mesmo gate do menu/telas do KO).
    // Como os dias do calendário derivam destas entradas, o filtro por data
    // também fica restrito aos jogos da fase atual.
    final groupOn = ref.watch(groupStageVisibleProvider).valueOrNull ?? true;
    final koOn = ref.watch(knockoutVisibleProvider).valueOrNull ?? false;

    final entries = <({DateTime date, _DayMatch dm})>[];
    if (groupOn) {
      for (final m in groupMatches) {
        if (m.matchDate == null) continue;
        entries.add((
          date: _localDate(m.matchDate!, offset),
          dm: _DayMatch.fromGroup(m, groupBets[m.id]),
        ));
      }
    }
    if (koOn) {
      for (final m in koMatches) {
        if (m.matchDate == null) continue;
        entries.add((
          date: _localDate(m.matchDate!, offset),
          dm: _DayMatch.fromKo(m, koBets[m.id]),
        ));
      }
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    // Dias com jogos (para o seletor) e o default = primeiro dia com jogos a
    // partir de hoje (fuso do usuário); se o torneio acabou, o último dia.
    final matchDays = entries.map((e) => e.date).toSet().toList()..sort();
    final today = _localDate(DateTime.now().toUtc(), offset);
    final defaultDay = matchDays.firstWhere((d) => !d.isBefore(today),
        orElse: () => matchDays.last);
    final day = _selectedDay ?? defaultDay;

    final shown = entries.where((e) => e.date == day).map((e) => e.dm).toList()
      ..sort((a, b) =>
          (a.kickoff ?? DateTime(0)).compareTo(b.kickoff ?? DateTime(0)));

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
              // Date chip → opens a calendar restricted to days that have games.
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _pickDay(context, matchDays, day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 13, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          _fmt(day),
                          style: tt.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            size: 18, color: cs.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Coluna única de cards full-width (mesma largura de Pontos/Super).
        ...shown.map((dm) => _MatchOfDayCard(dm: dm, offset: offset)),
        const SizedBox(height: 8),
      ],
    );
  }
}

// View-model unificado de um "jogo do dia": vale para a fase de grupos OU para
// o mata-mata. Normaliza ambos para o card renderizar igual e rotear ao destino
// certo (grupo vs aba do mata-mata).
class _DayMatch {
  final String idLabel;
  final MatchStatus status;
  final DateTime? kickoff;
  final String homeName;
  final String? homeFlag;
  final String awayName;
  final String? awayFlag;
  final int? homeScore;
  final int? awayScore;
  final int? homePens; // só mata-mata
  final int? awayPens;
  final int? betHome;
  final int? betAway;
  final int? points;
  final bool isPartial;
  final String routeTarget;

  const _DayMatch({
    required this.idLabel,
    required this.status,
    required this.kickoff,
    required this.homeName,
    required this.homeFlag,
    required this.awayName,
    required this.awayFlag,
    required this.homeScore,
    required this.awayScore,
    required this.homePens,
    required this.awayPens,
    required this.betHome,
    required this.betAway,
    required this.points,
    required this.isPartial,
    required this.routeTarget,
  });

  factory _DayMatch.fromGroup(MatchModel m, BetModel? bet) {
    final hasReal = (m.status == MatchStatus.live ||
            m.status == MatchStatus.finished) &&
        m.homeScore != null &&
        m.awayScore != null;
    int? pts;
    if (bet != null && hasReal) {
      pts = m.status == MatchStatus.finished
          ? bet.points
          : computeBetPoints(
              homeBet: bet.homeScoreBet,
              awayBet: bet.awayScoreBet,
              homeReal: m.homeScore!,
              awayReal: m.awayScore!,
            );
    }
    return _DayMatch(
      idLabel: '#${m.apiMatchId ?? m.id.substring(0, 4)}',
      status: m.status,
      kickoff: m.matchDate,
      homeName: m.homeTeam.name,
      homeFlag: m.homeTeam.flagUrl,
      awayName: m.awayTeam.name,
      awayFlag: m.awayTeam.flagUrl,
      homeScore: m.homeScore,
      awayScore: m.awayScore,
      homePens: null,
      awayPens: null,
      betHome: bet?.homeScoreBet,
      betAway: bet?.awayScoreBet,
      points: pts,
      isPartial: m.status == MatchStatus.live,
      routeTarget: '/groups/${m.groupLetter}',
    );
  }

  factory _DayMatch.fromKo(KoMatch m, (int, int)? bet) {
    final hasReal = (m.status == MatchStatus.live ||
            m.status == MatchStatus.finished) &&
        m.homeScore != null &&
        m.awayScore != null;
    int? pts;
    if (bet != null && hasReal) {
      pts = koBetPoints(m.round, bet.$1, bet.$2, m.homeScore!, m.awayScore!);
    }
    return _DayMatch(
      idLabel: m.gameNoLabel,
      status: m.status,
      kickoff: m.matchDate,
      homeName: m.homeText,
      homeFlag: m.home?.flagUrl,
      awayName: m.awayText,
      awayFlag: m.away?.flagUrl,
      homeScore: m.homeScore,
      awayScore: m.awayScore,
      homePens: m.homePens,
      awayPens: m.awayPens,
      betHome: bet?.$1,
      betAway: bet?.$2,
      points: pts,
      isPartial: m.status == MatchStatus.live,
      routeTarget: '/knockout',
    );
  }
}

// Card de jogo no estilo da aba de Grupos (agendado → caixas de placar com o
// palpite) e do Perfil Visitante (ao vivo/encerrado → placar real + rodapé com
// o palpite e os pontos). Somente leitura; toque abre o grupo ou o mata-mata.
class _MatchOfDayCard extends StatelessWidget {
  final _DayMatch dm;
  final Duration offset;

  const _MatchOfDayCard({required this.dm, required this.offset});

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

    final isScheduled = dm.status == MatchStatus.scheduled;
    final hasRealScore = (dm.status == MatchStatus.live ||
            dm.status == MatchStatus.finished) &&
        dm.homeScore != null &&
        dm.awayScore != null;
    final hasPens = dm.homePens != null && dm.awayPens != null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(dm.routeTarget),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              // ── Top row: #id + status + kickoff ──
              Row(
                children: [
                  Text(
                    dm.idLabel,
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _MatchStatusChip(status: dm.status, l: l),
                  const Spacer(),
                  if (isScheduled && dm.kickoff != null)
                    Text(
                      _formatTime(dm.kickoff!, offset),
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
                    child: _TeamCol(name: dm.homeName, flagUrl: dm.homeFlag),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: hasRealScore
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${dm.homeScore} - ${dm.awayScore}',
                                style: tt.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              // Pênaltis (só mata-mata): "(4 - 3)" abaixo do placar.
                              if (hasPens)
                                Text(
                                  '(${dm.homePens} - ${dm.awayPens})',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurface.withOpacity(0.6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ReadOnlyScoreBox(value: dm.betHome),
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
                              _ReadOnlyScoreBox(value: dm.betAway),
                            ],
                          ),
                  ),
                  Expanded(
                    child: _TeamCol(name: dm.awayName, flagUrl: dm.awayFlag),
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
                      (dm.betHome != null && dm.betAway != null)
                          ? '${dm.betHome} - ${dm.betAway}'
                          : '—',
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (dm.points != null) ...[
                      const SizedBox(width: 8),
                      _MatchPointsBadge(
                          points: dm.points!, isPartial: dm.isPartial, l: l),
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
class _PointsCard extends ConsumerWidget {
  final ProfileStats stats;
  final AppLocalizations l;
  const _PointsCard({required this.stats, required this.l});

  /// Opens the viewer's own bets (self mode) pre-filtered to a given outcome,
  /// so tapping "exact hits" / "result hits" jumps straight to those games.
  /// Builds a partial entry from the already-loaded [stats] so the header shows
  /// name/avatar/points instantly; the screen fills in the exact rank once the
  /// ranking stream loads.
  void _openSelfBets(BuildContext context, WidgetRef ref, BetOutcome outcome) {
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return;
    final partial = RankingEntry(
      userId: uid,
      username: stats.username,
      fullName: stats.fullName,
      displayPreference: stats.displayPreference,
      avatarUrl: stats.avatarUrl,
      totalPoints: stats.totalPoints,
      totalBets: stats.totalBets,
      rank: 0, // filled in by the screen from the ranking stream
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VisitorProfileScreen(
          userId: uid, entry: partial, initialOutcome: outcome),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

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
                    onTap: () =>
                        _openSelfBets(context, ref, BetOutcome.exact),
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
                    onTap: () =>
                        _openSelfBets(context, ref, BetOutcome.result),
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

  /// When set, the tile is tappable (opens the user's own bets filtered to the
  /// matching outcome) and shows a chevron affordance.
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final content = Container(
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
              if (onTap != null)
                Icon(Icons.chevron_right,
                    size: 16, color: cs.onSurface.withOpacity(0.35)),
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

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: content,
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

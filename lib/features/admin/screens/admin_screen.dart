import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:copa2026/l10n/team_translator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import 'package:copa2026/services/master_data_service.dart';
import 'package:copa2026/shared/utils/error_messages.dart';
import 'package:copa2026/utils/downloader.dart';

import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';
import 'package:copa2026/features/leagues/providers/leagues_provider.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';
import 'package:copa2026/features/knockout/providers/knockout_provider.dart';
import 'package:copa2026/shared/providers/phase_provider.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Admin: list of all matches for override
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final allMatchesProvider = FutureProvider<List<MatchModel>>((ref) async {
  final response = await Supabase.instance.client
      .from('matches')
      .select('''
        id, group_letter, match_date, home_score, away_score, status, api_match_id,
        home_team:teams!matches_home_team_id_fkey(id, name, flag_url, group_letter),
        away_team:teams!matches_away_team_id_fkey(id, name, flag_url, group_letter)
      ''')
      .order('group_letter')
      .order('match_date');

  return (response as List)
      .map((m) => MatchModel.fromJson(m as Map<String, dynamic>))
      .toList();
});

final adminUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client.rpc('get_admin_users');
  return List<Map<String, dynamic>>.from(response);
});

// IDs dos usuários com o mata-mata liberado (inscrição separada do bolão
// principal). Vem de uma RPC SECURITY DEFINER (profiles é restrito) — ver
// supabase/knockout_access.sql.
final adminKnockoutUnlockedProvider = FutureProvider<Set<String>>((ref) async {
  final response =
      await Supabase.instance.client.rpc('get_knockout_unlocked_ids');
  return (response as List).map((e) => e.toString()).toSet();
});

// IDs dos usuários que participam da FASE DE GRUPOS (profiles.groups_unlocked).
// RPC SECURITY DEFINER — ver supabase/groups_access.sql.
final adminGroupsUnlockedProvider = FutureProvider<Set<String>>((ref) async {
  final response =
      await Supabase.instance.client.rpc('get_groups_unlocked_ids');
  return (response as List).map((e) => e.toString()).toSet();
});

// Todas as ligas (id + nome). RLS de `leagues` é SELECT USING (true), então o
// admin pode listar todas. Usado na aba de adicionar usuários a ligas.
final adminAllLeaguesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('leagues')
      .select('id, name')
      .order('name');
  return List<Map<String, dynamic>>.from(data);
});



class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  bool _isSyncing = false;

  Future<void> _syncMasterData() async {
    setState(() => _isSyncing = true);
    try {
      final (updated, errors) = await MasterDataService.syncMatchesFromSheet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Planilha sincronizada: $updated atualizados, $errors erros.')),
        );
        ref.invalidate(allMatchesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errSyncFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final matchesAsync = ref.watch(allMatchesProvider);

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(' 👑'),
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
              tabs: [
              Tab(icon: const Icon(Icons.flag), text: 'Fase'),
              Tab(icon: const Icon(Icons.sports_soccer), text: l.adminTabMatches),
              Tab(icon: const Icon(Icons.sports_mma), text: 'Mata-Mata'),
              Tab(icon: const Icon(Icons.notifications_active), text: 'Notificar'),
              Tab(icon: const Icon(Icons.people), text: l.adminTabUsers),
              Tab(icon: const Icon(Icons.groups), text: 'Ligas'),
            ],
          ),

      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        children: [
          const _AdminPhaseTab(),
          matchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (matches) {
              // Group by letter
              final grouped = <String, List<MatchModel>>{};
              for (final m in matches) {
                grouped.putIfAbsent(m.groupLetter, () => []).add(m);
              }

              final keys = grouped.keys.toList()..sort();

              return Scaffold(
                backgroundColor: Colors.transparent,
                floatingActionButton: FloatingActionButton.extended(
                  onPressed: _isSyncing ? null : _syncMasterData,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync),
                  label: const Text('Atualizar'),
                ),
                body: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  children: keys.map((key) {
                    return _AdminGroupSection(
                      groupLetter: key,
                      matches: grouped[key]!,
                      ref: ref,
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const _AdminKnockoutTab(),
          const _AdminNotificationsTab(),
          const _AdminUsersTab(),
          const _AdminLeaguesTab(),
        ],
      ),
    ));
  }
}

// ─────────────────────────────────────────────
// Admin: ABA FASE DO BOLÃO (grava em app_config.phase)
// Fonte única de verdade da fase atual — controla, para TODOS os usuários, o
// que fica visível (ver tournamentPhaseProvider / phase_provider.dart).
// A troca é em DOIS PASSOS: escolher a fase + Confirmar, e ainda um duplo check,
// porque o impacto é global e sensível.
// ─────────────────────────────────────────────
String _phaseLabel(TournamentPhase p) => switch (p) {
      TournamentPhase.groups => 'Grupos',
      TournamentPhase.mixed => 'Mista',
      TournamentPhase.knockout => 'Mata-Mata',
    };

class _AdminPhaseTab extends ConsumerStatefulWidget {
  const _AdminPhaseTab();

  @override
  ConsumerState<_AdminPhaseTab> createState() => _AdminPhaseTabState();
}

class _AdminPhaseTabState extends ConsumerState<_AdminPhaseTab> {
  /// Seleção pendente (ainda não salva). null = segue a fase atual do servidor.
  TournamentPhase? _pending;
  bool _saving = false;

  String _phaseKey(TournamentPhase p) => switch (p) {
        TournamentPhase.groups => 'groups',
        TournamentPhase.mixed => 'mixed',
        TournamentPhase.knockout => 'knockout',
      };

  Future<void> _confirmAndSave(TournamentPhase phase) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deseja realmente alterar a fase do bolão?'),
        content: Text(
          'A fase passará para "${_phaseLabel(phase)}". Isso muda, para TODOS '
          'os usuários, o que fica visível no app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _save(phase);
  }

  Future<void> _save(TournamentPhase phase) async {
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('app_config').upsert(
        {
          'key': 'phase',
          'value': {'phase': _phaseKey(phase)},
        },
        onConflict: 'key',
      );
      ref.invalidate(tournamentPhaseProvider);
      if (mounted) {
        setState(() => _pending = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fase atualizada: ${_phaseLabel(phase)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao mudar a fase: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final phaseAsync = ref.watch(tournamentPhaseProvider);

    return phaseAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar a fase: $e')),
      data: (current) {
        final selected = _pending ?? current;
        final dirty = selected != current;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fase do Bolão',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fase atual: ${_phaseLabel(current)}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Controla o que TODOS veem. Grupos: só a fase de grupos '
                      '(esconde o mata-mata). Mista: grupos + mata-mata. '
                      'Mata-Mata: só o mata-mata (esconde os grupos). '
                      'Recomendado manter em "Mista" durante todo o mata-mata; '
                      'use "Mata-Mata" só ao final, para aposentar os grupos.',
                      style: TextStyle(fontSize: 12, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<TournamentPhase>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                              value: TournamentPhase.groups,
                              label: Text('Grupos')),
                          ButtonSegment(
                              value: TournamentPhase.mixed,
                              label: Text('Mista')),
                          ButtonSegment(
                              value: TournamentPhase.knockout,
                              label: Text('Mata-Mata')),
                        ],
                        selected: {selected},
                        onSelectionChanged: _saving
                            ? null
                            : (s) => setState(() => _pending = s.first),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (!dirty || _saving)
                            ? null
                            : () => _confirmAndSave(selected),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Confirmar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Admin: Mata-Mata — editar status/placar/quem avança por fase
// ─────────────────────────────────────────────
class _AdminKnockoutTab extends ConsumerWidget {
  const _AdminKnockoutTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(koMatchesProvider);
    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (matches) {
        if (matches.isEmpty) {
          return const Center(child: Text('Chaveamento ainda não disponível.'));
        }
        final byRound = <String, List<KoMatch>>{};
        for (final m in matches) {
          byRound.putIfAbsent(m.round, () => []).add(m);
        }
        for (final list in byRound.values) {
          list.sort((a, b) => (a.matchNo ?? a.slot).compareTo(b.matchNo ?? b.slot));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            for (final round in kKoRounds)
              if (byRound[round] != null)
                _AdminKoRoundSection(
                    round: round, matches: byRound[round]!, ref: ref),
          ],
        );
      },
    );
  }
}

class _AdminKoRoundSection extends StatelessWidget {
  final String round;
  final List<KoMatch> matches;
  final WidgetRef ref;

  const _AdminKoRoundSection(
      {required this.round, required this.matches, required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            koRoundLabel(AppLocalizations.of(context)!, round).toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.primary,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
          children:
              matches.map((m) => _AdminKoMatchTile(match: m, ref: ref)).toList(),
        ),
      ),
    );
  }
}

class _AdminKoMatchTile extends StatelessWidget {
  final KoMatch match;
  final WidgetRef ref;

  const _AdminKoMatchTile({required this.match, required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final homeName = match.home?.name ?? match.homeSlotLabel ?? 'A definir';
    final awayName = match.away?.name ?? match.awaySlotLabel ?? 'A definir';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('$homeName  X  $awayName',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: _subtitle(context),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: cs.primary),
          onPressed: () => _showDialog(context),
        ),
      ),
    );
  }

  Widget _subtitle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final parts = <String>[];
    if (match.homeScore != null && match.awayScore != null) {
      parts.add('${match.homeScore} – ${match.awayScore}');
    }
    parts.add('[${match.status.name}]');
    if (match.advancing != null) parts.add('avança: ${match.advancing!.name}');
    return Text(parts.join('   '),
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600));
  }

  void _showDialog(BuildContext context) {
    final homeCtrl =
        TextEditingController(text: match.homeScore?.toString() ?? '');
    final awayCtrl =
        TextEditingController(text: match.awayScore?.toString() ?? '');
    MatchStatus status = match.status;
    // Opções de "quem avança": null, time da casa, visitante (quando definidos).
    String? advancingId = match.advancing?.id;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          final advItems = <DropdownMenuItem<String?>>[
            const DropdownMenuItem(value: null, child: Text('—')),
            if (match.home != null)
              DropdownMenuItem(value: match.home!.id, child: Text(match.home!.name)),
            if (match.away != null)
              DropdownMenuItem(value: match.away!.id, child: Text(match.away!.name)),
          ];
          // Evita valor inválido se o time selecionado não estiver na lista.
          final advValue =
              advItems.any((i) => i.value == advancingId) ? advancingId : null;

          return AlertDialog(
            title: Text(
                '${match.home?.name ?? match.homeSlotLabel ?? '?'} X ${match.away?.name ?? match.awaySlotLabel ?? '?'}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: homeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Casa'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('–', style: TextStyle(fontSize: 20)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: awayCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Visitante'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MatchStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: MatchStatus.values
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setState(() => status = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: advValue,
                  decoration: const InputDecoration(labelText: 'Quem avança'),
                  items: advItems,
                  onChanged: (v) => setState(() => advancingId = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final home = int.tryParse(homeCtrl.text);
                  final away = int.tryParse(awayCtrl.text);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await Supabase.instance.client.from('ko_match').update({
                      'home_score': home,
                      'away_score': away,
                      'status': status.name,
                      'advancing_team_id': advancingId,
                    }).eq('id', match.id);

                    ref.invalidate(koMatchesProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Jogo atualizado.')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            describeError(AppLocalizations.of(context)!, e)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminGroupSection extends StatelessWidget {
  final String groupLetter;
  final List<MatchModel> matches;
  final WidgetRef ref;

  const _AdminGroupSection({
    required this.groupLetter,
    required this.matches,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'GRUPO $groupLetter',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.primary,
              letterSpacing: 1.5,
              fontSize: 14,
            ),
          ),
          children: matches.map((m) => _AdminMatchTile(match: m, ref: ref)).toList(),
        ),
      ),
    );
  }
}

class _AdminMatchTile extends StatelessWidget {
  final MatchModel match;
  final WidgetRef ref;

  const _AdminMatchTile({required this.match, required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '${translateTeam(context, match.homeTeam.name)} X ${translateTeam(context, match.awayTeam.name)}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: _buildScoreSubtitle(context),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: cs.primary),
          onPressed: () => _showOverrideDialog(context),
        ),
      ),
    );
  }

  Widget _buildScoreSubtitle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (match.homeScore != null && match.awayScore != null) {
      return Text(
        '${match.homeScore} – ${match.awayScore}   [${match.status.name}]',
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700),
      );
    }
    return Text(
      match.status.name,
      style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
    );
  }

  void _showOverrideDialog(BuildContext context) {
    final homeCtrl = TextEditingController(
        text: match.homeScore?.toString() ?? '');
    final awayCtrl = TextEditingController(
        text: match.awayScore?.toString() ?? '');
    MatchStatus selectedStatus = match.status;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('${translateTeam(context, match.homeTeam.name)} X ${translateTeam(context, match.awayTeam.name)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: homeCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: translateTeam(context, match.homeTeam.name)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('–', style: TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: awayCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          InputDecoration(labelText: translateTeam(context, match.awayTeam.name)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MatchStatus>(
                initialValue: selectedStatus,
                decoration:
                    const InputDecoration(labelText: 'Status'),
                items: MatchStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedStatus = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final home = int.tryParse(homeCtrl.text);
                final away = int.tryParse(awayCtrl.text);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await Supabase.instance.client
                      .from('matches')
                      .update({
                        if (home != null) 'home_score': home,
                        if (away != null) 'away_score': away,
                        'status': selectedStatus.name,
                      })
                      .eq('id', match.id);

                  ref.invalidate(allMatchesProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Partida atualizada.')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(describeError(AppLocalizations.of(context)!, e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}


class _AdminNotificationsTab extends StatefulWidget {
  const _AdminNotificationsTab();

  @override
  State<_AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends State<_AdminNotificationsTab> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _filter = 'all';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.isEmpty || _msgCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha título e mensagem.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.rpc(
        'admin_send_notification',
        params: {
          'p_title': _titleCtrl.text,
          'p_message': _msgCtrl.text,
          'p_filter': _filter,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificações enviadas com sucesso!')),
        );
        _titleCtrl.clear();
        _msgCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Enviar Notificação em Massa',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Título da Notificação',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _msgCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Mensagem Completa',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Enviar para:', style: TextStyle(fontWeight: FontWeight.bold)),
        RadioListTile<String>(
          title: const Text('Todos os Usuários'),
          value: 'all',
          groupValue: _filter,
          onChanged: (v) => setState(() => _filter = v!),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('Usuários com apostas incompletas'),
          value: 'missing_bets',
          groupValue: _filter,
          onChanged: (v) => setState(() => _filter = v!),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('Apenas quem JÁ PAGOU'),
          value: 'paid',
          groupValue: _filter,
          onChanged: (v) => setState(() => _filter = v!),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('Apenas quem NÃO PAGOU'),
          value: 'unpaid',
          groupValue: _filter,
          onChanged: (v) => setState(() => _filter = v!),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _send,
            icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Disparar Notificações'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminUsersTab extends ConsumerStatefulWidget {
  const _AdminUsersTab();

  @override
  ConsumerState<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<_AdminUsersTab> {
  String _searchQuery = '';
  String _filter = 'all';

  List<List<dynamic>> _csvRows(List<Map<String, dynamic>> users) {
    final rows = <List<dynamic>>[
      ['Username', 'Nome Completo', 'Email', 'Telefone', 'Status Pagamento']
    ];
    for (var u in users) {
      rows.add([
        u['username'] ?? '',
        u['full_name'] ?? '',
        u['email'] ?? '',
        u['phone'] ?? '',
        (u['paid'] == true) ? 'Pago' : 'Pendente',
      ]);
    }
    return rows;
  }

  Future<void> _copyCsv(List<Map<String, dynamic>> users) async {
    final csv = Csv().encode(_csvRows(users));
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV copiado para a área de transferência!')),
      );
    }
  }

  void _downloadCsv(List<Map<String, dynamic>> users) {
    final csv = Csv().encode(_csvRows(users));
    // BOM UTF-8 para que o Excel reconheça a acentuação corretamente.
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
    try {
      downloadBytes(bytes, 'usuarios_bolao.csv', 'text/csv;charset=utf-8');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download iniciado! Verifique sua pasta de downloads.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao baixar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _togglePaid(Map<String, dynamic> u) async {
    final newVal = !(u['paid'] == true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'paid': newVal})
          .eq('id', u['id']);
      ref.invalidate(adminUsersProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Libera/bloqueia o mata-mata para um usuário (inscrição separada).
  Future<void> _toggleKnockout(Map<String, dynamic> u, bool currentlyOn) async {
    final newVal = !currentlyOn;
    try {
      await Supabase.instance.client.from('profiles').update({
        'knockout_unlocked': newVal,
        'knockout_unlocked_at': newVal ? DateTime.now().toIso8601String() : null,
      }).eq('id', u['id']);
      ref.invalidate(adminKnockoutUnlockedProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Marca/desmarca participação do usuário na FASE DE GRUPOS.
  Future<void> _toggleGroups(Map<String, dynamic> u, bool currentlyOn) async {
    final newVal = !currentlyOn;
    try {
      await Supabase.instance.client.from('profiles').update({
        'groups_unlocked': newVal,
        'groups_unlocked_at': newVal ? DateTime.now().toIso8601String() : null,
      }).eq('id', u['id']);
      ref.invalidate(adminGroupsUnlockedProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final usersAsync = ref.watch(adminUsersProvider);
    final koUnlockedIds =
        ref.watch(adminKnockoutUnlockedProvider).valueOrNull ?? const <String>{};
    final groupsUnlockedIds =
        ref.watch(adminGroupsUnlockedProvider).valueOrNull ?? const <String>{};

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (users) {
        var filtered = users.where((u) {
          final isPaid = u['paid'] == true;
          if (_filter == 'paid' && !isPaid) return false;
          if (_filter == 'unpaid' && isPaid) return false;
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final name = (u['full_name'] ?? '').toString().toLowerCase();
            final user = (u['username'] ?? '').toString().toLowerCase();
            final email = (u['email'] ?? '').toString().toLowerCase();
            if (!(name.contains(q) || user.contains(q) || email.contains(q))) {
              return false;
            }
          }
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: l.searchUsers,
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _filter,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Todos')),
                          DropdownMenuItem(value: 'paid', child: Text('Pagos')),
                          DropdownMenuItem(value: 'unpaid', child: Text('Pendentes')),
                        ],
                        onChanged: (v) => setState(() => _filter = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Expanded garante largura limitada aos botões (o tema usa
                  // minimumSize com largura infinita), evitando o erro de
                  // "BoxConstraints forces an infinite width".
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyCsv(filtered),
                          icon: const Icon(Icons.copy),
                          label: const Text('Copiar CSV'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadCsv(filtered),
                          icon: const Icon(Icons.download),
                          label: const Text('Baixar CSV'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Nenhum usuário encontrado.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final u = filtered[index];
                        final bool isPaid = u['paid'] == true;
                        final bool koOn =
                            koUnlockedIds.contains(u['id']?.toString());
                        final bool grpOn =
                            groupsUnlockedIds.contains(u['id']?.toString());
                        final cs = Theme.of(context).colorScheme;
                        final Color statusColor =
                            isPaid ? Colors.green : Colors.grey;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u['username'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      if ((u['full_name'] ?? '').toString().isNotEmpty)
                                        Text(u['full_name'] ?? ''),
                                      Text(
                                        u['email'] ?? '',
                                        style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                                      ),
                                      if ((u['phone'] ?? '').toString().isNotEmpty)
                                        Text(u['phone'] ?? ''),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Badges (empilhados p/ não estourar a largura):
                                // Grupos, Mata-Mata e Pagamento.
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Badge clicável: participação na fase de grupos.
                                    Tooltip(
                                      message: grpOn
                                          ? 'Fase de grupos liberada — clique para bloquear'
                                          : 'Fase de grupos bloqueada — clique para liberar',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => _toggleGroups(u, grpOn),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: (grpOn ? Colors.teal : Colors.grey)
                                                .withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                                color: grpOn ? Colors.teal : Colors.grey),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                grpOn
                                                    ? Icons.sports_soccer
                                                    : Icons.lock_outline,
                                                size: 16,
                                                color: grpOn ? Colors.teal : Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Grupos',
                                                style: TextStyle(
                                                  color: grpOn ? Colors.teal : Colors.grey,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Badge clicável: libera/bloqueia o mata-mata
                                    // (inscrição separada do bolão principal).
                                    Tooltip(
                                      message: koOn
                                          ? 'Mata-Mata liberado — clique para bloquear'
                                          : 'Mata-Mata bloqueado — clique para liberar',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => _toggleKnockout(u, koOn),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: (koOn ? Colors.deepPurple : Colors.grey)
                                                .withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                                color: koOn ? Colors.deepPurple : Colors.grey),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                koOn ? Icons.sports_mma : Icons.lock_outline,
                                                size: 16,
                                                color: koOn ? Colors.deepPurple : Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Mata-Mata',
                                                style: TextStyle(
                                                  color: koOn ? Colors.deepPurple : Colors.grey,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Badge clicável: alterna o status de pagamento.
                                    Tooltip(
                                      message: isPaid
                                          ? 'Clique para marcar como Pendente'
                                          : 'Clique para marcar como Pago',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => _togglePaid(u),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: statusColor),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isPaid ? Icons.check_circle : Icons.attach_money,
                                                size: 16,
                                                color: statusColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isPaid ? l.paymentRealized : l.paymentPending,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Admin: adicionar usuários a ligas (multi-seleção)
// ─────────────────────────────────────────────
class _PickOption {
  final String id;
  final String label;
  final String? sub;
  const _PickOption(this.id, this.label, [this.sub]);
}

class _AdminLeaguesTab extends ConsumerStatefulWidget {
  const _AdminLeaguesTab();

  @override
  ConsumerState<_AdminLeaguesTab> createState() => _AdminLeaguesTabState();
}

class _AdminLeaguesTabState extends ConsumerState<_AdminLeaguesTab> {
  String _leagueQuery = '';
  String _userQuery = '';
  final Map<String, String> _selLeagues = {}; // id -> nome
  final Map<String, String> _selUsers = {}; // id -> label
  bool _submitting = false;

  Future<void> _submit() async {
    if (_selLeagues.isEmpty || _selUsers.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final result = await Supabase.instance.client.rpc(
        'admin_add_users_to_leagues',
        params: {
          'p_user_ids': _selUsers.keys.toList(),
          'p_league_ids': _selLeagues.keys.toList(),
        },
      );
      if (!mounted) return;
      final inserted = (result as num?)?.toInt() ?? 0;
      final attempted = _selUsers.length * _selLeagues.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$inserted novo(s) vínculo(s) de $attempted (duplicados ignorados).'),
        ),
      );
      setState(() {
        _selLeagues.clear();
        _selUsers.clear();
        _leagueQuery = '';
        _userQuery = '';
      });
      // Caso o próprio admin tenha sido adicionado a alguma liga.
      ref.invalidate(myLeaguesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final usersAsync = ref.watch(adminUsersProvider);
    final leaguesAsync = ref.watch(adminAllLeaguesProvider);

    final canSubmit =
        _selLeagues.isNotEmpty && _selUsers.isNotEmpty && !_submitting;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const Text(
          'Adicionar usuários a ligas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecione uma ou mais ligas e um ou mais usuários. '
          'Cada usuário será adicionado a cada liga selecionada.',
          style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 20),

        // ── 1. Ligas ──
        const Text('1. Ligas', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        leaguesAsync.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
          error: (e, _) =>
              Text('Erro ao carregar ligas: $e', style: TextStyle(color: cs.error)),
          data: (leagues) {
            final options = leagues
                .map((lg) =>
                    _PickOption(lg['id'] as String, (lg['name'] ?? '') as String))
                .toList();
            return _selector(
              hint: 'Buscar liga pelo nome...',
              query: _leagueQuery,
              onQuery: (v) => setState(() => _leagueQuery = v),
              selected: _selLeagues,
              options: options,
              onAdd: (o) => setState(() => _selLeagues[o.id] = o.label),
              onRemove: (id) => setState(() => _selLeagues.remove(id)),
            );
          },
        ),
        const SizedBox(height: 24),

        // ── 2. Usuários ──
        const Text('2. Usuários', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        usersAsync.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
          error: (e, _) => Text('Erro ao carregar usuários: $e',
              style: TextStyle(color: cs.error)),
          data: (users) {
            final options = users.map((u) {
              final username = (u['username'] ?? '') as String;
              final fullName = (u['full_name'] ?? '') as String;
              return _PickOption(
                u['id'] as String,
                username.isNotEmpty ? username : fullName,
                fullName.isNotEmpty ? fullName : null,
              );
            }).toList();
            return _selector(
              hint: 'Buscar usuário por nome ou username...',
              query: _userQuery,
              onQuery: (v) => setState(() => _userQuery = v),
              selected: _selUsers,
              options: options,
              onAdd: (o) => setState(() => _selUsers[o.id] = o.label),
              onRemove: (id) => setState(() => _selUsers.remove(id)),
            );
          },
        ),
        const SizedBox(height: 28),

        // ── Confirmar ──
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: canSubmit ? _submit : null,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.group_add),
            label: Text(
              _submitting
                  ? 'Adicionando...'
                  : 'Adicionar Usuários (${_selUsers.length}×${_selLeagues.length})',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Campo de busca + chips dos itens selecionados + lista de resultados.
  /// Combobox multi-seleção: cada toque num resultado adiciona ao conjunto
  /// (sem substituir); o chip remove. Resultados aparecem só com busca ativa.
  Widget _selector({
    required String hint,
    required String query,
    required ValueChanged<String> onQuery,
    required Map<String, String> selected,
    required List<_PickOption> options,
    required void Function(_PickOption) onAdd,
    required void Function(String id) onRemove,
  }) {
    final cs = Theme.of(context).colorScheme;
    final q = query.trim().toLowerCase();

    final results = q.isEmpty
        ? const <_PickOption>[]
        : options.where((o) {
            if (selected.containsKey(o.id)) return false;
            return o.label.toLowerCase().contains(q) ||
                (o.sub?.toLowerCase().contains(q) ?? false);
          }).take(25).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: selected.entries
                  .map((e) => Chip(
                        label: Text(e.value),
                        onDeleted: () => onRemove(e.key),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: onQuery,
        ),
        if (q.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: results.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Nenhum resultado.'))
                : Column(
                    children: results
                        .map((o) => ListTile(
                              dense: true,
                              title: Text(o.label),
                              subtitle: (o.sub != null && o.sub!.isNotEmpty)
                                  ? Text(o.sub!)
                                  : null,
                              trailing: const Icon(Icons.add),
                              onTap: () => onAdd(o),
                            ))
                        .toList(),
                  ),
          ),
      ],
    );
  }
}

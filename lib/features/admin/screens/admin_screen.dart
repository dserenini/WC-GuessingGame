import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:copa2026/l10n/team_translator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/services/master_data_service.dart';

import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';
import 'package:copa2026/shared/models/match.dart';

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

final allProfilesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('profiles')
      .select('id, username, paid')
      .order('username');
  return List<Map<String, dynamic>>.from(response);
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
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
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
      length: 3,
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sports_soccer), text: 'Partidas'),
              Tab(icon: Icon(Icons.notifications_active), text: 'Notificar'),
              Tab(icon: Icon(Icons.attach_money), text: 'Pagamentos'),
            ],
          ),

      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        children: [
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
          const _AdminNotificationsTab(),
          const _AdminPaymentsTab(),
        ],
      ),
    ));
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
                await Supabase.instance.client
                    .from('matches')
                    .update({
                      if (home != null) 'home_score': home,
                      if (away != null) 'away_score': away,
                      'status': selectedStatus.name,
                    })
                    .eq('id', match.id);

                // ignore: use_build_context_synchronously
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(allMatchesProvider);
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

class _AdminPaymentsTab extends ConsumerStatefulWidget {
  const _AdminPaymentsTab();

  @override
  ConsumerState<_AdminPaymentsTab> createState() => _AdminPaymentsTabState();
}

class _AdminPaymentsTabState extends ConsumerState<_AdminPaymentsTab> {
  String _searchQuery = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(allProfilesProvider);

    return profilesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (profiles) {
        var filtered = profiles.where((p) {
          final isPaid = p['paid'] == true;
          if (_filter == 'paid' && !isPaid) return false;
          if (_filter == 'unpaid' && isPaid) return false;
          
          final name = (p['username'] ?? '').toString().toLowerCase();
          if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
            return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nome',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
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
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Nenhum usuário encontrado.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final profile = filtered[index];
                        final bool isPaid = profile['paid'] == true;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: SwitchListTile(
                            title: Text(
                              profile['username'] ?? 'Sem nome',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(isPaid ? 'Pago' : 'Pendente'),
                            value: isPaid,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: (val) async {
                              try {
                                await Supabase.instance.client
                                    .from('profiles')
                                    .update({'paid': val})
                                    .eq('id', profile['id']);
                                ref.invalidate(allProfilesProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/features/leagues/providers/leagues_provider.dart';
import 'package:copa2026/features/ranking/providers/ranking_provider.dart';
import 'package:copa2026/features/ranking/screens/ranking_screen.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';

class LeaguesScreen extends ConsumerWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final leaguesAsync = ref.watch(myLeaguesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('🛡️  '),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showJoinOrCreateSheet(context, ref),
        label: Text(l.joinOrCreate),
        icon: const Icon(Icons.add),
      ),
      body: leaguesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (leagues) => leagues.isEmpty
            ? _EmptyState(onAdd: () => _showJoinOrCreateSheet(context, ref))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: leagues.length,
                itemBuilder: (_, i) =>
                    _LeagueCard(league: leagues[i]),
              ),
      ),
    );
  }

  void _showJoinOrCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _JoinOrCreateSheet(ref: ref),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// League Card
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LeagueCard extends ConsumerWidget {
  final LeagueModel league;
  const _LeagueCard({required this.league});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(league.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Text(
              '${l.inviteCode}: ',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
            ),
            Text(
              league.inviteCode,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: league.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.codeCopied)),
                );
              },
              child: Icon(Icons.copy, size: 14, color: cs.primary),
            ),
          ],
        ),
        children: [
          _LeagueRankingList(leagueId: league.id),
        ],
      ),
    );
  }
}

class _LeagueRankingList extends ConsumerWidget {
  final String leagueId;
  const _LeagueRankingList({required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankAsync = ref.watch(myLeaguesRankingProvider(leagueId));

    return rankAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(e.toString()),
      data: (entries) => Column(
        children: entries
            .map<Widget>((entry) => RankingTile(entry: entry, isMe: false, l: AppLocalizations.of(context)!))
            .toList(),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Join or Create bottom sheet
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _JoinOrCreateSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _JoinOrCreateSheet({required this.ref});

  @override
  ConsumerState<_JoinOrCreateSheet> createState() => _JoinOrCreateSheetState();
}

class _JoinOrCreateSheetState extends ConsumerState<_JoinOrCreateSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(leagueNotifierProvider.notifier);
    final state = ref.watch(leagueNotifierProvider);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TabBar(
                controller: _tabs,
                tabs: [Tab(text: l.joinLeague), Tab(text: l.createLeague)],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 140,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    Column(
                      children: [
                        TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: l.inviteCode,
                            prefixIcon: const Icon(Icons.key_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: state is AsyncLoading
                              ? null
                              : () async {
                                  await notifier
                                      .joinLeague(_codeCtrl.text.trim());
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: Text(l.joinLeague),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: l.leagueName,
                            prefixIcon: const Icon(Icons.shield_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: state is AsyncLoading
                              ? null
                              : () async {
                                  await notifier
                                      .createLeague(_nameCtrl.text.trim());
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: Text(l.createLeague),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Empty state
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛡️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(l.noLeagues,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(l.noLeaguesSub,
              style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(l.joinOrCreate),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/shared/widgets/flag_avatar.dart';
import 'package:copa2026/features/knockout/providers/champion_pick_provider.dart';

/// Bottom sheet para escolher/alterar o palpite de CAMPEÃO da Copa: lista de
/// seleções com busca; toca → salva e fecha. Aberto só enquanto o palpite estiver
/// liberado (antes do início do mata-mata).
class ChampionPickSheet extends ConsumerStatefulWidget {
  final String? currentTeamId;
  const ChampionPickSheet({super.key, this.currentTeamId});

  @override
  ConsumerState<ChampionPickSheet> createState() => _ChampionPickSheetState();
}

class _ChampionPickSheetState extends ConsumerState<ChampionPickSheet> {
  String _query = '';
  bool _saving = false;

  Future<void> _pick(String teamId) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(championPickActionsProvider).save(teamId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.koSaveError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    // Só as seleções classificadas ao mata-mata.
    final teamsAsync = ref.watch(koQualifiedTeamsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                      color: cs.outline.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2)),
                ),
                Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.koChampionSheetTitle,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l.koChampionSearchHint,
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: teamsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                        child: Text(l.koSaveError(e.toString()),
                            textAlign: TextAlign.center)),
                    data: (teams) {
                      final filtered = _query.isEmpty
                          ? teams
                          : teams
                              .where((t) => t.name.toLowerCase().contains(_query))
                              .toList();
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(l.koChampionNoResults,
                              style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.6))),
                        );
                      }
                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final t = filtered[i];
                          final selected = t.id == widget.currentTeamId;
                          return ListTile(
                            leading: FlagAvatar(flagUrl: t.flagUrl, radius: 16),
                            title: Text(t.name,
                                style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: selected ? cs.primary : null)),
                            trailing: selected
                                ? Icon(Icons.check_circle, color: cs.primary)
                                : null,
                            selected: selected,
                            onTap: _saving ? null : () => _pick(t.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

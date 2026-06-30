import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/features/results/providers/evolution_provider.dart';
import 'package:copa2026/features/results/widgets/evolution_chart.dart';
import 'package:copa2026/features/results/widgets/lineup_field.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';

/// Tela "Resultados" da fase de grupos, com duas abas:
///   • Evolução        → gráfico da posição de cada um ao longo do tempo.
///   • Seleção do Bolão → escalação com os 11 primeiros + técnico (último).
/// Mesmo esqueleto de abas de AdvancedStatsScreen.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text('📈 ${l.resultsMenu}'),
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(evolutionDataProvider),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l.resultsTabSelection),
              Tab(text: l.resultsTabEvolution),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LineupTab(),
            EvolutionTab(),
          ],
        ),
      ),
    );
  }
}

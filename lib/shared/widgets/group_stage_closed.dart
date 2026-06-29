import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';

/// Placeholder "Fase de grupos encerrada". Mostrado na fase knockout para quem
/// NÃO participa do mata-mata (dados de grupos escondidos + sem acesso ao KO),
/// no lugar do conteúdo de Ranking/Ligas. Ver [groupStageClosedProvider].
class GroupStageClosed extends StatelessWidget {
  const GroupStageClosed({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              l.groupStageClosed,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

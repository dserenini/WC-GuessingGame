import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:copa2026/features/knockout/models/knockout_models.dart';

/// Barra de filtro de escopo do mata-mata: "Todos", "Do dia" e um chip por fase
/// presente no chaveamento ([rounds]). Seleção única, no mesmo estilo compacto da
/// [BetFilterBar] da fase de grupos. Usada nas telas de "ver apostas / ver jogos"
/// de um participante (perfil visitante do KO e seleção de jogo do KO).
class KoScopeFilterBar extends StatelessWidget {
  final String scope;
  final List<String> rounds;
  final ValueChanged<String> onScope;

  const KoScopeFilterBar({
    super.key,
    required this.scope,
    required this.rounds,
    required this.onScope,
  });

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
      selected: selected,
      onSelected: (_) => onTap(),
      labelPadding: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        children: [
          _chip(l.filterAll, scope == kKoScopeAll, () => onScope(kKoScopeAll)),
          _chip(l.filterDay, scope == kKoScopeDay, () => onScope(kKoScopeDay)),
          for (final r in rounds)
            _chip(koRoundLabel(l, r), scope == r, () => onScope(r)),
        ],
      ),
    );
  }
}

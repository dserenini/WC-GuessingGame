import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Usuários adicionados à comparação na aba Evolução (além de "Você", que é
/// sempre fixo). LinkedHashSet preserva a ordem de inserção — usada para manter
/// a cor de cada linha estável conforme são adicionados.
class EvolutionSelection extends StateNotifier<Set<String>> {
  EvolutionSelection() : super(<String>{});

  void toggle(String userId) {
    if (state.contains(userId)) {
      state = {...state}..remove(userId);
    } else {
      state = {...state, userId};
    }
  }

  void remove(String userId) => state = {...state}..remove(userId);

  void clear() => state = <String>{};
}

final evolutionSelectionProvider =
    StateNotifierProvider<EvolutionSelection, Set<String>>(
        (ref) => EvolutionSelection());

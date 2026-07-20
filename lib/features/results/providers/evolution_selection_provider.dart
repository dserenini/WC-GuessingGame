import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Escopo da tela Resultados: fase de grupos ou mata-mata. Segrega os dados
/// (views distintas) e a seleção de comparação (KO e grupos não se misturam).
enum EvolutionScope { groups, knockout }

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

/// Family por [EvolutionScope]: cada escopo (grupos / mata-mata) mantém sua
/// própria lista de comparação, independente do outro.
final evolutionSelectionProvider = StateNotifierProvider.family<
    EvolutionSelection, Set<String>, EvolutionScope>((ref, scope) => EvolutionSelection());

import 'package:flutter_test/flutter_test.dart';

import 'package:copa2026/shared/utils/bet_filter.dart';
import 'package:copa2026/shared/utils/bet_points.dart';

void main() {
  group('classifyFilterToken', () {
    test('reconhece placar com hífen', () {
      final r = classifyFilterToken('2-1');
      expect(r.isScore, isTrue);
      expect(r.value, '2-1');
    });

    test('normaliza "x"/"X" e espaços para hífen', () {
      expect(classifyFilterToken('2x1').value, '2-1');
      expect(classifyFilterToken('2X1').value, '2-1');
      expect(classifyFilterToken(' 2 x 1 ').value, '2-1');
      expect(classifyFilterToken('2 x 1').isScore, isTrue);
    });

    test('aceita placares com dois dígitos', () {
      final r = classifyFilterToken('10-12');
      expect(r.isScore, isTrue);
      expect(r.value, '10-12');
    });

    test('trata nome de jogador como termo de usuário (não placar)', () {
      final r = classifyFilterToken('  Danilo ');
      expect(r.isScore, isFalse);
      expect(r.value, 'Danilo'); // apenas trim, preserva o texto
    });

    test('texto que parece placar mas tem letras não vira placar', () {
      expect(classifyFilterToken('2-1a').isScore, isFalse);
      expect(classifyFilterToken('abc').isScore, isFalse);
    });
  });

  group('bucketForPoints', () {
    test('3 pts -> exato (0), 1 pt -> resultado (1), 0 pt -> perdeu (2)', () {
      expect(bucketForPoints(3), 0);
      expect(bucketForPoints(1), 1);
      expect(bucketForPoints(0), 2);
    });
  });

  group('computeBetPoints + bucketForPoints (agrupamento)', () {
    int bucketFor(int hb, int ab, int hr, int ar) => bucketForPoints(
        computeBetPoints(homeBet: hb, awayBet: ab, homeReal: hr, awayReal: ar));

    test('placar exato -> bucket Exato', () {
      expect(bucketFor(2, 1, 2, 1), 0);
    });

    test('mesmo vencedor, placar diferente -> bucket Resultado', () {
      expect(bucketFor(3, 0, 2, 1), 1); // casa vence em ambos
    });

    test('empate previsto e empate real (placar diferente) -> Resultado', () {
      expect(bucketFor(1, 1, 2, 2), 1);
    });

    test('resultado errado -> bucket Perdeu', () {
      expect(bucketFor(0, 1, 2, 1), 2); // previu fora, deu casa
    });
  });
}

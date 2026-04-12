import 'dart:math';

/// Agent of Chaos service â€” generates random scores
class ChaosService {
  static final _rng = Random();

  /// Random score bounded by [max] goals per team
  static (int, int) randomScore({int max = 5}) {
    return (_rng.nextInt(max + 1), _rng.nextInt(max + 1));
  }

  /// Random WIN for the specified side (never equal)
  static (int, int) randomWin({required bool isHome, int max = 5}) {
    int home, away;
    do {
      home = _rng.nextInt(max + 1);
      away = _rng.nextInt(max + 1);
    } while (isHome ? home <= away : away <= home);
    return (home, away);
  }

  /// Random DRAW (home == away)
  static (int, int) randomDraw({int max = 5}) {
    final score = _rng.nextInt(max + 1);
    return (score, score);
  }
}

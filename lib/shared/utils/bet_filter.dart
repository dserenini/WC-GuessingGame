/// Pure helpers for the "view bets" comparison screen (LeagueScorelinesScreen),
/// extracted so the filtering/grouping rules can be unit-tested without a
/// widget tree.

/// Classifies a submitted search term as a scoreline filter or a free username
/// substring.
///
/// A scoreline is two integers separated by `-`, `x` or `X` (spaces ignored),
/// normalized to `home-away` (e.g. "2 x 1" → "2-1"). Anything else is treated
/// as a username substring and returned trimmed, unchanged.
({bool isScore, String value}) classifyFilterToken(String raw) {
  final t = raw.trim();
  final norm = t.replaceAll(RegExp('[xX]'), '-').replaceAll(' ', '');
  final isScore = RegExp(r'^\d+-\d+$').hasMatch(norm);
  return (isScore: isScore, value: isScore ? norm : t);
}

/// Maps the points a scoreline scores against the real result to its display
/// bucket: 0 = exact (3 pts), 1 = correct result (1 pt), 2 = lost/losing (0).
int bucketForPoints(int points) => points == 3 ? 0 : (points == 1 ? 1 : 2);

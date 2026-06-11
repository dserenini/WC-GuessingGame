import 'package:copa2026/core/constants.dart';

/// Computes the points a bet would earn against a given real score.
///
/// Replicates the database scoring rule (see `calculate_bet_points` in
/// supabase/schema.sql): exact score = 3, correct result direction = 1,
/// otherwise 0.
///
/// Used client-side to show **provisional** ("parcial") points while a match is
/// live. For finished matches, prefer the persisted `BetModel.points` (the DB is
/// the source of truth once the final whistle blows).
int computeBetPoints({
  required int homeBet,
  required int awayBet,
  required int homeReal,
  required int awayReal,
}) {
  if (homeBet == homeReal && awayBet == awayReal) return kPointsExactScore;
  if (homeBet > awayBet && homeReal > awayReal) return kPointsCorrectResult;
  if (homeBet < awayBet && homeReal < awayReal) return kPointsCorrectResult;
  if (homeBet == awayBet && homeReal == awayReal) return kPointsCorrectResult;
  return 0;
}

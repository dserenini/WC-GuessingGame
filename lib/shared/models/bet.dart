class BetModel {
  final String id;
  final String userId;
  final String matchId;
  final int homeScoreBet;
  final int awayScoreBet;
  final int points;

  const BetModel({
    required this.id,
    required this.userId,
    required this.matchId,
    required this.homeScoreBet,
    required this.awayScoreBet,
    required this.points,
  });

  factory BetModel.fromJson(Map<String, dynamic> json) => BetModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        matchId: json['match_id'] as String,
        homeScoreBet: json['home_score_bet'] as int,
        awayScoreBet: json['away_score_bet'] as int,
        points: json['points'] as int,
      );

  BetModel copyWith({int? homeScoreBet, int? awayScoreBet}) => BetModel(
        id: id,
        userId: userId,
        matchId: matchId,
        homeScoreBet: homeScoreBet ?? this.homeScoreBet,
        awayScoreBet: awayScoreBet ?? this.awayScoreBet,
        points: points,
      );
}

class RankingEntry {
  final String userId;
  final String username;
  final String? fullName;
  final String displayPreference;
  final String? avatarUrl;
  final int totalPoints;
  final int totalBets;
  final int rank;

  const RankingEntry({
    required this.userId,
    required this.username,
    this.fullName,
    required this.displayPreference,
    this.avatarUrl,
    required this.totalPoints,
    required this.totalBets,
    required this.rank,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) => RankingEntry(
        userId: json['user_id'] as String,
        username: json['username'] as String,
        fullName: json['full_name'] as String?,
        displayPreference: json['display_preference'] as String? ?? 'username',
        avatarUrl: json['avatar_url'] as String?,
        totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
        totalBets: (json['total_bets'] as num?)?.toInt() ?? 0,
        rank: (json['rank'] as num?)?.toInt() ?? 0,
      );

  RankingEntry copyWith({int? rank}) => RankingEntry(
        userId: userId,
        username: username,
        fullName: fullName,
        displayPreference: displayPreference,
        avatarUrl: avatarUrl,
        totalPoints: totalPoints,
        totalBets: totalBets,
        rank: rank ?? this.rank,
      );
  
  String get displayName {
    if (displayPreference == 'full_name' && fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    return username;
  }
}

class LeagueModel {
  final String id;
  final String name;
  final String inviteCode;
  final String ownerId;

  const LeagueModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
  });

  factory LeagueModel.fromJson(Map<String, dynamic> json) => LeagueModel(
        id: json['id'] as String,
        name: json['name'] as String,
        inviteCode: json['invite_code'] as String,
        ownerId: json['owner_id'] as String,
      );
}

import 'package:copa2026/shared/models/team.dart';

enum MatchStatus { scheduled, live, finished }

class MatchModel {
  final String id;
  final String groupLetter;
  final TeamModel homeTeam;
  final TeamModel awayTeam;
  final DateTime? matchDate;
  final int? homeScore;
  final int? awayScore;
  final MatchStatus status;
  final String? apiMatchId;

  const MatchModel({
    required this.id,
    required this.groupLetter,
    required this.homeTeam,
    required this.awayTeam,
    this.matchDate,
    this.homeScore,
    this.awayScore,
    required this.status,
    this.apiMatchId,
  });

  bool get isLocked =>
      status == MatchStatus.live || status == MatchStatus.finished;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      groupLetter: json['group_letter'] as String,
      homeTeam: TeamModel.fromJson(json['home_team'] as Map<String, dynamic>),
      awayTeam: TeamModel.fromJson(json['away_team'] as Map<String, dynamic>),
      matchDate: json['match_date'] != null
          ? DateTime.parse(json['match_date'] as String)
          : null,
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      status: MatchStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MatchStatus.scheduled,
      ),
      apiMatchId: json['api_match_id'] as String?,
    );
  }
}

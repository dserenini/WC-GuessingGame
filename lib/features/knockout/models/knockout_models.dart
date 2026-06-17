import 'package:copa2026/shared/models/team.dart';
import 'package:copa2026/shared/models/match.dart' show MatchStatus;

// ─────────────────────────────────────────────────────────────────────────────
// MATA-MATA — modelos
// ─────────────────────────────────────────────────────────────────────────────

/// Ordem e rótulos das rodadas do mata-mata.
const List<String> kKoRounds = [
  '16avos', 'oitavas', 'quartas', 'semis', '3lugar', 'final',
];

String koRoundLabel(String round) {
  switch (round) {
    case '16avos':
      return '16-avos';
    case 'oitavas':
      return 'Oitavas';
    case 'quartas':
      return 'Quartas';
    case 'semis':
      return 'Semifinais';
    case 'final':
      return 'Final';
    case '3lugar':
      return 'Disputa de 3º';
    default:
      return round;
  }
}

/// Um jogo do mata-mata (com a árvore do chaveamento via slot/round).
class KoMatch {
  final String id;
  final String round;
  final int slot;
  final TeamModel? home;
  final TeamModel? away;
  final TeamModel? advancing;
  final DateTime? matchDate;
  final int? homeScore;
  final int? awayScore;
  final int? homePens;
  final int? awayPens;
  final MatchStatus status;
  final int? apiFixtureId;

  const KoMatch({
    required this.id,
    required this.round,
    required this.slot,
    this.home,
    this.away,
    this.advancing,
    this.matchDate,
    this.homeScore,
    this.awayScore,
    this.homePens,
    this.awayPens,
    required this.status,
    this.apiFixtureId,
  });

  /// Identificador curto para exibição (#ID), igual ao padrão da fase de grupos.
  String get shortId => apiFixtureId?.toString() ?? id.substring(0, 4);

  bool get teamsKnown => home != null && away != null;
  bool get isFinished => status == MatchStatus.finished;

  static TeamModel? _team(dynamic v) =>
      v == null ? null : TeamModel.fromJson((v as Map).cast<String, dynamic>());

  factory KoMatch.fromJson(Map<String, dynamic> j) => KoMatch(
        id: j['id'] as String,
        round: j['round'] as String,
        slot: (j['slot'] as num).toInt(),
        home: _team(j['home']),
        away: _team(j['away']),
        advancing: _team(j['advancing']),
        matchDate: j['match_date'] != null
            ? DateTime.parse(j['match_date'] as String)
            : null,
        homeScore: j['home_score'] as int?,
        awayScore: j['away_score'] as int?,
        homePens: j['home_pens'] as int?,
        awayPens: j['away_pens'] as int?,
        status: MatchStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => MatchStatus.scheduled,
        ),
        apiFixtureId: (j['api_fixture_id'] as num?)?.toInt(),
      );
}

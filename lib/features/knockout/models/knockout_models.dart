import 'package:copa2026/l10n/app_localizations.dart';
import 'package:copa2026/shared/models/team.dart';
import 'package:copa2026/shared/models/match.dart' show MatchStatus;

// ─────────────────────────────────────────────────────────────────────────────
// MATA-MATA — modelos
// ─────────────────────────────────────────────────────────────────────────────

/// Ordem e rótulos das rodadas do mata-mata.
const List<String> kKoRounds = [
  '16avos', 'oitavas', 'quartas', 'semis', '3lugar', 'final',
];

String koRoundLabel(AppLocalizations l, String round) {
  switch (round) {
    case '16avos':
      return l.koRound16avos;
    case 'oitavas':
      return l.koRoundOitavas;
    case 'quartas':
      return l.koRoundQuartas;
    case 'semis':
      return l.koRoundSemis;
    case 'final':
      return l.koRoundFinal;
    case '3lugar':
      return l.koRound3lugar;
    default:
      return round;
  }
}

/// Semifinal e Final pontuam em dobro? Reforço de pontuação só nessas duas fases
/// (a disputa de 3º NÃO entra). Fonte única para cliente — espelha `score_ko_match`.
bool koIsFinalsRound(String round) => round == 'semis' || round == 'final';

/// Pontos de um palpite de placar do mata-mata por fase. Espelha o trigger SQL
/// `score_ko_match()`: cravada=5 / resultado=3 na Semi/Final; 3 / 1 nas demais.
int koBetPoints(String round, int betHome, int betAway, int realHome, int realAway) {
  final finals = koIsFinalsRound(round);
  if (betHome == realHome && betAway == realAway) return finals ? 5 : 3;
  final betDir = betHome.compareTo(betAway);
  final realDir = realHome.compareTo(realAway);
  if (betDir == realDir) return finals ? 3 : 1;
  return 0;
}

/// O palpite de KO de um jogo já pode ser REVELADO aos outros? Mesmo critério do
/// fechamento da aposta: 30 min antes do jogo, ao vivo ou encerrado. Espelha a
/// RLS `ko_bet_read` (supabase/ko_bet_reveal_30min.sql) — antes disso o palpite
/// alheio fica oculto para evitar cópia.
bool koMatchRevealed(KoMatch m) {
  if (m.status == MatchStatus.finished || m.status == MatchStatus.live) {
    return true;
  }
  final d = m.matchDate;
  if (d == null) return false;
  return DateTime.now()
      .toUtc()
      .isAfter(d.toUtc().subtract(const Duration(minutes: 30)));
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

  /// Nº oficial do jogo na tabela da FIFA (73–104).
  final int? matchNo;

  /// Rótulo do confronto quando o time ainda não está definido
  /// (ex.: "1º E", "3º A/B/C/D/F", "Venc. Jogo 74").
  final String? homeSlotLabel;
  final String? awaySlotLabel;

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
    this.matchNo,
    this.homeSlotLabel,
    this.awaySlotLabel,
  });

  /// Identificador curto para exibição (#ID), igual ao padrão da fase de grupos.
  String get shortId => apiFixtureId?.toString() ?? id.substring(0, 4);

  /// Nº do jogo para exibir no card ("Jogo 73"); cai no #ID se não houver.
  String get gameNoLabel => matchNo != null ? 'Jogo $matchNo' : '#$shortId';

  /// Texto do lado da casa/visitante: time real ou, se indefinido, o rótulo
  /// do confronto ("1º E", "Venc. Jogo 74"). Usado fora da árvore (lista/folha),
  /// onde não há animação de revelação.
  String get homeText => home?.name ?? homeSlotLabel ?? 'A definir';
  String get awayText => away?.name ?? awaySlotLabel ?? 'A definir';

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
        matchNo: (j['match_no'] as num?)?.toInt(),
        homeSlotLabel: j['home_slot_label'] as String?,
        awaySlotLabel: j['away_slot_label'] as String?,
      );
}

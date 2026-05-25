// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginSubtitle => 'Bet on the group stage with your friends';

  @override
  String get login => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get username => 'Username';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get yes => 'Yes, I\'m serious!';

  @override
  String get save => 'Save';

  @override
  String get group => 'Group';

  @override
  String get groups => 'GROUPS';

  @override
  String get ranking => 'Ranking';

  @override
  String get privateLeagues => 'Private Leagues';

  @override
  String get settings => 'Settings';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get signOut => 'Sign Out';

  @override
  String get betsLocked => 'Bets closed — deadline has passed';

  @override
  String get betsOpen => 'Bets are open';

  @override
  String get betDeadline => 'Bet Deadline';

  @override
  String get result => 'Result';

  @override
  String get agentOfChaos => 'Agent of Chaos';

  @override
  String get chaosRandomAll => 'Randomize all';

  @override
  String get chaosRandomAllSub => 'Fills empty scores with random picks';

  @override
  String get chaosGuidedHint =>
      'Tap a flag for a random win. Tap \'X\' for a random draw.';

  @override
  String get chaosMaxGoals => 'Max goals per team';

  @override
  String get wackyGoalAlert =>
      'You\'re picking more than 20 goals... Are you serious? 😱';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get account => 'Account';

  @override
  String get joinLeague => 'Join league';

  @override
  String get createLeague => 'Create league';

  @override
  String get joinOrCreate => 'Join or create';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get leagueName => 'League name';

  @override
  String get noLeagues => 'No leagues yet';

  @override
  String get noLeaguesSub =>
      'Join a league with an invite code or create your own';

  @override
  String get codeCopied => 'Code copied!';

  @override
  String get myProfile => 'My Profile';

  @override
  String get betsFilled => 'Bets Filled';

  @override
  String get totalPoints => 'Total Points';

  @override
  String get exactHits => 'Exact Score';

  @override
  String get resultHits => 'Correct Result';

  @override
  String get superPalpites => 'Super Bets';

  @override
  String superPalpitesRemaining(int count) {
    return 'You have $count edits left after the deadline.';
  }

  @override
  String get forgotPassword => 'Forgot my password';

  @override
  String get recoverPassword => 'Recover Password';

  @override
  String get recoverPasswordHint =>
      'Enter your email to receive a recovery link.';

  @override
  String get recoveryLinkSent => 'Recovery link sent! Check your email.';

  @override
  String get send => 'Send';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get invalidLogin => 'Invalid login/password.';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get continueBtn => 'Continue';

  @override
  String get advancedStats => 'Advanced Stats';

  @override
  String get advancedStatsSub => 'By group, round, team — coming soon!';

  @override
  String get deleteBet => 'Delete Bet';

  @override
  String get deleteBetConfirm =>
      'Do you want to delete your bet for this match?';

  @override
  String get delete => 'Delete';

  @override
  String get helpAndRules => 'Help / Rules';

  @override
  String get helpScoring => 'Scoring';

  @override
  String get helpScoringDesc =>
      'You get 3 points for the exact score. If you miss the score but guess the winner (or a draw), you get 1 point.';

  @override
  String get helpDeadlines => 'Bet Deadlines';

  @override
  String helpDeadlinesDesc(String date, String gmt) {
    return 'All bets must be made by $date at $gmt. After this date, bets can only be changed using a Super Bet.';
  }

  @override
  String get helpSuperPalpites => 'Super Bets';

  @override
  String get helpSuperPalpitesDesc =>
      'After the global lock, you have a limited amount of emergency edits called Super Bets. For a given match, a Super Bet must be used up to 1 hour before the match starts, after which it cannot be changed.';

  @override
  String get helpAgentOfChaosTitle => 'Agent of Chaos 🎲';

  @override
  String get helpAgentOfChaosDesc =>
      'The Agent of Chaos has 2 modes: fill all bets for you randomly, or fill the bets based on the final standings you indicate. The maximum goal limit is configured in the settings section.';

  @override
  String get helpEasyBetTitle => 'Easy Bet ⚡';

  @override
  String get helpEasyBetDesc =>
      'While the Easy Bet toggle is active, you can bet just by clicking the flags (or the center \'X\') and the Agent of Chaos will automatically set the score. The maximum goal limit is configured in the settings section.';

  @override
  String get easyBet => 'Easy Bet';

  @override
  String get helpLeaguesTitle => 'Private Leagues';

  @override
  String get helpLeaguesDesc =>
      'Create or join private leagues using an invite code to compete against your friends.';

  @override
  String get appTitle => 'Make Bolão Great Again';

  @override
  String exportError(String error) {
    return 'Error capturing image: $error';
  }

  @override
  String get exportStarted => 'Download started! Check your downloads folder.';

  @override
  String get exportBets => 'Export Bets';

  @override
  String get downloadImage => 'Download Image';

  @override
  String get shareWhatsApp => 'Share on WhatsApp';

  @override
  String get settingsSaved => 'Settings saved successfully!';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesDesc => 'Unsaved changes will be lost.';

  @override
  String get no => 'No';

  @override
  String get yesDiscard => 'Yes, discard';

  @override
  String get currentTimeZone => 'Current Time Zone';

  @override
  String get exportMyBets => 'Export my bets';

  @override
  String get exportMyBetsSub => 'Generate an image to save or share!';

  @override
  String exportBetsOf(String userName) {
    return '$userName\'s bets';
  }

  @override
  String exportGroupTitle(String group) {
    return 'GROUP $group';
  }

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get waitDataLoad => 'Please wait for data to load...';

  @override
  String get changePassword => 'Change Password';

  @override
  String get passwordMinLength => 'Password must have at least 6 characters.';

  @override
  String get passwordsMismatch => 'Passwords do not match.';

  @override
  String get passwordUpdated => 'Password updated successfully!';

  @override
  String get portuguese => 'Português';

  @override
  String get english => 'English';

  @override
  String get italian => 'Italiano';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications.';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get close => 'Close';

  @override
  String get followStandings => 'Follow Standings';

  @override
  String get followStandingsSub =>
      'Choose the final order and we generate the scores for you';

  @override
  String get desiredStandings => 'Desired Standings';

  @override
  String get dragTeams =>
      'Drag the teams to the exact order you want to see them finish in the table.';

  @override
  String get generateChaos => 'Generate Chaos';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get deleteGroupConfirm =>
      'Are you sure you want to delete all bets for this group?';

  @override
  String get deleteAllBets => 'Delete all bets';

  @override
  String rankingBetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bets',
      one: '1 bet',
    );
    return '$_temp0';
  }

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusLive => 'Live 🔴';

  @override
  String get statusFinished => 'Finished';

  @override
  String get teamMexico => 'Mexico';

  @override
  String get teamSouthAfrica => 'South Africa';

  @override
  String get teamSouthKorea => 'South Korea';

  @override
  String get teamCzechia => 'Czechia';

  @override
  String get teamCanada => 'Canada';

  @override
  String get teamSwitzerland => 'Switzerland';

  @override
  String get teamQatar => 'Qatar';

  @override
  String get teamBosniaAndHerzegovina => 'Bosnia and Herzegovina';

  @override
  String get teamBrazil => 'Brazil';

  @override
  String get teamMorocco => 'Morocco';

  @override
  String get teamHaiti => 'Haiti';

  @override
  String get teamScotland => 'Scotland';

  @override
  String get teamUnitedStates => 'United States';

  @override
  String get teamParaguay => 'Paraguay';

  @override
  String get teamAustralia => 'Australia';

  @override
  String get teamTurkiye => 'Türkiye';

  @override
  String get teamGermany => 'Germany';

  @override
  String get teamCuracao => 'Curaçao';

  @override
  String get teamIvoryCoast => 'Ivory Coast';

  @override
  String get teamEcuador => 'Ecuador';

  @override
  String get teamNetherlands => 'Netherlands';

  @override
  String get teamJapan => 'Japan';

  @override
  String get teamSweden => 'Sweden';

  @override
  String get teamTunisia => 'Tunisia';

  @override
  String get teamBelgium => 'Belgium';

  @override
  String get teamEgypt => 'Egypt';

  @override
  String get teamIRIran => 'IR Iran';

  @override
  String get teamNewZealand => 'New Zealand';

  @override
  String get teamSpain => 'Spain';

  @override
  String get teamCaboVerde => 'Cabo Verde';

  @override
  String get teamSaudiArabia => 'Saudi Arabia';

  @override
  String get teamUruguay => 'Uruguay';

  @override
  String get teamFrance => 'France';

  @override
  String get teamSenegal => 'Senegal';

  @override
  String get teamIraq => 'Iraq';

  @override
  String get teamNorway => 'Norway';

  @override
  String get teamArgentina => 'Argentina';

  @override
  String get teamAlgeria => 'Algeria';

  @override
  String get teamAustria => 'Austria';

  @override
  String get teamJordan => 'Jordan';

  @override
  String get teamPortugal => 'Portugal';

  @override
  String get teamDRCongo => 'DR Congo';

  @override
  String get teamUzbekistan => 'Uzbekistan';

  @override
  String get teamColombia => 'Colombia';

  @override
  String get teamEngland => 'England';

  @override
  String get teamCroatia => 'Croatia';

  @override
  String get teamGhana => 'Ghana';

  @override
  String get teamPanama => 'Panama';
}

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
  String get appTitle => 'Make Bolão Great Again';
}

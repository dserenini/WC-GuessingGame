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
  String get regularDeadlineClosed => 'Regular deadline closed';

  @override
  String get betsUseSuperPalpite => 'New bets now spend Super Palpites';

  @override
  String get superPalpitesExhausted =>
      'Super Palpites used up — betting locked';

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
  String get advancedStatsSub => 'See how you stack up against the pool';

  @override
  String get statsTabRankings => 'Rankings';

  @override
  String get statsTabPersonal => 'Personal';

  @override
  String get statsTabAchievements => 'Achievements';

  @override
  String get statsTabPool => 'Pool';

  @override
  String get statExactTitle => 'Exact Score King';

  @override
  String get statExactSub => 'Who nailed the most exact scores';

  @override
  String get statExactUnit => 'exact';

  @override
  String get statBrazilTitle => 'Brazil\'s Lucky Charm';

  @override
  String get statBrazilSub => 'Who scored the most on Brazil\'s matches';

  @override
  String get statNearMissTitle => 'So Close';

  @override
  String get statNearMissSub => 'Got the result but missed the score by 1 goal';

  @override
  String get statNearMissUnit => 'near';

  @override
  String get statDailyTitle => 'Best Day';

  @override
  String get statDailySub => 'Highest points in a single day';

  @override
  String get statRegularTitle => 'Most Consistent';

  @override
  String get statRegularSub => 'Scored in the most matches';

  @override
  String get statRegularUnit => 'games';

  @override
  String get statBoldTitle => 'The Bold Ones';

  @override
  String get statBoldSub => 'Who bets the riskiest scorelines';

  @override
  String get statBoldUnit => 'bold';

  @override
  String get statContrarianTitle => 'Right Against the Crowd';

  @override
  String get statContrarianSub => 'Nailed scores almost nobody picked';

  @override
  String get statContrarianUnit => 'rare';

  @override
  String get statsNoGames => 'No games for this stat yet';

  @override
  String get statsPersonalEmpty => 'Your numbers show up as the games happen';

  @override
  String get statGroupPointsTitle => 'Points by Group';

  @override
  String get statGroupPointsSub => 'Where you scored most and least';

  @override
  String get statDistributionTitle => 'Hit Breakdown';

  @override
  String get statDistributionSub => 'Exact, result and misses';

  @override
  String get statDistResult => 'results';

  @override
  String get statDistZero => 'misses';

  @override
  String get statUtilization => 'Efficiency';

  @override
  String get statSignatureTitle => 'Signature Score';

  @override
  String get statSignatureSub => 'The scoreline you bet most';

  @override
  String get statHandTitle => 'Goal Average';

  @override
  String get statHandSub => 'Your goals per game vs. the real average';

  @override
  String get statHandReal => 'Real';

  @override
  String get statGoalsPerGame => 'goals/game';

  @override
  String get statLuckyTitle => 'Lucky / Unlucky Charm';

  @override
  String get statLuckySub => 'Teams where you score most and least';

  @override
  String get statLucky => 'Lucky';

  @override
  String get statUnlucky => 'Unlucky';

  @override
  String get statStreakTitle => 'Longest Streak';

  @override
  String get statStreakSub => 'Consecutive games scoring';

  @override
  String get statBest => 'Best';

  @override
  String get statWorst => 'Worst';

  @override
  String get statBestPlural => 'Best';

  @override
  String get statWorstPlural => 'Worst';

  @override
  String get poolUnpredictableTitle => 'Most unpredictable games';

  @override
  String get poolUnpredictableSub => 'Where the fewest nailed the score';

  @override
  String get poolEveryoneKnewTitle => 'Everyone saw it coming';

  @override
  String get poolEveryoneKnewSub => 'Where the most nailed the score';

  @override
  String get poolPopularTitle => 'Most popular picks';

  @override
  String get poolPopularSub => 'The pool\'s most-bet scorelines';

  @override
  String get poolUniqueTitle => 'Unique picks';

  @override
  String get poolUniqueSub => 'The pool\'s rarest scorelines';

  @override
  String get poolNailedLabel => 'nailed it';

  @override
  String get poolWhoNailed => 'Who nailed it';

  @override
  String get poolNobodyNailed => 'Nobody nailed this game';

  @override
  String get poolLookupTitle => 'Look up a scoreline';

  @override
  String get poolLookupHint => 'e.g. 1-1';

  @override
  String get poolLookupNotFound => 'No picks with that scoreline';

  @override
  String get achBronze => 'Bronze';

  @override
  String get achPrata => 'Silver';

  @override
  String get achOuro => 'Gold';

  @override
  String get achRarityOf => 'of players';

  @override
  String get achUnlocked => 'Unlocked';

  @override
  String get achUnlockedOn => 'Unlocked on';

  @override
  String get achViewGames => 'View the games';

  @override
  String get achExactTitle => 'Exact Scores';

  @override
  String get achExactDesc => 'Nail exact scorelines';

  @override
  String get achEmpateName => 'Knew the Draw';

  @override
  String get achEmpateDesc => 'Nail a draw';

  @override
  String get achOusadiaName => 'Living Dangerously';

  @override
  String get achOusadiaDesc => 'Nail a bold pick (5+ goal gap or 7+ goals)';

  @override
  String get achEmbaladoName => 'On Fire';

  @override
  String get achEmbaladoDesc => 'Score in several games in a row';

  @override
  String get achPequenteName => 'Red Hot';

  @override
  String get achPequenteDesc => 'Score in 5 games in a row';

  @override
  String get achDiaCheioName => 'Full Day';

  @override
  String get achDiaCheioDesc => 'Score in every game of a day (with 3+ games)';

  @override
  String get achVoltaName => 'Around the World';

  @override
  String get achVoltaDesc => 'Score in every group';

  @override
  String get achDonoName => 'Group Boss';

  @override
  String get achDonoDesc => 'Get 6+ points in a group';

  @override
  String get achBrasilName => 'Green & Yellow Heart';

  @override
  String get achBrasilDesc => 'Score in a Brazil game';

  @override
  String get achProfetaName => 'Prophet';

  @override
  String get achProfetaDesc => 'Nail a scoreline fewer than 10% nailed';

  @override
  String get achPanelaName => 'Welcome Aboard';

  @override
  String get achPanelaDesc => 'Join a league';

  @override
  String get achMeioSeculoName => 'Raining Points';

  @override
  String get achMeioSeculoDesc => 'Reach 50 total points';

  @override
  String get achQuaseName => 'So Close';

  @override
  String get achQuaseDesc => 'Rack up 5 near-misses (off by 1 goal)';

  @override
  String get achNewUnlocked => 'New achievement!';

  @override
  String get achNice => 'Nice!';

  @override
  String get achViewAchievement => 'View achievement';

  @override
  String get achClose => 'Close';

  @override
  String get statPointsUnit => 'pts';

  @override
  String get statsYou => 'You';

  @override
  String get statsSeeAll => 'See all';

  @override
  String get statsSeeMore => 'See more';

  @override
  String get statsSeeLess => 'See less';

  @override
  String get statsComingSoon => 'Coming soon to this tab!';

  @override
  String get statsEmpty => 'Not enough data yet';

  @override
  String get statsError => 'Couldn\'t load';

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
  String get nextMatch => 'Next Match';

  @override
  String get matchesOfDay => 'Matches of the day';

  @override
  String get yourPrediction => 'Your prediction';

  @override
  String get makeYourPrediction => 'Make your prediction';

  @override
  String get previousGroup => 'Previous group';

  @override
  String get nextGroup => 'Next group';

  @override
  String get searchPlayer => 'Search player...';

  @override
  String get youLabel => 'You';

  @override
  String get exportRanking => 'Export ranking';

  @override
  String exportRankingOf(String leagueName) {
    return '$leagueName ranking';
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
  String get noNotifications => 'No notifications';

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

  @override
  String get paymentPixTitle => 'For Brazilian users, payment via Pix.';

  @override
  String get paymentPixKey => 'Key: pix@example.com';

  @override
  String get paymentPixScan => 'Or scan the QR Code below';

  @override
  String get paymentIbanTitle =>
      'For European users, payment via bank transfer';

  @override
  String get paymentIbanKey => 'IBAN: IT93W0364601600526228392905';

  @override
  String get copiedToClipboard => 'Copied to clipboard!';

  @override
  String get paymentPixAmount => 'Amount: R\$ 20.00';

  @override
  String get paymentIbanAmount => 'Amount: € 5.00';

  @override
  String get firstName => 'Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get displayAs => 'Display in ranking as:';

  @override
  String get displayAsUsername => 'Username';

  @override
  String get displayAsFullName => 'Full Name';

  @override
  String get completeProfileTitle => 'Complete your Profile';

  @override
  String get completeProfileDesc =>
      'We need your name to make it easier to identify you in payments and rankings.';

  @override
  String get nameRequired => 'Please fill in your name and last name';

  @override
  String get phoneLabel => 'Phone / WhatsApp';

  @override
  String get phoneRequired => 'Please enter your phone number';

  @override
  String get phoneInvalidBr =>
      'Invalid phone. Use area code + number (11 digits).';

  @override
  String get editProfile => 'Update Personal Data';

  @override
  String get leaveLeague => 'Leave league';

  @override
  String get leaveLeagueConfirm =>
      'Are you sure you want to leave this league?';

  @override
  String get paymentPending => 'Payment Pending';

  @override
  String get paymentRealized => 'Payment Completed';

  @override
  String get adminTabMatches => 'Matches';

  @override
  String get adminTabUsers => 'Users';

  @override
  String get exportData => 'Export CSV';

  @override
  String get searchUsers => 'Search by username, email or name...';

  @override
  String get visitorMode => 'visitor';

  @override
  String get yourBet => 'You';

  @override
  String get partial => 'partial';

  @override
  String get liveNow => 'LIVE';

  @override
  String get finalLabel => 'FINAL';

  @override
  String get versusShort => 'vs';

  @override
  String get hiddenUntilKickoff => 'Hidden until kickoff';

  @override
  String get completeBetsToView => 'Complete your bets to see others\'';

  @override
  String get completeBetsToViewSub =>
      'You must place at least 65 of your bets before you can view the other participants\' predictions.';

  @override
  String rankPositionShort(int rank) {
    return '${rank}th place';
  }

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get errConnection =>
      'No connection. Check your internet and try again.';

  @override
  String get errAuth =>
      'Authentication failed. Check your credentials and try again.';

  @override
  String get errBetMatchStarted =>
      'This match already started or ended — you can\'t change the bet.';

  @override
  String get errBetDeadlinePassed =>
      'The deadline to change this bet has passed (less than 1 hour to kickoff).';

  @override
  String get errSuperPalpiteLimit => 'You\'ve already used all 10 Super Bets.';

  @override
  String get errSyncFailed =>
      'Couldn\'t sync the spreadsheet. Check your connection and try again.';

  @override
  String get filterAll => 'All';

  @override
  String get filterRound1 => 'Round 1';

  @override
  String get filterRound2 => 'Round 2';

  @override
  String get filterRound3 => 'Round 3';

  @override
  String get filterDay => 'Today';

  @override
  String get filterFinished => 'Finished';

  @override
  String get filterUnfinished => 'Not finished';

  @override
  String get filterExact => 'Exact score';

  @override
  String get filterResult => 'Result';

  @override
  String get filterLost => 'Missed';

  @override
  String get filterNoGames => 'No games match these filters';
}

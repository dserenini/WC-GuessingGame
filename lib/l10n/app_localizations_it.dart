// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get loginSubtitle => 'Scommetti sulla fase a gironi con gli amici';

  @override
  String get login => 'Accedi';

  @override
  String get signUp => 'Registrati';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get username => 'Nome utente';

  @override
  String get confirm => 'Conferma';

  @override
  String get cancel => 'Annulla';

  @override
  String get yes => 'Sì, ci credo!';

  @override
  String get save => 'Salva';

  @override
  String get group => 'Gruppo';

  @override
  String get groups => 'GRUPPI';

  @override
  String get ranking => 'Classifica';

  @override
  String get privateLeagues => 'Leghe Private';

  @override
  String get settings => 'Impostazioni';

  @override
  String get adminPanel => 'Pannello Admin';

  @override
  String get signOut => 'Esci';

  @override
  String get betsLocked => 'Scommesse chiuse — scadenza superata';

  @override
  String get betsOpen => 'Scommesse aperte';

  @override
  String get betDeadline => 'Scadenza Scommesse';

  @override
  String get result => 'Risultato';

  @override
  String get agentOfChaos => 'Agente del Caos';

  @override
  String get chaosRandomAll => 'Randomizza tutto';

  @override
  String get chaosRandomAllSub => 'Riempie i punteggi vuoti casualmente';

  @override
  String get chaosGuidedHint =>
      'Tocca la bandiera per una vittoria casuale. Tocca \'X\' per un pareggio casuale.';

  @override
  String get chaosMaxGoals => 'Massimo gol per squadra';

  @override
  String get wackyGoalAlert =>
      'Stai mettendo più di 20 gol... Fa sul serio? 😱';

  @override
  String get appearance => 'Aspetto';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get language => 'Lingua';

  @override
  String get account => 'Account';

  @override
  String get joinLeague => 'Entra in una lega';

  @override
  String get createLeague => 'Crea lega';

  @override
  String get joinOrCreate => 'Entra o crea';

  @override
  String get inviteCode => 'Codice invito';

  @override
  String get leagueName => 'Nome della lega';

  @override
  String get noLeagues => 'Nessuna lega ancora';

  @override
  String get noLeaguesSub => 'Entra in una lega con un codice o creane una tua';

  @override
  String get codeCopied => 'Codice copiato!';

  @override
  String get myProfile => 'Il mio Profilo';

  @override
  String get betsFilled => 'Scommesse Compilate';

  @override
  String get totalPoints => 'Punti Totali';

  @override
  String get exactHits => 'Punteggio Esatto';

  @override
  String get resultHits => 'Risultato Corretto';

  @override
  String get superPalpites => 'Super Scommessa';

  @override
  String superPalpitesRemaining(int count) {
    return 'Hai $count modifiche rimaste dopo la scadenza.';
  }

  @override
  String get forgotPassword => 'Ho dimenticato la password';

  @override
  String get recoverPassword => 'Recupera Password';

  @override
  String get recoverPasswordHint =>
      'Inserisci la tua email per ricevere un link di recupero.';

  @override
  String get recoveryLinkSent =>
      'Link di recupero inviato! Controlla la tua email.';

  @override
  String get send => 'Invia';

  @override
  String errorGeneric(String error) {
    return 'Errore: $error';
  }

  @override
  String get invalidLogin => 'Login/Password errati.';

  @override
  String get chooseLanguage => 'Scegli la tua lingua';

  @override
  String get continueBtn => 'Continua';

  @override
  String get advancedStats => 'Statistiche Avanzate';

  @override
  String get advancedStatsSub => 'Per gruppo, turno, squadra — in arrivo!';

  @override
  String get deleteBet => 'Elimina Scommessa';

  @override
  String get deleteBetConfirm =>
      'Vuoi eliminare la tua scommessa per questa partita?';

  @override
  String get delete => 'Elimina';

  @override
  String get appTitle => 'Make Bolão Great Again';
}

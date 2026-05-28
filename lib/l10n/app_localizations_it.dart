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
  String get helpAndRules => 'Aiuto / Regole';

  @override
  String get helpScoring => 'Punteggio';

  @override
  String get helpScoringDesc =>
      'Ottieni 3 punti per il risultato esatto. Se sbagli il punteggio ma indovini il vincitore (o il pareggio), ottieni 1 punto.';

  @override
  String get helpDeadlines => 'Scadenze Scommesse';

  @override
  String helpDeadlinesDesc(String date, String gmt) {
    return 'Tutte le scommesse devono essere effettuate entro il $date nel fuso orario $gmt. Dopo questa data, sarà possibile modificare una scommessa solo utilizzando una Super Scommessa.';
  }

  @override
  String get helpSuperPalpites => 'Super Scommesse';

  @override
  String get helpSuperPalpitesDesc =>
      'Dopo il blocco globale, hai un numero limitato di modifiche di emergenza chiamate Super Scommesse. Per una determinata partita, una Super Scommessa deve essere utilizzata fino a 1 ora prima dell\'inizio della partita, dopodiché non potrà più essere modificata.';

  @override
  String get helpAgentOfChaosTitle => 'Agente del Caos 🎲';

  @override
  String get helpAgentOfChaosDesc =>
      'L\'Agente del Caos ha 2 modalità: riempire tutte le scommesse in modo casuale, oppure riempirle in base alla classifica finale da te indicata. Il limite massimo di gol è configurato nella sezione Impostazioni.';

  @override
  String get helpEasyBetTitle => 'Scommessa Facile ⚡';

  @override
  String get helpEasyBetDesc =>
      'Mentre il pulsante Scommessa Facile è attivo, puoi scommettere semplicemente cliccando sulle bandiere (o sulla \'X\' centrale) e l\'Agente del Caos imposterà automaticamente il punteggio. Il limite massimo di gol è configurato nella sezione Impostazioni.';

  @override
  String get easyBet => 'Scommessa Facile';

  @override
  String get helpLeaguesTitle => 'Leghe Private';

  @override
  String get helpLeaguesDesc =>
      'Crea o unisciti a leghe private utilizzando un codice di invito per competere contro i tuoi amici.';

  @override
  String get appTitle => 'Make Bolão Great Again';

  @override
  String exportError(String error) {
    return 'Errore durante l\'acquisizione dell\'immagine: $error';
  }

  @override
  String get exportStarted =>
      'Download avviato! Controlla la cartella dei download.';

  @override
  String get exportBets => 'Esporta Scommesse';

  @override
  String get downloadImage => 'Scarica Immagine';

  @override
  String get shareWhatsApp => 'Condividi su WhatsApp';

  @override
  String get settingsSaved => 'Impostazioni salvate con successo!';

  @override
  String get discardChangesTitle => 'Scartare le modifiche?';

  @override
  String get discardChangesDesc => 'Le modifiche non salvate andranno perse.';

  @override
  String get no => 'No';

  @override
  String get yesDiscard => 'Sì, scarta';

  @override
  String get currentTimeZone => 'Fuso Orario Attuale';

  @override
  String get exportMyBets => 'Esporta le mie scommesse';

  @override
  String get exportMyBetsSub => 'Genera un\'immagine da salvare o condividere!';

  @override
  String exportBetsOf(String userName) {
    return 'Scommesse di $userName';
  }

  @override
  String exportGroupTitle(String group) {
    return 'GRUPPO $group';
  }

  @override
  String get newPassword => 'Nuova Password';

  @override
  String get confirmPassword => 'Conferma Password';

  @override
  String get waitDataLoad => 'Attendi il caricamento dei dati...';

  @override
  String get changePassword => 'Cambia Password';

  @override
  String get passwordMinLength => 'La password deve avere almeno 6 caratteri.';

  @override
  String get passwordsMismatch => 'Le password non corrispondono.';

  @override
  String get passwordUpdated => 'Password aggiornata con successo!';

  @override
  String get portuguese => 'Português';

  @override
  String get english => 'English';

  @override
  String get italian => 'Italiano';

  @override
  String get notifications => 'Notifiche';

  @override
  String get noNotifications => 'Nessuna notifica.';

  @override
  String get markAsRead => 'Segna come già lette';

  @override
  String get close => 'Chiudi';

  @override
  String get followStandings => 'Segui la Classifica';

  @override
  String get followStandingsSub =>
      'Scegli l\'ordine finale e generiamo i risultati per te';

  @override
  String get desiredStandings => 'Classifica Desiderata';

  @override
  String get dragTeams =>
      'Trascina le squadre nell\'ordine esatto in cui desideri vederle finire nella tabella.';

  @override
  String get generateChaos => 'Genera Caos';

  @override
  String get deleteGroup => 'Elimina Gruppo';

  @override
  String get deleteGroupConfirm =>
      'Sei sicuro di voler eliminare tutte le scommesse di questo gruppo?';

  @override
  String get deleteAllBets => 'Elimina tutte le scommesse';

  @override
  String rankingBetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scommesse',
      one: '1 scommessa',
    );
    return '$_temp0';
  }

  @override
  String get statusScheduled => 'Programmate';

  @override
  String get statusLive => 'In Diretta 🔴';

  @override
  String get statusFinished => 'Terminato';

  @override
  String get teamMexico => 'Messico';

  @override
  String get teamSouthAfrica => 'Sudafrica';

  @override
  String get teamSouthKorea => 'Corea del Sud';

  @override
  String get teamCzechia => 'Cechia';

  @override
  String get teamCanada => 'Canada';

  @override
  String get teamSwitzerland => 'Svizzera';

  @override
  String get teamQatar => 'Qatar';

  @override
  String get teamBosniaAndHerzegovina => 'Bosnia ed Erzegovina';

  @override
  String get teamBrazil => 'Brasile';

  @override
  String get teamMorocco => 'Marocco';

  @override
  String get teamHaiti => 'Haiti';

  @override
  String get teamScotland => 'Scozia';

  @override
  String get teamUnitedStates => 'Stati Uniti';

  @override
  String get teamParaguay => 'Paraguay';

  @override
  String get teamAustralia => 'Australia';

  @override
  String get teamTurkiye => 'Turchia';

  @override
  String get teamGermany => 'Germania';

  @override
  String get teamCuracao => 'Curaçao';

  @override
  String get teamIvoryCoast => 'Costa d\'Avorio';

  @override
  String get teamEcuador => 'Ecuador';

  @override
  String get teamNetherlands => 'Paesi Bassi';

  @override
  String get teamJapan => 'Giappone';

  @override
  String get teamSweden => 'Svezia';

  @override
  String get teamTunisia => 'Tunisia';

  @override
  String get teamBelgium => 'Belgio';

  @override
  String get teamEgypt => 'Egitto';

  @override
  String get teamIRIran => 'Iran';

  @override
  String get teamNewZealand => 'Nuova Zelanda';

  @override
  String get teamSpain => 'Spagna';

  @override
  String get teamCaboVerde => 'Capo Verde';

  @override
  String get teamSaudiArabia => 'Arabia Saudita';

  @override
  String get teamUruguay => 'Uruguay';

  @override
  String get teamFrance => 'Francia';

  @override
  String get teamSenegal => 'Senegal';

  @override
  String get teamIraq => 'Iraq';

  @override
  String get teamNorway => 'Norvegia';

  @override
  String get teamArgentina => 'Argentina';

  @override
  String get teamAlgeria => 'Algeria';

  @override
  String get teamAustria => 'Austria';

  @override
  String get teamJordan => 'Giordania';

  @override
  String get teamPortugal => 'Portogallo';

  @override
  String get teamDRCongo => 'RD del Congo';

  @override
  String get teamUzbekistan => 'Uzbekistan';

  @override
  String get teamColombia => 'Colombia';

  @override
  String get teamEngland => 'Inghilterra';

  @override
  String get teamCroatia => 'Croazia';

  @override
  String get teamGhana => 'Ghana';

  @override
  String get teamPanama => 'Panama';

  @override
  String get paymentPixTitle =>
      'Per gli utenti brasiliani, pagamento tramite Pix.';

  @override
  String get paymentPixKey => 'chiave: pix@example.com';

  @override
  String get paymentPixScan => 'Oppure scansiona il QR Code qui sotto';

  @override
  String get paymentIbanTitle =>
      'Per gli utenti europei, pagamento tramite bonifico';

  @override
  String get paymentIbanKey => 'IBAN: IT93W0364601600526228392905';

  @override
  String get copiedToClipboard => 'Copiato negli appunti!';

  @override
  String get paymentPixAmount => 'Importo: R\$ 20,00';

  @override
  String get paymentIbanAmount => 'Importo: € 5,00';
}

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
  String get regularDeadlineClosed => 'Termine regolare chiuso';

  @override
  String get betsUseSuperPalpite =>
      'Le nuove scommesse usano i Super Pronostici';

  @override
  String get superPalpitesExhausted =>
      'Super Pronostici esauriti — scommesse bloccate';

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
  String get home => 'Home';

  @override
  String get bets => 'Pronostici';

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
  String get advancedStatsSub => 'Scopri come ti confronti con il girone';

  @override
  String get resultsMenu => 'Risultati';

  @override
  String get resultsTabEvolution => 'Evoluzione';

  @override
  String get resultsTabSelection => 'Top 11';

  @override
  String get evolutionByGame => 'Per partita';

  @override
  String get evolutionByDay => 'Per giorno';

  @override
  String get evolutionAxisPosition => 'Posizione in classifica';

  @override
  String get evolutionAxisGame => 'Partita';

  @override
  String get evolutionAxisDay => 'Giorno';

  @override
  String get evolutionYou => 'Tu';

  @override
  String get evolutionNeighbors => 'Vicini';

  @override
  String get evolutionBest => 'migliore';

  @override
  String get evolutionWorst => 'peggiore';

  @override
  String get evolutionFinal => 'finale';

  @override
  String get compareWith => 'Confronta con:';

  @override
  String get addUser => 'Aggiungi utente';

  @override
  String get resultsEmpty =>
      'Ancora nessuna partita conclusa per mostrare l\'evoluzione.';

  @override
  String get lineupTitle => 'Top 11 del torneo';

  @override
  String get coach => 'Allenatore';

  @override
  String get lastPlace => 'Ultimo posto';

  @override
  String get bench => 'Panchina';

  @override
  String get reserveGoalkeeper => 'Portiere di riserva';

  @override
  String get tied => 'Pari merito';

  @override
  String get posGoalkeeper => 'Portiere';

  @override
  String get posDefense => 'Difesa';

  @override
  String get posDefensiveMid => 'Mediano';

  @override
  String get posPlaymaker => 'Trequartista';

  @override
  String get posWinger => 'Ala';

  @override
  String get posStriker => 'Attaccante';

  @override
  String get resultsLineupEmpty =>
      'Partecipanti insufficienti per formare la squadra (minimo 12).';

  @override
  String get statsTabRankings => 'Classifiche';

  @override
  String get statsTabPersonal => 'Personale';

  @override
  String get statsTabAchievements => 'Traguardi';

  @override
  String get statsTabPool => 'Girone';

  @override
  String get statExactTitle => 'Re del Risultato Esatto';

  @override
  String get statExactSub => 'Chi ha azzeccato più risultati esatti';

  @override
  String get statExactUnit => 'esatti';

  @override
  String get statBrazilTitle => 'Portafortuna del Brasile';

  @override
  String get statBrazilSub =>
      'Chi ha fatto più punti sulle partite del Brasile';

  @override
  String get statNearMissTitle => 'Quasi';

  @override
  String get statNearMissSub =>
      'Ha azzeccato l\'esito ma sbagliato il risultato per 1 gol';

  @override
  String get statNearMissUnit => 'quasi';

  @override
  String get statDailyTitle => 'Giornata Top';

  @override
  String get statDailySub => 'Punteggio più alto in un solo giorno';

  @override
  String get statRegularTitle => 'Più Regolare';

  @override
  String get statRegularSub => 'Ha fatto punti nel maggior numero di partite';

  @override
  String get statRegularUnit => 'partite';

  @override
  String get statBoldTitle => 'I Coraggiosi';

  @override
  String get statBoldSub => 'Chi rischia i risultati più audaci';

  @override
  String get statBoldUnit => 'audaci';

  @override
  String get statContrarianTitle => 'Controcorrente vincente';

  @override
  String get statContrarianSub =>
      'Ha azzeccato risultati che quasi nessuno ha scelto';

  @override
  String get statContrarianUnit => 'rare';

  @override
  String get statsNoGames => 'Ancora nessuna partita per questa statistica';

  @override
  String get statsPersonalEmpty =>
      'I tuoi numeri compaiono man mano che si giocano le partite';

  @override
  String get statGroupPointsTitle => 'Punti per Girone';

  @override
  String get statGroupPointsSub => 'Dove hai fatto più e meno punti';

  @override
  String get statDistributionTitle => 'Distribuzione Esiti';

  @override
  String get statDistributionSub => 'Esatti, risultati ed errori';

  @override
  String get statDistResult => 'risultati';

  @override
  String get statDistZero => 'errori';

  @override
  String get statUtilization => 'Efficienza';

  @override
  String get statSignatureTitle => 'Risultato firma';

  @override
  String get statSignatureSub => 'Il risultato che giochi di più';

  @override
  String get statHandTitle => 'Media Gol';

  @override
  String get statHandSub => 'La tua media gol a partita vs la media reale';

  @override
  String get statHandReal => 'Reale';

  @override
  String get statGoalsPerGame => 'gol/partita';

  @override
  String get statLuckyTitle => 'Amuleto Fortuna / Sfortuna';

  @override
  String get statLuckySub => 'Squadre dove fai più e meno punti';

  @override
  String get statLucky => 'Fortuna';

  @override
  String get statUnlucky => 'Sfortuna';

  @override
  String get statStreakTitle => 'Serie più Lunga';

  @override
  String get statStreakSub => 'Partite di fila a punti';

  @override
  String get statBest => 'Migliore';

  @override
  String get statWorst => 'Peggiore';

  @override
  String get statBestPlural => 'Migliori';

  @override
  String get statWorstPlural => 'Peggiori';

  @override
  String get poolUnpredictableTitle => 'Partite più imprevedibili';

  @override
  String get poolUnpredictableSub => 'Dove meno gente ha azzeccato';

  @override
  String get poolEveryoneKnewTitle => 'Lo sapevano tutti';

  @override
  String get poolEveryoneKnewSub => 'Dove più gente ha azzeccato';

  @override
  String get poolPopularTitle => 'Pronostici più popolari';

  @override
  String get poolPopularSub => 'I risultati più giocati del girone';

  @override
  String get poolUniqueTitle => 'Pronostici unici';

  @override
  String get poolUniqueSub => 'I risultati più rari del girone';

  @override
  String get poolNailedLabel => 'azzeccato';

  @override
  String get poolWhoNailed => 'Chi ha azzeccato';

  @override
  String get poolNobodyNailed => 'Nessuno ha azzeccato questa partita';

  @override
  String get poolLookupTitle => 'Cerca un risultato';

  @override
  String get poolLookupHint => 'es. 1-1';

  @override
  String get poolLookupNotFound => 'Nessun pronostico con quel risultato';

  @override
  String get achBronze => 'Bronzo';

  @override
  String get achPrata => 'Argento';

  @override
  String get achOuro => 'Oro';

  @override
  String get achRarityOf => 'dei giocatori';

  @override
  String get achUnlocked => 'Sbloccato';

  @override
  String get achUnlockedOn => 'Sbloccato il';

  @override
  String get achViewGames => 'Vedi le partite';

  @override
  String get achExactTitle => 'Risultati Esatti';

  @override
  String get achExactDesc => 'Azzecca risultati esatti';

  @override
  String get achEmpateName => 'Sapevo del Pari';

  @override
  String get achEmpateDesc => 'Azzecca un pareggio';

  @override
  String get achOusadiaName => 'Coraggio e Allegria';

  @override
  String get achOusadiaDesc =>
      'Azzecca un pronostico audace (5+ di scarto o 7+ gol)';

  @override
  String get achEmbaladoName => 'In Fiamme';

  @override
  String get achEmbaladoDesc => 'Fai punti in più partite di fila';

  @override
  String get achPequenteName => 'Caldissimo';

  @override
  String get achPequenteDesc => 'Fai punti in 5 partite di fila';

  @override
  String get achDiaCheioName => 'Giornata Piena';

  @override
  String get achDiaCheioDesc =>
      'Fai punti in tutte le partite di un giorno (con 3+ partite)';

  @override
  String get achVoltaName => 'Giro del Mondo';

  @override
  String get achVoltaDesc => 'Fai punti in tutti i gironi';

  @override
  String get achDonoName => 'Padrone del Girone';

  @override
  String get achDonoDesc => 'Fai 6+ punti in un girone';

  @override
  String get achBrasilName => 'Cuore Verdeoro';

  @override
  String get achBrasilDesc => 'Fai punti in una partita del Brasile';

  @override
  String get achProfetaName => 'Profeta';

  @override
  String get achProfetaDesc =>
      'Azzecca un risultato che meno del 10% ha azzeccato';

  @override
  String get achPanelaName => 'Benvenuto nel Gruppo';

  @override
  String get achPanelaDesc => 'Entra in una lega';

  @override
  String get achMeioSeculoName => 'Piove Punti';

  @override
  String get achMeioSeculoDesc => 'Raggiungi 50 punti totali';

  @override
  String get achQuaseName => 'Quasi';

  @override
  String get achQuaseDesc => 'Colleziona \"quasi\" (sbagliato per 1 gol)';

  @override
  String get achNewUnlocked => 'Nuovo traguardo!';

  @override
  String get achNice => 'Forte!';

  @override
  String get achViewAchievement => 'Vedi traguardo';

  @override
  String get achClose => 'Chiudi';

  @override
  String get statPointsUnit => 'pti';

  @override
  String get statsYou => 'Tu';

  @override
  String get statsSeeAll => 'Vedi tutti';

  @override
  String get statsSeeMore => 'Mostra altri';

  @override
  String get statsSeeLess => 'Mostra meno';

  @override
  String get statsComingSoon => 'Presto in questa scheda!';

  @override
  String get statsEmpty => 'Dati ancora insufficienti';

  @override
  String get statsError => 'Caricamento non riuscito';

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
  String get helpTiebreakTitle => 'Criteri di Spareggio ⚖️';

  @override
  String get helpTiebreakDesc =>
      'In caso di parità di punti, la posizione in classifica è decisa in questo ordine: 1) chi ha indovinato più risultati esatti (scommesse da 3 punti); 2) chi ha totalizzato più punti nelle partite del Brasile. Se la parità persiste, i giocatori condividono la stessa posizione in classifica.';

  @override
  String get prizesTitle => 'Premi';

  @override
  String get prizesCardDesc =>
      'Scopri come il montepremi totale è suddiviso tra la classifica generale e ogni giornata.';

  @override
  String get prizesTotalLabel => 'Montepremi totale';

  @override
  String get prizesGeneralTitle => 'Classifica Generale';

  @override
  String get prizesGeneralNote =>
      'Considerando tutte le partite della fase a gironi.';

  @override
  String get prizesLastPlace => 'Ultimo classificato';

  @override
  String get prizesPerRoundTitle => 'Per Giornata';

  @override
  String get prizesPerRoundNote =>
      'I primi 3 di ogni giornata (1ª, 2ª e 3ª) vengono premiati.';

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
  String get nextMatch => 'Prossima Partita';

  @override
  String get matchesOfDay => 'Partite del giorno';

  @override
  String get yourPrediction => 'Il tuo pronostico';

  @override
  String get makeYourPrediction => 'Fai il tuo pronostico';

  @override
  String get previousGroup => 'Gruppo precedente';

  @override
  String get nextGroup => 'Gruppo successivo';

  @override
  String get searchPlayer => 'Cerca giocatore...';

  @override
  String get youLabel => 'Tu';

  @override
  String get exportRanking => 'Esporta classifica';

  @override
  String exportRankingOf(String leagueName) {
    return 'Classifica: $leagueName';
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
  String get noNotifications => 'Nessuna notifica';

  @override
  String get markAsRead => 'Segna come già letto';

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

  @override
  String get firstName => 'Nome';

  @override
  String get lastName => 'Cognome';

  @override
  String get displayAs => 'Apparire in classifica come:';

  @override
  String get displayAsUsername => 'Nome utente';

  @override
  String get displayAsFullName => 'Nome e Cognome';

  @override
  String get completeProfileTitle => 'Completa il tuo profilo';

  @override
  String get completeProfileDesc =>
      'Abbiamo bisogno del tuo nome per facilitare l\'identificazione nei pagamenti e in classifica.';

  @override
  String get nameRequired => 'Inserisci il tuo nome e cognome';

  @override
  String get phoneLabel => 'Telefono / WhatsApp';

  @override
  String get phoneRequired => 'Inserisci il tuo numero di telefono';

  @override
  String get phoneInvalidBr =>
      'Telefono non valido. Usa prefisso + numero (11 cifre).';

  @override
  String get editProfile => 'Aggiorna Dati Personali';

  @override
  String get leaveLeague => 'Abbandona lega';

  @override
  String get leaveLeagueConfirm =>
      'Sei sicuro di voler abbandonare questa lega?';

  @override
  String get paymentPending => 'Pagamento in sospeso';

  @override
  String get paymentRealized => 'Pagamento completato';

  @override
  String get adminTabMatches => 'Partite';

  @override
  String get adminTabUsers => 'Utenti';

  @override
  String get exportData => 'Esporta CSV';

  @override
  String get searchUsers => 'Cerca per username, email o nome...';

  @override
  String get visitorMode => 'ospite';

  @override
  String get yourBet => 'Tu';

  @override
  String get partial => 'parziale';

  @override
  String get liveNow => 'IN DIRETTA';

  @override
  String get finalLabel => 'FINALE';

  @override
  String get versusShort => 'vs';

  @override
  String get hiddenUntilKickoff => 'Nascosto fino al fischio d\'inizio';

  @override
  String get completeBetsToView =>
      'Completa le tue scommesse per vedere quelle degli altri';

  @override
  String get completeBetsToViewSub =>
      'Devi inserire almeno 65 delle tue scommesse prima di poter vedere i pronostici degli altri partecipanti.';

  @override
  String rankPositionShort(int rank) {
    return '$rankº posto';
  }

  @override
  String get errGeneric => 'Qualcosa è andato storto. Riprova.';

  @override
  String get errConnection =>
      'Nessuna connessione. Controlla la rete e riprova.';

  @override
  String get errAuth =>
      'Autenticazione fallita. Controlla i tuoi dati e riprova.';

  @override
  String get errBetMatchStarted =>
      'La partita è già iniziata o terminata — non puoi modificare il pronostico.';

  @override
  String get errBetDeadlinePassed =>
      'Il termine per modificare questo pronostico è scaduto (meno di 1 ora al fischio d\'inizio).';

  @override
  String get errSuperPalpiteLimit =>
      'Hai già usato tutti i 10 Super Pronostici.';

  @override
  String get errSyncFailed =>
      'Impossibile sincronizzare il foglio. Controlla la connessione e riprova.';

  @override
  String get filterAll => 'Tutti';

  @override
  String get filterRound1 => 'Giornata 1';

  @override
  String get filterRound2 => 'Giornata 2';

  @override
  String get filterRound3 => 'Giornata 3';

  @override
  String get rankingScopeGeneral => 'Generale';

  @override
  String get filterDay => 'Di oggi';

  @override
  String get filterFinished => 'Finite';

  @override
  String get filterUnfinished => 'Non finite';

  @override
  String get filterExact => 'Risultato esatto';

  @override
  String get filterResult => 'Esito';

  @override
  String get filterLost => 'Persa';

  @override
  String get filterNoGames => 'Nessuna partita con questi filtri';

  @override
  String get viewBets => 'Vedi pronostici';

  @override
  String get leagueBetsSelectMatch =>
      'Scegli una partita per vedere i pronostici della lega';

  @override
  String get leagueBetsNobody =>
      'Nessuno della lega ha pronosticato questa partita';

  @override
  String get leagueBetsLockedUntilDeadline =>
      'Disponibile dopo la chiusura dei pronostici';

  @override
  String get filterLosing => 'In perdita';

  @override
  String get searchScore => 'Cerca risultato (es. 2-1)';

  @override
  String get searchScoreOrPlayer => 'Cerca risultato (2-1) o giocatore';

  @override
  String get filterAdd => 'Aggiungi';

  @override
  String get filterClear => 'Pulisci';

  @override
  String topNFilter(int count) {
    return 'Primi $count';
  }

  @override
  String generalRankPosition(int rank) {
    return '$rankº in classifica generale';
  }

  @override
  String get koMenu => 'Eliminazione';

  @override
  String get koStatsMenu => 'Statistiche Eliminazione';

  @override
  String koSaveError(String error) {
    return 'Impossibile salvare: $error';
  }

  @override
  String koPlusPoints(int points) {
    return '+$points pt';
  }

  @override
  String get koLockTeamsUndefined =>
      'Le scommesse aprono quando la sfida è definita.';

  @override
  String get koLockStarted => 'Partita già iniziata — scommesse chiuse.';

  @override
  String get koLockClosed30min =>
      'Scommesse chiuse (chiudono 30 min prima della partita).';

  @override
  String get koFinalsScoringNote =>
      'Semifinale e Finale: risultato esatto vale 5 pt · esito corretto 3 pt.';

  @override
  String get koChampionTitle => 'Pronostico Campione';

  @override
  String get koChampionSubtitle => 'Chi alza la coppa? Indovinare vale +3 pt.';

  @override
  String get koChampionCta => 'Scegli campione';

  @override
  String get koChampionChange => 'Cambia';

  @override
  String get koChampionEmptyLocked => 'Non hai pronosticato il campione.';

  @override
  String get koChampionSheetTitle => 'Scegli il campione del Mondiale';

  @override
  String get koChampionSearchHint => 'Cerca nazionale';

  @override
  String get koChampionNoResults => 'Nessuna nazionale trovata';

  @override
  String get helpKoSection => 'Eliminazione';

  @override
  String get helpKoScoringTitle => 'Punteggio Eliminazione';

  @override
  String get helpKoScoringDesc =>
      'Ogni partita vale 3 punti per il risultato esatto e 1 punto per il solo esito corretto. In Semifinale e Finale, il risultato esatto vale 5 punti e l\'esito 3. Conta solo i tempi regolamentari (90 min): supplementari e rigori non valgono per il pronostico.';

  @override
  String get helpKoChampionTitle => 'Pronostico Campione';

  @override
  String get helpKoChampionDesc =>
      'Prima della prima partita a eliminazione, scegli chi sarà il campione del Mondiale. Se indovini, guadagni 3 punti bonus nella classifica a eliminazione.';

  @override
  String get helpKoDeadlineTitle => 'Scadenza Eliminazione';

  @override
  String get helpKoDeadlineDesc =>
      'Le scommesse di ogni partita a eliminazione possono essere fatte o modificate fino a 30 minuti prima del calcio d\'inizio.';

  @override
  String get helpKoRankingTitle => 'Classifica Eliminazione';

  @override
  String get helpKoRankingDesc =>
      'La fase a eliminazione ha una classifica propria, separata dalla fase a gironi (parte da zero).';

  @override
  String get helpKoPrizesTitle => 'Premi Eliminazione';

  @override
  String get helpKoPrizesDesc =>
      'Scopri come il montepremi della fase a eliminazione è suddiviso tra i primi 8 classificati.';

  @override
  String get koPrizesTitle => 'Premi Eliminazione';

  @override
  String get koPrizesSectionTitle => 'Classifica Eliminazione';

  @override
  String get koPrizesNote =>
      'In base alla classifica finale della fase a eliminazione (classifica propria).';

  @override
  String get koStatsTitle => 'Statistiche Eliminazione';

  @override
  String get koStatsTabRankings => 'Classifiche';

  @override
  String get koStatsTabPersonal => 'Personale';

  @override
  String get koStatPointsTitle => 'Punti Eliminazione';

  @override
  String get koStatPointsSub => 'Chi ha fatto più punti nell\'eliminazione';

  @override
  String get koStatPointsUnit => 'pt';

  @override
  String get koStatExactTitle => 'Re del Risultato Esatto';

  @override
  String get koStatExactSub => 'Chi ha azzeccato più risultati';

  @override
  String get koStatExactUnit => 'esatti';

  @override
  String get koChampionDistTitle => 'Pronostico Campione';

  @override
  String get koChampionDistSub => 'Le nazionali più scelte';

  @override
  String get koChampionDistEmpty =>
      'La distribuzione appare quando inizia l\'eliminazione.';

  @override
  String get koPersonalTotalPoints => 'Punti eliminazione';

  @override
  String get koPersonalExacts => 'Risultati esatti';

  @override
  String get koPersonalDirs => 'Esiti corretti';

  @override
  String get koPersonalZeros => 'Errori';

  @override
  String get koPersonalAccuracy => 'Rendimento';

  @override
  String get koPersonalPlayed => 'Partite con punti';

  @override
  String get koPersonalChampionBonus => 'Bonus campione';

  @override
  String get koPersonalEmpty =>
      'Non hai ancora statistiche nell\'eliminazione.';

  @override
  String get koChampionStatusNone => 'Non hai pronosticato il campione.';

  @override
  String get koChampionStatusPending => 'In attesa della finale.';

  @override
  String get koChampionStatusHit => 'Hai indovinato il campione! 🎉';

  @override
  String get koChampionStatusMiss => 'Non hai indovinato il campione.';

  @override
  String get statsScopeGroups => 'Fase a Gironi';

  @override
  String get statsScopeKnockout => 'Eliminazione';

  @override
  String get groupStageClosed => 'Fase a gironi conclusa';

  @override
  String get koStatsTabPool => 'Lega';

  @override
  String get koPoolPopularTitle => 'Risultati più giocati';

  @override
  String get koPoolPopularSub => 'I risultati più scelti nell\'eliminazione';

  @override
  String get koPoolUnpredictableTitle => 'Partite più imprevedibili';

  @override
  String get koPoolUnpredictableSub => 'In pochi hanno azzeccato il risultato';

  @override
  String get koPoolEveryoneKnewTitle => 'Lo sapevano tutti';

  @override
  String get koPoolEveryoneKnewSub => 'In molti hanno azzeccato il risultato';

  @override
  String get koPoolEmpty => 'Dati ancora insufficienti.';

  @override
  String koPoolExactOf(int exact, int total) {
    return '$exact su $total hanno azzeccato';
  }

  @override
  String get koTbd => 'Da definire';

  @override
  String get koLiveBadge => 'IN CORSO';

  @override
  String get koNoBet => 'Nessun pronostico';

  @override
  String get koYourBet => 'Il tuo pronostico';

  @override
  String get koUpdateBet => 'Aggiorna pronostico';

  @override
  String get koConfirmBet => 'Conferma pronostico';

  @override
  String koBetValue(int home, int away) {
    return 'Pronostico $home × $away';
  }

  @override
  String get koBracketUnavailable => 'Tabellone non ancora disponibile.';

  @override
  String get koViewBracket => 'Tabellone';

  @override
  String get koViewList => 'Lista';

  @override
  String koRoundGamesCount(int count) {
    return '· $count partite';
  }

  @override
  String koLoadError(String message) {
    return 'Errore nel caricamento: $message';
  }

  @override
  String get koLockedTitle => 'Eliminazione bloccata';

  @override
  String get koLockedDesc =>
      'Il torneo a eliminazione ha un\'iscrizione propria. Appena confermata, apparirà qui automaticamente.';

  @override
  String get koThirdPlaceShort => '3º posto';

  @override
  String get koRound16avos => 'Sedicesimi';

  @override
  String get koRoundOitavas => 'Ottavi';

  @override
  String get koRoundQuartas => 'Quarti';

  @override
  String get koRoundSemis => 'Semifinali';

  @override
  String get koRoundFinal => 'Finale';

  @override
  String get koRound3lugar => 'Finale 3º posto';
}

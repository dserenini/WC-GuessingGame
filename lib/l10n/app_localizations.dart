import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
    Locale('pt')
  ];

  /// No description provided for @loginSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Aposte no seu grupo com os amigos'**
  String get loginSubtitle;

  /// No description provided for @login.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// No description provided for @username.
  ///
  /// In pt, this message translates to:
  /// **'Nome de usuário'**
  String get username;

  /// No description provided for @confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim, vai fundo!'**
  String get yes;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @group.
  ///
  /// In pt, this message translates to:
  /// **'Grupo'**
  String get group;

  /// No description provided for @groups.
  ///
  /// In pt, this message translates to:
  /// **'GRUPOS'**
  String get groups;

  /// No description provided for @ranking.
  ///
  /// In pt, this message translates to:
  /// **'Ranking'**
  String get ranking;

  /// No description provided for @privateLeagues.
  ///
  /// In pt, this message translates to:
  /// **'Ligas Privadas'**
  String get privateLeagues;

  /// No description provided for @settings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings;

  /// No description provided for @adminPanel.
  ///
  /// In pt, this message translates to:
  /// **'Painel Admin'**
  String get adminPanel;

  /// No description provided for @signOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get signOut;

  /// No description provided for @betsLocked.
  ///
  /// In pt, this message translates to:
  /// **'Apostas encerradas — prazo expirado'**
  String get betsLocked;

  /// No description provided for @betsOpen.
  ///
  /// In pt, this message translates to:
  /// **'Apostas abertas'**
  String get betsOpen;

  /// No description provided for @betDeadline.
  ///
  /// In pt, this message translates to:
  /// **'Prazo das Apostas'**
  String get betDeadline;

  /// No description provided for @regularDeadlineClosed.
  ///
  /// In pt, this message translates to:
  /// **'Prazo regular encerrado'**
  String get regularDeadlineClosed;

  /// No description provided for @betsUseSuperPalpite.
  ///
  /// In pt, this message translates to:
  /// **'Novas apostas consomem Super Palpites'**
  String get betsUseSuperPalpite;

  /// No description provided for @superPalpitesExhausted.
  ///
  /// In pt, this message translates to:
  /// **'Super Palpites esgotados — apostas bloqueadas'**
  String get superPalpitesExhausted;

  /// No description provided for @result.
  ///
  /// In pt, this message translates to:
  /// **'Resultado'**
  String get result;

  /// No description provided for @agentOfChaos.
  ///
  /// In pt, this message translates to:
  /// **'Agente do Caos'**
  String get agentOfChaos;

  /// No description provided for @chaosRandomAll.
  ///
  /// In pt, this message translates to:
  /// **'Aleatorizar tudo'**
  String get chaosRandomAll;

  /// No description provided for @chaosRandomAllSub.
  ///
  /// In pt, this message translates to:
  /// **'Preenche placares vazios aleatoriamente'**
  String get chaosRandomAllSub;

  /// No description provided for @chaosGuidedHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque na bandeira para vitória aleatória. Toque no \'X\' para empate aleatório.'**
  String get chaosGuidedHint;

  /// No description provided for @chaosMaxGoals.
  ///
  /// In pt, this message translates to:
  /// **'Bolas no máximo'**
  String get chaosMaxGoals;

  /// No description provided for @wackyGoalAlert.
  ///
  /// In pt, this message translates to:
  /// **'Você está colocando mais de 20 gols... É sério isso? 😱'**
  String get wackyGoalAlert;

  /// No description provided for @appearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @account.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get account;

  /// No description provided for @joinLeague.
  ///
  /// In pt, this message translates to:
  /// **'Entrar em liga'**
  String get joinLeague;

  /// No description provided for @createLeague.
  ///
  /// In pt, this message translates to:
  /// **'Criar liga'**
  String get createLeague;

  /// No description provided for @joinOrCreate.
  ///
  /// In pt, this message translates to:
  /// **'Entrar ou criar'**
  String get joinOrCreate;

  /// No description provided for @inviteCode.
  ///
  /// In pt, this message translates to:
  /// **'Código de convite'**
  String get inviteCode;

  /// No description provided for @leagueName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da liga'**
  String get leagueName;

  /// No description provided for @noLeagues.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma liga ainda'**
  String get noLeagues;

  /// No description provided for @noLeaguesSub.
  ///
  /// In pt, this message translates to:
  /// **'Entre em uma liga com um código ou crie a sua'**
  String get noLeaguesSub;

  /// No description provided for @codeCopied.
  ///
  /// In pt, this message translates to:
  /// **'Código copiado!'**
  String get codeCopied;

  /// No description provided for @myProfile.
  ///
  /// In pt, this message translates to:
  /// **'Meu Perfil'**
  String get myProfile;

  /// No description provided for @betsFilled.
  ///
  /// In pt, this message translates to:
  /// **'Apostas Preenchidas'**
  String get betsFilled;

  /// No description provided for @totalPoints.
  ///
  /// In pt, this message translates to:
  /// **'Pontos Totais'**
  String get totalPoints;

  /// No description provided for @exactHits.
  ///
  /// In pt, this message translates to:
  /// **'Acerto no Placar'**
  String get exactHits;

  /// No description provided for @resultHits.
  ///
  /// In pt, this message translates to:
  /// **'Acerto no Resultado'**
  String get resultHits;

  /// No description provided for @superPalpites.
  ///
  /// In pt, this message translates to:
  /// **'Super Palpites'**
  String get superPalpites;

  /// No description provided for @superPalpitesRemaining.
  ///
  /// In pt, this message translates to:
  /// **'Você tem {count} alterações após o prazo limite.'**
  String superPalpitesRemaining(int count);

  /// No description provided for @forgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha senha'**
  String get forgotPassword;

  /// No description provided for @recoverPassword.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar Senha'**
  String get recoverPassword;

  /// No description provided for @recoverPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite o seu e-mail para receber um link de recuperação.'**
  String get recoverPasswordHint;

  /// No description provided for @recoveryLinkSent.
  ///
  /// In pt, this message translates to:
  /// **'Link de recuperação enviado! Verifique seu e-mail.'**
  String get recoveryLinkSent;

  /// No description provided for @send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get send;

  /// No description provided for @errorGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {error}'**
  String errorGeneric(String error);

  /// No description provided for @invalidLogin.
  ///
  /// In pt, this message translates to:
  /// **'Login/Senha incorretos.'**
  String get invalidLogin;

  /// No description provided for @chooseLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Escolha seu idioma'**
  String get chooseLanguage;

  /// No description provided for @continueBtn.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get continueBtn;

  /// No description provided for @advancedStats.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas Avançadas'**
  String get advancedStats;

  /// No description provided for @advancedStatsSub.
  ///
  /// In pt, this message translates to:
  /// **'Veja como você se compara ao bolão'**
  String get advancedStatsSub;

  /// No description provided for @statsTabRankings.
  ///
  /// In pt, this message translates to:
  /// **'Rankings'**
  String get statsTabRankings;

  /// No description provided for @statsTabPersonal.
  ///
  /// In pt, this message translates to:
  /// **'Pessoal'**
  String get statsTabPersonal;

  /// No description provided for @statsTabAchievements.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas'**
  String get statsTabAchievements;

  /// No description provided for @statsTabPool.
  ///
  /// In pt, this message translates to:
  /// **'Bolão'**
  String get statsTabPool;

  /// No description provided for @statExactTitle.
  ///
  /// In pt, this message translates to:
  /// **'Rei do Placar Exato'**
  String get statExactTitle;

  /// No description provided for @statExactSub.
  ///
  /// In pt, this message translates to:
  /// **'Quem mais cravou o placar'**
  String get statExactSub;

  /// No description provided for @statExactUnit.
  ///
  /// In pt, this message translates to:
  /// **'exatos'**
  String get statExactUnit;

  /// No description provided for @statBrazilTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pé-quente do Brasil'**
  String get statBrazilTitle;

  /// No description provided for @statBrazilSub.
  ///
  /// In pt, this message translates to:
  /// **'Quem mais pontuou nos jogos do Brasil'**
  String get statBrazilSub;

  /// No description provided for @statNearMissTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quase lá'**
  String get statNearMissTitle;

  /// No description provided for @statNearMissSub.
  ///
  /// In pt, this message translates to:
  /// **'Cravaria o resultado, mas ficou no quase por 1 gol'**
  String get statNearMissSub;

  /// No description provided for @statNearMissUnit.
  ///
  /// In pt, this message translates to:
  /// **'quase'**
  String get statNearMissUnit;

  /// No description provided for @statDailyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tacada do Dia'**
  String get statDailyTitle;

  /// No description provided for @statDailySub.
  ///
  /// In pt, this message translates to:
  /// **'Maior pontuação num único dia'**
  String get statDailySub;

  /// No description provided for @statRegularTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mais Regular'**
  String get statRegularTitle;

  /// No description provided for @statRegularSub.
  ///
  /// In pt, this message translates to:
  /// **'Pontuou no maior número de jogos'**
  String get statRegularSub;

  /// No description provided for @statRegularUnit.
  ///
  /// In pt, this message translates to:
  /// **'jogos'**
  String get statRegularUnit;

  /// No description provided for @statBoldTitle.
  ///
  /// In pt, this message translates to:
  /// **'Os Corajosos'**
  String get statBoldTitle;

  /// No description provided for @statBoldSub.
  ///
  /// In pt, this message translates to:
  /// **'Quem arrisca os placares mais ousados'**
  String get statBoldSub;

  /// No description provided for @statBoldUnit.
  ///
  /// In pt, this message translates to:
  /// **'ousados'**
  String get statBoldUnit;

  /// No description provided for @statContrarianTitle.
  ///
  /// In pt, this message translates to:
  /// **'Do Contra que Acertou'**
  String get statContrarianTitle;

  /// No description provided for @statContrarianSub.
  ///
  /// In pt, this message translates to:
  /// **'Cravou placares que quase ninguém apostou'**
  String get statContrarianSub;

  /// No description provided for @statContrarianUnit.
  ///
  /// In pt, this message translates to:
  /// **'raras'**
  String get statContrarianUnit;

  /// No description provided for @statsNoGames.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum jogo nesta estatística ainda'**
  String get statsNoGames;

  /// No description provided for @statsPersonalEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Seus números aparecem conforme os jogos acontecem'**
  String get statsPersonalEmpty;

  /// No description provided for @statGroupPointsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pontos por Grupo'**
  String get statGroupPointsTitle;

  /// No description provided for @statGroupPointsSub.
  ///
  /// In pt, this message translates to:
  /// **'Onde você mais e menos pontuou'**
  String get statGroupPointsSub;

  /// No description provided for @statDistributionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição de Acertos'**
  String get statDistributionTitle;

  /// No description provided for @statDistributionSub.
  ///
  /// In pt, this message translates to:
  /// **'Exatos, resultados e erros'**
  String get statDistributionSub;

  /// No description provided for @statDistResult.
  ///
  /// In pt, this message translates to:
  /// **'resultados'**
  String get statDistResult;

  /// No description provided for @statDistZero.
  ///
  /// In pt, this message translates to:
  /// **'erros'**
  String get statDistZero;

  /// No description provided for @statUtilization.
  ///
  /// In pt, this message translates to:
  /// **'Aproveitamento'**
  String get statUtilization;

  /// No description provided for @statSignatureTitle.
  ///
  /// In pt, this message translates to:
  /// **'Placar-assinatura'**
  String get statSignatureTitle;

  /// No description provided for @statSignatureSub.
  ///
  /// In pt, this message translates to:
  /// **'O placar que você mais aposta'**
  String get statSignatureSub;

  /// No description provided for @statHandTitle.
  ///
  /// In pt, this message translates to:
  /// **'Média de Gols'**
  String get statHandTitle;

  /// No description provided for @statHandSub.
  ///
  /// In pt, this message translates to:
  /// **'Sua média de gols por jogo vs a média da realidade'**
  String get statHandSub;

  /// No description provided for @statHandReal.
  ///
  /// In pt, this message translates to:
  /// **'Real'**
  String get statHandReal;

  /// No description provided for @statGoalsPerGame.
  ///
  /// In pt, this message translates to:
  /// **'gols/jogo'**
  String get statGoalsPerGame;

  /// No description provided for @statLuckyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Amuleto da Sorte / Azar'**
  String get statLuckyTitle;

  /// No description provided for @statLuckySub.
  ///
  /// In pt, this message translates to:
  /// **'Seleções onde você mais e menos pontua'**
  String get statLuckySub;

  /// No description provided for @statLucky.
  ///
  /// In pt, this message translates to:
  /// **'Sorte'**
  String get statLucky;

  /// No description provided for @statUnlucky.
  ///
  /// In pt, this message translates to:
  /// **'Azar'**
  String get statUnlucky;

  /// No description provided for @statStreakTitle.
  ///
  /// In pt, this message translates to:
  /// **'Maior Sequência'**
  String get statStreakTitle;

  /// No description provided for @statStreakSub.
  ///
  /// In pt, this message translates to:
  /// **'Jogos seguidos pontuando'**
  String get statStreakSub;

  /// No description provided for @statBest.
  ///
  /// In pt, this message translates to:
  /// **'Melhor'**
  String get statBest;

  /// No description provided for @statWorst.
  ///
  /// In pt, this message translates to:
  /// **'Pior'**
  String get statWorst;

  /// No description provided for @statBestPlural.
  ///
  /// In pt, this message translates to:
  /// **'Melhores'**
  String get statBestPlural;

  /// No description provided for @statWorstPlural.
  ///
  /// In pt, this message translates to:
  /// **'Piores'**
  String get statWorstPlural;

  /// No description provided for @poolUnpredictableTitle.
  ///
  /// In pt, this message translates to:
  /// **'Jogos mais imprevisíveis'**
  String get poolUnpredictableTitle;

  /// No description provided for @poolUnpredictableSub.
  ///
  /// In pt, this message translates to:
  /// **'Onde menos gente cravou o placar'**
  String get poolUnpredictableSub;

  /// No description provided for @poolEveryoneKnewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Esse todo mundo sabia'**
  String get poolEveryoneKnewTitle;

  /// No description provided for @poolEveryoneKnewSub.
  ///
  /// In pt, this message translates to:
  /// **'Onde mais gente cravou o placar'**
  String get poolEveryoneKnewSub;

  /// No description provided for @poolPopularTitle.
  ///
  /// In pt, this message translates to:
  /// **'Palpites mais populares'**
  String get poolPopularTitle;

  /// No description provided for @poolPopularSub.
  ///
  /// In pt, this message translates to:
  /// **'Os placares mais apostados do bolão'**
  String get poolPopularSub;

  /// No description provided for @poolUniqueTitle.
  ///
  /// In pt, this message translates to:
  /// **'Palpites únicos'**
  String get poolUniqueTitle;

  /// No description provided for @poolUniqueSub.
  ///
  /// In pt, this message translates to:
  /// **'Os placares mais raros do bolão'**
  String get poolUniqueSub;

  /// No description provided for @poolNailedLabel.
  ///
  /// In pt, this message translates to:
  /// **'cravaram'**
  String get poolNailedLabel;

  /// No description provided for @poolWhoNailed.
  ///
  /// In pt, this message translates to:
  /// **'Quem cravou'**
  String get poolWhoNailed;

  /// No description provided for @poolNobodyNailed.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém cravou este jogo'**
  String get poolNobodyNailed;

  /// No description provided for @poolLookupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Consultar um placar'**
  String get poolLookupTitle;

  /// No description provided for @poolLookupHint.
  ///
  /// In pt, this message translates to:
  /// **'ex.: 1-1'**
  String get poolLookupHint;

  /// No description provided for @poolLookupNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum palpite com esse placar'**
  String get poolLookupNotFound;

  /// No description provided for @achBronze.
  ///
  /// In pt, this message translates to:
  /// **'Bronze'**
  String get achBronze;

  /// No description provided for @achPrata.
  ///
  /// In pt, this message translates to:
  /// **'Prata'**
  String get achPrata;

  /// No description provided for @achOuro.
  ///
  /// In pt, this message translates to:
  /// **'Ouro'**
  String get achOuro;

  /// No description provided for @achRarityOf.
  ///
  /// In pt, this message translates to:
  /// **'dos jogadores'**
  String get achRarityOf;

  /// No description provided for @achUnlocked.
  ///
  /// In pt, this message translates to:
  /// **'Conquistado'**
  String get achUnlocked;

  /// No description provided for @achUnlockedOn.
  ///
  /// In pt, this message translates to:
  /// **'Conquistado em'**
  String get achUnlockedOn;

  /// No description provided for @achViewGames.
  ///
  /// In pt, this message translates to:
  /// **'Ver os jogos'**
  String get achViewGames;

  /// No description provided for @achExactTitle.
  ///
  /// In pt, this message translates to:
  /// **'Placares Exatos'**
  String get achExactTitle;

  /// No description provided for @achExactDesc.
  ///
  /// In pt, this message translates to:
  /// **'Crave placares exatos'**
  String get achExactDesc;

  /// No description provided for @achEmpateName.
  ///
  /// In pt, this message translates to:
  /// **'Sabia do Empate'**
  String get achEmpateName;

  /// No description provided for @achEmpateDesc.
  ///
  /// In pt, this message translates to:
  /// **'Crave um empate'**
  String get achEmpateDesc;

  /// No description provided for @achOusadiaName.
  ///
  /// In pt, this message translates to:
  /// **'Ousadia e Alegria'**
  String get achOusadiaName;

  /// No description provided for @achOusadiaDesc.
  ///
  /// In pt, this message translates to:
  /// **'Crave um palpite ousado (≥5 de diferença ou ≥7 gols)'**
  String get achOusadiaDesc;

  /// No description provided for @achEmbaladoName.
  ///
  /// In pt, this message translates to:
  /// **'Embalado'**
  String get achEmbaladoName;

  /// No description provided for @achEmbaladoDesc.
  ///
  /// In pt, this message translates to:
  /// **'Pontue em vários jogos seguidos'**
  String get achEmbaladoDesc;

  /// No description provided for @achPequenteName.
  ///
  /// In pt, this message translates to:
  /// **'Pé-quente'**
  String get achPequenteName;

  /// No description provided for @achPequenteDesc.
  ///
  /// In pt, this message translates to:
  /// **'Pontue em 5 jogos seguidos'**
  String get achPequenteDesc;

  /// No description provided for @achDiaCheioName.
  ///
  /// In pt, this message translates to:
  /// **'Dia Cheio'**
  String get achDiaCheioName;

  /// No description provided for @achDiaCheioDesc.
  ///
  /// In pt, this message translates to:
  /// **'Pontue em todos os jogos de um dia (com 3+ jogos)'**
  String get achDiaCheioDesc;

  /// No description provided for @achVoltaName.
  ///
  /// In pt, this message translates to:
  /// **'Volta ao Mundo'**
  String get achVoltaName;

  /// No description provided for @achVoltaDesc.
  ///
  /// In pt, this message translates to:
  /// **'Pontue em todos os grupos'**
  String get achVoltaDesc;

  /// No description provided for @achDonoName.
  ///
  /// In pt, this message translates to:
  /// **'Dono do Grupo'**
  String get achDonoName;

  /// No description provided for @achDonoDesc.
  ///
  /// In pt, this message translates to:
  /// **'Faça 6+ pontos num grupo'**
  String get achDonoDesc;

  /// No description provided for @achBrasilName.
  ///
  /// In pt, this message translates to:
  /// **'Coração Verde-Amarelo'**
  String get achBrasilName;

  /// No description provided for @achBrasilDesc.
  ///
  /// In pt, this message translates to:
  /// **'Pontue num jogo do Brasil'**
  String get achBrasilDesc;

  /// No description provided for @achProfetaName.
  ///
  /// In pt, this message translates to:
  /// **'Profeta'**
  String get achProfetaName;

  /// No description provided for @achProfetaDesc.
  ///
  /// In pt, this message translates to:
  /// **'Crave um placar que menos de 10% cravou'**
  String get achProfetaDesc;

  /// No description provided for @achPanelaName.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo à Panela'**
  String get achPanelaName;

  /// No description provided for @achPanelaDesc.
  ///
  /// In pt, this message translates to:
  /// **'Entre em uma liga'**
  String get achPanelaDesc;

  /// No description provided for @achMeioSeculoName.
  ///
  /// In pt, this message translates to:
  /// **'Tá chovendo pontos'**
  String get achMeioSeculoName;

  /// No description provided for @achMeioSeculoDesc.
  ///
  /// In pt, this message translates to:
  /// **'Alcance 50 pontos no total'**
  String get achMeioSeculoDesc;

  /// No description provided for @achQuaseName.
  ///
  /// In pt, this message translates to:
  /// **'Quase Lá'**
  String get achQuaseName;

  /// No description provided for @achQuaseDesc.
  ///
  /// In pt, this message translates to:
  /// **'Acumule 5 \"quases\" (errou o placar por 1 gol)'**
  String get achQuaseDesc;

  /// No description provided for @achNewUnlocked.
  ///
  /// In pt, this message translates to:
  /// **'Nova conquista!'**
  String get achNewUnlocked;

  /// No description provided for @achNice.
  ///
  /// In pt, this message translates to:
  /// **'Boa!'**
  String get achNice;

  /// No description provided for @achViewAchievement.
  ///
  /// In pt, this message translates to:
  /// **'Ver conquista'**
  String get achViewAchievement;

  /// No description provided for @achClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get achClose;

  /// No description provided for @statPointsUnit.
  ///
  /// In pt, this message translates to:
  /// **'pts'**
  String get statPointsUnit;

  /// No description provided for @statsYou.
  ///
  /// In pt, this message translates to:
  /// **'Você'**
  String get statsYou;

  /// No description provided for @statsSeeAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos'**
  String get statsSeeAll;

  /// No description provided for @statsSeeMore.
  ///
  /// In pt, this message translates to:
  /// **'Ver mais'**
  String get statsSeeMore;

  /// No description provided for @statsSeeLess.
  ///
  /// In pt, this message translates to:
  /// **'Ver menos'**
  String get statsSeeLess;

  /// No description provided for @statsComingSoon.
  ///
  /// In pt, this message translates to:
  /// **'Em breve, nesta aba!'**
  String get statsComingSoon;

  /// No description provided for @statsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há dados suficientes'**
  String get statsEmpty;

  /// No description provided for @statsError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar'**
  String get statsError;

  /// No description provided for @deleteBet.
  ///
  /// In pt, this message translates to:
  /// **'Deletar Aposta'**
  String get deleteBet;

  /// No description provided for @deleteBetConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja apagar sua aposta para este jogo?'**
  String get deleteBetConfirm;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// No description provided for @helpAndRules.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda / Regras'**
  String get helpAndRules;

  /// No description provided for @helpScoring.
  ///
  /// In pt, this message translates to:
  /// **'Pontuação'**
  String get helpScoring;

  /// No description provided for @helpScoringDesc.
  ///
  /// In pt, this message translates to:
  /// **'Você ganha 3 pontos se acertar o placar exato. Se errar o placar, mas acertar o vencedor (ou o empate), você ganha 1 ponto.'**
  String get helpScoringDesc;

  /// No description provided for @helpDeadlines.
  ///
  /// In pt, this message translates to:
  /// **'Prazo das Apostas'**
  String get helpDeadlines;

  /// No description provided for @helpDeadlinesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Todas as apostas devem ser feitas até {date} no horário {gmt}. Após esta data, apenas será possível alterar uma aposta utilizando um Super Palpite.'**
  String helpDeadlinesDesc(String date, String gmt);

  /// No description provided for @helpSuperPalpites.
  ///
  /// In pt, this message translates to:
  /// **'Super Palpites'**
  String get helpSuperPalpites;

  /// No description provided for @helpSuperPalpitesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Após o bloqueio global, você tem direito a algumas alterações de emergência chamadas Super Palpites. Para um determinado jogo, o Super Palpite deve ser utilizado até 1 hora antes do horário da partida, depois disso não será mais possível alterar.'**
  String get helpSuperPalpitesDesc;

  /// No description provided for @helpAgentOfChaosTitle.
  ///
  /// In pt, this message translates to:
  /// **'Agente do Caos 🎲'**
  String get helpAgentOfChaosTitle;

  /// No description provided for @helpAgentOfChaosDesc.
  ///
  /// In pt, this message translates to:
  /// **'O Agente do Caos tem 2 modos: preencher todas as apostas para você aleatoriamente, ou preencher as apostas com base na classificação final que você indicar. O limite máximo de gols é preenchido na seção de configuração.'**
  String get helpAgentOfChaosDesc;

  /// No description provided for @helpEasyBetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aposta Fácil ⚡'**
  String get helpEasyBetTitle;

  /// No description provided for @helpEasyBetDesc.
  ///
  /// In pt, this message translates to:
  /// **'Enquanto o botão de Aposta Fácil estiver ativo, você pode apostar apenas clicando nas bandeiras (ou no \'X\' central) e o Agente do Caos definirá o placar automaticamente. O limite máximo de gols é preenchido na seção de configuração.'**
  String get helpEasyBetDesc;

  /// No description provided for @easyBet.
  ///
  /// In pt, this message translates to:
  /// **'Aposta Fácil'**
  String get easyBet;

  /// No description provided for @helpLeaguesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ligas Privadas'**
  String get helpLeaguesTitle;

  /// No description provided for @helpLeaguesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Crie ou participe de ligas privadas usando um código de convite para competir com seus amigos.'**
  String get helpLeaguesDesc;

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Make Bolão Great Again'**
  String get appTitle;

  /// No description provided for @exportError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao capturar imagem: {error}'**
  String exportError(String error);

  /// No description provided for @exportStarted.
  ///
  /// In pt, this message translates to:
  /// **'Download iniciado! Verifique sua pasta de downloads.'**
  String get exportStarted;

  /// No description provided for @exportBets.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Apostas'**
  String get exportBets;

  /// No description provided for @downloadImage.
  ///
  /// In pt, this message translates to:
  /// **'Baixar Imagem'**
  String get downloadImage;

  /// No description provided for @shareWhatsApp.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar no WhatsApp'**
  String get shareWhatsApp;

  /// No description provided for @settingsSaved.
  ///
  /// In pt, this message translates to:
  /// **'Configurações salvas com sucesso!'**
  String get settingsSaved;

  /// No description provided for @discardChangesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Descartar alterações?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesDesc.
  ///
  /// In pt, this message translates to:
  /// **'As alterações não salvas serão perdidas.'**
  String get discardChangesDesc;

  /// No description provided for @no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get no;

  /// No description provided for @yesDiscard.
  ///
  /// In pt, this message translates to:
  /// **'Sim, descartar'**
  String get yesDiscard;

  /// No description provided for @currentTimeZone.
  ///
  /// In pt, this message translates to:
  /// **'Fuso Horário Atual'**
  String get currentTimeZone;

  /// No description provided for @exportMyBets.
  ///
  /// In pt, this message translates to:
  /// **'Exportar minhas apostas'**
  String get exportMyBets;

  /// No description provided for @exportMyBetsSub.
  ///
  /// In pt, this message translates to:
  /// **'Gere uma imagem para salvar ou compartilhar!'**
  String get exportMyBetsSub;

  /// No description provided for @exportBetsOf.
  ///
  /// In pt, this message translates to:
  /// **'Apostas de {userName}'**
  String exportBetsOf(String userName);

  /// No description provided for @exportGroupTitle.
  ///
  /// In pt, this message translates to:
  /// **'GRUPO {group}'**
  String exportGroupTitle(String group);

  /// No description provided for @nextMatch.
  ///
  /// In pt, this message translates to:
  /// **'Próximo Jogo'**
  String get nextMatch;

  /// No description provided for @matchesOfDay.
  ///
  /// In pt, this message translates to:
  /// **'Jogos do dia'**
  String get matchesOfDay;

  /// No description provided for @yourPrediction.
  ///
  /// In pt, this message translates to:
  /// **'Seu palpite'**
  String get yourPrediction;

  /// No description provided for @makeYourPrediction.
  ///
  /// In pt, this message translates to:
  /// **'Faça seu palpite'**
  String get makeYourPrediction;

  /// No description provided for @previousGroup.
  ///
  /// In pt, this message translates to:
  /// **'Grupo anterior'**
  String get previousGroup;

  /// No description provided for @nextGroup.
  ///
  /// In pt, this message translates to:
  /// **'Próximo grupo'**
  String get nextGroup;

  /// No description provided for @searchPlayer.
  ///
  /// In pt, this message translates to:
  /// **'Buscar jogador...'**
  String get searchPlayer;

  /// No description provided for @youLabel.
  ///
  /// In pt, this message translates to:
  /// **'Você'**
  String get youLabel;

  /// No description provided for @exportRanking.
  ///
  /// In pt, this message translates to:
  /// **'Exportar classificação'**
  String get exportRanking;

  /// No description provided for @exportRankingOf.
  ///
  /// In pt, this message translates to:
  /// **'Classificação: {leagueName}'**
  String exportRankingOf(String leagueName);

  /// No description provided for @newPassword.
  ///
  /// In pt, this message translates to:
  /// **'Nova Senha'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Senha'**
  String get confirmPassword;

  /// No description provided for @waitDataLoad.
  ///
  /// In pt, this message translates to:
  /// **'Aguarde os dados carregarem primeiro...'**
  String get waitDataLoad;

  /// No description provided for @changePassword.
  ///
  /// In pt, this message translates to:
  /// **'Trocar Senha'**
  String get changePassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos 6 caracteres.'**
  String get passwordMinLength;

  /// No description provided for @passwordsMismatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem.'**
  String get passwordsMismatch;

  /// No description provided for @passwordUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Senha atualizada com sucesso!'**
  String get passwordUpdated;

  /// No description provided for @portuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get portuguese;

  /// No description provided for @english.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @italian.
  ///
  /// In pt, this message translates to:
  /// **'Italiano'**
  String get italian;

  /// No description provided for @notifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma notificação'**
  String get noNotifications;

  /// No description provided for @markAsRead.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como lida'**
  String get markAsRead;

  /// No description provided for @close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;

  /// No description provided for @followStandings.
  ///
  /// In pt, this message translates to:
  /// **'Seguir uma Classificação'**
  String get followStandings;

  /// No description provided for @followStandingsSub.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a ordem final e geramos os placares para você'**
  String get followStandingsSub;

  /// No description provided for @desiredStandings.
  ///
  /// In pt, this message translates to:
  /// **'Classificação Desejada'**
  String get desiredStandings;

  /// No description provided for @dragTeams.
  ///
  /// In pt, this message translates to:
  /// **'Arraste os times para a ordem exata que você deseja vê-los terminarem na tabela.'**
  String get dragTeams;

  /// No description provided for @generateChaos.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Caos'**
  String get generateChaos;

  /// No description provided for @deleteGroup.
  ///
  /// In pt, this message translates to:
  /// **'Deletar Grupo'**
  String get deleteGroup;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja deletar todas as apostas deste grupo?'**
  String get deleteGroupConfirm;

  /// No description provided for @deleteAllBets.
  ///
  /// In pt, this message translates to:
  /// **'Deletar todas apostas'**
  String get deleteAllBets;

  /// No description provided for @rankingBetsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 aposta} other{{count} apostas}}'**
  String rankingBetsCount(int count);

  /// No description provided for @statusScheduled.
  ///
  /// In pt, this message translates to:
  /// **'Agendado'**
  String get statusScheduled;

  /// No description provided for @statusLive.
  ///
  /// In pt, this message translates to:
  /// **'Ao Vivo 🔴'**
  String get statusLive;

  /// No description provided for @statusFinished.
  ///
  /// In pt, this message translates to:
  /// **'Encerrado'**
  String get statusFinished;

  /// No description provided for @teamMexico.
  ///
  /// In pt, this message translates to:
  /// **'México'**
  String get teamMexico;

  /// No description provided for @teamSouthAfrica.
  ///
  /// In pt, this message translates to:
  /// **'África do Sul'**
  String get teamSouthAfrica;

  /// No description provided for @teamSouthKorea.
  ///
  /// In pt, this message translates to:
  /// **'Coreia do Sul'**
  String get teamSouthKorea;

  /// No description provided for @teamCzechia.
  ///
  /// In pt, this message translates to:
  /// **'Chéquia'**
  String get teamCzechia;

  /// No description provided for @teamCanada.
  ///
  /// In pt, this message translates to:
  /// **'Canadá'**
  String get teamCanada;

  /// No description provided for @teamSwitzerland.
  ///
  /// In pt, this message translates to:
  /// **'Suíça'**
  String get teamSwitzerland;

  /// No description provided for @teamQatar.
  ///
  /// In pt, this message translates to:
  /// **'Catar'**
  String get teamQatar;

  /// No description provided for @teamBosniaAndHerzegovina.
  ///
  /// In pt, this message translates to:
  /// **'Bósnia e Herzegovina'**
  String get teamBosniaAndHerzegovina;

  /// No description provided for @teamBrazil.
  ///
  /// In pt, this message translates to:
  /// **'Brasil'**
  String get teamBrazil;

  /// No description provided for @teamMorocco.
  ///
  /// In pt, this message translates to:
  /// **'Marrocos'**
  String get teamMorocco;

  /// No description provided for @teamHaiti.
  ///
  /// In pt, this message translates to:
  /// **'Haiti'**
  String get teamHaiti;

  /// No description provided for @teamScotland.
  ///
  /// In pt, this message translates to:
  /// **'Escócia'**
  String get teamScotland;

  /// No description provided for @teamUnitedStates.
  ///
  /// In pt, this message translates to:
  /// **'Estados Unidos'**
  String get teamUnitedStates;

  /// No description provided for @teamParaguay.
  ///
  /// In pt, this message translates to:
  /// **'Paraguai'**
  String get teamParaguay;

  /// No description provided for @teamAustralia.
  ///
  /// In pt, this message translates to:
  /// **'Austrália'**
  String get teamAustralia;

  /// No description provided for @teamTurkiye.
  ///
  /// In pt, this message translates to:
  /// **'Turquia'**
  String get teamTurkiye;

  /// No description provided for @teamGermany.
  ///
  /// In pt, this message translates to:
  /// **'Alemanha'**
  String get teamGermany;

  /// No description provided for @teamCuracao.
  ///
  /// In pt, this message translates to:
  /// **'Curaçao'**
  String get teamCuracao;

  /// No description provided for @teamIvoryCoast.
  ///
  /// In pt, this message translates to:
  /// **'Costa do Marfim'**
  String get teamIvoryCoast;

  /// No description provided for @teamEcuador.
  ///
  /// In pt, this message translates to:
  /// **'Equador'**
  String get teamEcuador;

  /// No description provided for @teamNetherlands.
  ///
  /// In pt, this message translates to:
  /// **'Holanda'**
  String get teamNetherlands;

  /// No description provided for @teamJapan.
  ///
  /// In pt, this message translates to:
  /// **'Japão'**
  String get teamJapan;

  /// No description provided for @teamSweden.
  ///
  /// In pt, this message translates to:
  /// **'Suécia'**
  String get teamSweden;

  /// No description provided for @teamTunisia.
  ///
  /// In pt, this message translates to:
  /// **'Tunísia'**
  String get teamTunisia;

  /// No description provided for @teamBelgium.
  ///
  /// In pt, this message translates to:
  /// **'Bélgica'**
  String get teamBelgium;

  /// No description provided for @teamEgypt.
  ///
  /// In pt, this message translates to:
  /// **'Egito'**
  String get teamEgypt;

  /// No description provided for @teamIRIran.
  ///
  /// In pt, this message translates to:
  /// **'Irã'**
  String get teamIRIran;

  /// No description provided for @teamNewZealand.
  ///
  /// In pt, this message translates to:
  /// **'Nova Zelândia'**
  String get teamNewZealand;

  /// No description provided for @teamSpain.
  ///
  /// In pt, this message translates to:
  /// **'Espanha'**
  String get teamSpain;

  /// No description provided for @teamCaboVerde.
  ///
  /// In pt, this message translates to:
  /// **'Cabo Verde'**
  String get teamCaboVerde;

  /// No description provided for @teamSaudiArabia.
  ///
  /// In pt, this message translates to:
  /// **'Arábia Saudita'**
  String get teamSaudiArabia;

  /// No description provided for @teamUruguay.
  ///
  /// In pt, this message translates to:
  /// **'Uruguai'**
  String get teamUruguay;

  /// No description provided for @teamFrance.
  ///
  /// In pt, this message translates to:
  /// **'França'**
  String get teamFrance;

  /// No description provided for @teamSenegal.
  ///
  /// In pt, this message translates to:
  /// **'Senegal'**
  String get teamSenegal;

  /// No description provided for @teamIraq.
  ///
  /// In pt, this message translates to:
  /// **'Iraque'**
  String get teamIraq;

  /// No description provided for @teamNorway.
  ///
  /// In pt, this message translates to:
  /// **'Noruega'**
  String get teamNorway;

  /// No description provided for @teamArgentina.
  ///
  /// In pt, this message translates to:
  /// **'Argentina'**
  String get teamArgentina;

  /// No description provided for @teamAlgeria.
  ///
  /// In pt, this message translates to:
  /// **'Argélia'**
  String get teamAlgeria;

  /// No description provided for @teamAustria.
  ///
  /// In pt, this message translates to:
  /// **'Áustria'**
  String get teamAustria;

  /// No description provided for @teamJordan.
  ///
  /// In pt, this message translates to:
  /// **'Jordânia'**
  String get teamJordan;

  /// No description provided for @teamPortugal.
  ///
  /// In pt, this message translates to:
  /// **'Portugal'**
  String get teamPortugal;

  /// No description provided for @teamDRCongo.
  ///
  /// In pt, this message translates to:
  /// **'RD Congo'**
  String get teamDRCongo;

  /// No description provided for @teamUzbekistan.
  ///
  /// In pt, this message translates to:
  /// **'Uzbequistão'**
  String get teamUzbekistan;

  /// No description provided for @teamColombia.
  ///
  /// In pt, this message translates to:
  /// **'Colômbia'**
  String get teamColombia;

  /// No description provided for @teamEngland.
  ///
  /// In pt, this message translates to:
  /// **'Inglaterra'**
  String get teamEngland;

  /// No description provided for @teamCroatia.
  ///
  /// In pt, this message translates to:
  /// **'Croácia'**
  String get teamCroatia;

  /// No description provided for @teamGhana.
  ///
  /// In pt, this message translates to:
  /// **'Gana'**
  String get teamGhana;

  /// No description provided for @teamPanama.
  ///
  /// In pt, this message translates to:
  /// **'Panamá'**
  String get teamPanama;

  /// No description provided for @paymentPixTitle.
  ///
  /// In pt, this message translates to:
  /// **'Para usuários brasileiros, pagamento via pix.'**
  String get paymentPixTitle;

  /// No description provided for @paymentPixKey.
  ///
  /// In pt, this message translates to:
  /// **'chave: pix@example.com'**
  String get paymentPixKey;

  /// No description provided for @paymentPixScan.
  ///
  /// In pt, this message translates to:
  /// **'Ou escaneie o QR-Code abaixo'**
  String get paymentPixScan;

  /// No description provided for @paymentIbanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Para usuários europeus, pagamento via transferência'**
  String get paymentIbanTitle;

  /// No description provided for @paymentIbanKey.
  ///
  /// In pt, this message translates to:
  /// **'IBAN: IT93W0364601600526228392905'**
  String get paymentIbanKey;

  /// No description provided for @copiedToClipboard.
  ///
  /// In pt, this message translates to:
  /// **'Copiado para a área de transferência!'**
  String get copiedToClipboard;

  /// No description provided for @paymentPixAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor: R\$ 20,00'**
  String get paymentPixAmount;

  /// No description provided for @paymentIbanAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor: € 5,00'**
  String get paymentIbanAmount;

  /// No description provided for @firstName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In pt, this message translates to:
  /// **'Sobrenome'**
  String get lastName;

  /// No description provided for @displayAs.
  ///
  /// In pt, this message translates to:
  /// **'Aparecer no ranking como:'**
  String get displayAs;

  /// No description provided for @displayAsUsername.
  ///
  /// In pt, this message translates to:
  /// **'Nome de Usuário'**
  String get displayAsUsername;

  /// No description provided for @displayAsFullName.
  ///
  /// In pt, this message translates to:
  /// **'Nome Completo'**
  String get displayAsFullName;

  /// No description provided for @completeProfileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Complete seu Perfil'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileDesc.
  ///
  /// In pt, this message translates to:
  /// **'Precisamos do seu nome para facilitar a identificação nos pagamentos e no ranking.'**
  String get completeProfileDesc;

  /// No description provided for @nameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Preencha seu nome e sobrenome'**
  String get nameRequired;

  /// No description provided for @phoneLabel.
  ///
  /// In pt, this message translates to:
  /// **'Telefone / WhatsApp'**
  String get phoneLabel;

  /// No description provided for @phoneRequired.
  ///
  /// In pt, this message translates to:
  /// **'Por favor, insira seu telefone'**
  String get phoneRequired;

  /// No description provided for @phoneInvalidBr.
  ///
  /// In pt, this message translates to:
  /// **'Telefone inválido. Use DDD + número (11 dígitos).'**
  String get phoneInvalidBr;

  /// No description provided for @editProfile.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar Dados Pessoais'**
  String get editProfile;

  /// No description provided for @leaveLeague.
  ///
  /// In pt, this message translates to:
  /// **'Sair da liga'**
  String get leaveLeague;

  /// No description provided for @leaveLeagueConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja sair desta liga?'**
  String get leaveLeagueConfirm;

  /// No description provided for @paymentPending.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento Pendente'**
  String get paymentPending;

  /// No description provided for @paymentRealized.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento Realizado'**
  String get paymentRealized;

  /// No description provided for @adminTabMatches.
  ///
  /// In pt, this message translates to:
  /// **'Partidas'**
  String get adminTabMatches;

  /// No description provided for @adminTabUsers.
  ///
  /// In pt, this message translates to:
  /// **'Usuários'**
  String get adminTabUsers;

  /// No description provided for @exportData.
  ///
  /// In pt, this message translates to:
  /// **'Exportar CSV'**
  String get exportData;

  /// No description provided for @searchUsers.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por usuário, e-mail ou nome...'**
  String get searchUsers;

  /// No description provided for @visitorMode.
  ///
  /// In pt, this message translates to:
  /// **'visitante'**
  String get visitorMode;

  /// No description provided for @yourBet.
  ///
  /// In pt, this message translates to:
  /// **'Você'**
  String get yourBet;

  /// No description provided for @partial.
  ///
  /// In pt, this message translates to:
  /// **'parcial'**
  String get partial;

  /// No description provided for @liveNow.
  ///
  /// In pt, this message translates to:
  /// **'AO VIVO'**
  String get liveNow;

  /// No description provided for @finalLabel.
  ///
  /// In pt, this message translates to:
  /// **'FINAL'**
  String get finalLabel;

  /// No description provided for @versusShort.
  ///
  /// In pt, this message translates to:
  /// **'vs'**
  String get versusShort;

  /// No description provided for @hiddenUntilKickoff.
  ///
  /// In pt, this message translates to:
  /// **'Oculto até o jogo começar'**
  String get hiddenUntilKickoff;

  /// No description provided for @completeBetsToView.
  ///
  /// In pt, this message translates to:
  /// **'Complete suas apostas para ver as dos outros'**
  String get completeBetsToView;

  /// No description provided for @completeBetsToViewSub.
  ///
  /// In pt, this message translates to:
  /// **'Você precisa preencher pelo menos 65 das suas apostas para visualizar os palpites dos outros participantes.'**
  String get completeBetsToViewSub;

  /// No description provided for @rankPositionShort.
  ///
  /// In pt, this message translates to:
  /// **'{rank}º lugar'**
  String rankPositionShort(int rank);

  /// No description provided for @errGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado. Tente novamente.'**
  String get errGeneric;

  /// No description provided for @errConnection.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão. Verifique sua internet e tente novamente.'**
  String get errConnection;

  /// No description provided for @errAuth.
  ///
  /// In pt, this message translates to:
  /// **'Falha na autenticação. Verifique seus dados e tente novamente.'**
  String get errAuth;

  /// No description provided for @errBetMatchStarted.
  ///
  /// In pt, this message translates to:
  /// **'Este jogo já começou ou foi encerrado — não é possível alterar o palpite.'**
  String get errBetMatchStarted;

  /// No description provided for @errBetDeadlinePassed.
  ///
  /// In pt, this message translates to:
  /// **'O prazo para alterar este palpite expirou (menos de 1 hora para o início).'**
  String get errBetDeadlinePassed;

  /// No description provided for @errSuperPalpiteLimit.
  ///
  /// In pt, this message translates to:
  /// **'Você já usou seus 10 Super Palpites.'**
  String get errSuperPalpiteLimit;

  /// No description provided for @errSyncFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível sincronizar a planilha. Verifique a conexão e tente novamente.'**
  String get errSyncFailed;

  /// No description provided for @filterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get filterAll;

  /// No description provided for @filterRound1.
  ///
  /// In pt, this message translates to:
  /// **'Rodada 1'**
  String get filterRound1;

  /// No description provided for @filterRound2.
  ///
  /// In pt, this message translates to:
  /// **'Rodada 2'**
  String get filterRound2;

  /// No description provided for @filterRound3.
  ///
  /// In pt, this message translates to:
  /// **'Rodada 3'**
  String get filterRound3;

  /// No description provided for @filterDay.
  ///
  /// In pt, this message translates to:
  /// **'Do dia'**
  String get filterDay;

  /// No description provided for @filterFinished.
  ///
  /// In pt, this message translates to:
  /// **'Finalizados'**
  String get filterFinished;

  /// No description provided for @filterUnfinished.
  ///
  /// In pt, this message translates to:
  /// **'Não finalizados'**
  String get filterUnfinished;

  /// No description provided for @filterExact.
  ///
  /// In pt, this message translates to:
  /// **'Placar exato'**
  String get filterExact;

  /// No description provided for @filterResult.
  ///
  /// In pt, this message translates to:
  /// **'Resultado'**
  String get filterResult;

  /// No description provided for @filterLost.
  ///
  /// In pt, this message translates to:
  /// **'Perdida'**
  String get filterLost;

  /// No description provided for @filterNoGames.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum jogo com esses filtros'**
  String get filterNoGames;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

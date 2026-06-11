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
  /// **'Por grupo, rodada, seleção — em breve!'**
  String get advancedStatsSub;

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
  /// **'Você precisa preencher todas as suas apostas para visualizar os palpites dos outros participantes.'**
  String get completeBetsToViewSub;

  /// No description provided for @rankPositionShort.
  ///
  /// In pt, this message translates to:
  /// **'{rank}º lugar'**
  String rankPositionShort(int rank);
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

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
  /// **'Deletar'**
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
  /// **'As apostas fecham antes de cada partida. Fique atento aos horários de encerramento!'**
  String get helpDeadlinesDesc;

  /// No description provided for @helpSuperPalpites.
  ///
  /// In pt, this message translates to:
  /// **'Super Palpites'**
  String get helpSuperPalpites;

  /// No description provided for @helpSuperPalpitesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Após o bloqueio global, você tem direito a algumas alterações de emergência chamadas Super Palpites. Use-os com sabedoria!'**
  String get helpSuperPalpitesDesc;

  /// No description provided for @helpAgentOfChaosTitle.
  ///
  /// In pt, this message translates to:
  /// **'Agent of Chaos 🎲'**
  String get helpAgentOfChaosTitle;

  /// No description provided for @helpAgentOfChaosDesc.
  ///
  /// In pt, this message translates to:
  /// **'Se estiver com preguiça, use o botão de dado para preencher tudo aleatoriamente! Você também pode tocar na bandeira (ou no \'X\') no cartão do jogo para forçar uma vitória/empate aleatório.'**
  String get helpAgentOfChaosDesc;

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
  /// **'Nenhuma notificação.'**
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

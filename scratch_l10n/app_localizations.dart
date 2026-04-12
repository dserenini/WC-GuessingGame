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
/// import './app_localizations.dart';
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

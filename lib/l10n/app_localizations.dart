import 'package:flutter/widgets.dart';

class AppLocalizations {
  static AppLocalizations? of(BuildContext context) => AppLocalizations();
  String get loginSubtitle => "Aposte no seu grupo com os amigos";
  String get login => "Entrar";
  String get signUp => "Cadastrar";
  String get email => "E-mail";
  String get password => "Senha";
  String get username => "Nome de usuário";
  String get confirm => "Confirmar";
  String get cancel => "Cancelar";
  String get yes => "Sim, vai fundo!";
  String get save => "Salvar";
  String get group => "Grupo";
  String get groups => "GRUPOS";
  String get ranking => "Ranking";
  String get privateLeagues => "Ligas Privadas";
  String get settings => "Configurações";
  String get adminPanel => "Painel Admin";
  String get signOut => "Sair";
  String get betsLocked => "Apostas encerradas — prazo expirado";
  String get betsOpen => "Apostas abertas";
  String get betDeadline => "Prazo das Apostas";
  String get result => "Resultado";
  String get agentOfChaos => "Agente do Caos";
  String get chaosRandomAll => "Aleatorizar tudo";
  String get chaosRandomAllSub => "Preenche placares vazios aleatoriamente";
  String get chaosGuidedHint => "Toque na bandeira para vitória aleatória. Toque no 'X' para empate aleatório.";
  String get chaosMaxGoals => "Bolas no máximo";
  String get wackyGoalAlert => "Você está colocando mais de 20 gols... É sério isso? 😱";
  String get appearance => "Aparência";
  String get themeSystem => "Sistema";
  String get themeLight => "Claro";
  String get themeDark => "Escuro";
  String get language => "Idioma";
  String get account => "Conta";
  String get joinLeague => "Entrar em liga";
  String get createLeague => "Criar liga";
  String get joinOrCreate => "Entrar ou criar";
  String get inviteCode => "Código de convite";
  String get leagueName => "Nome da liga";
  String get noLeagues => "Nenhuma liga ainda";
  String get noLeaguesSub => "Entre em uma liga com um código ou crie a sua";
  String get codeCopied => "Código copiado!";

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override bool isSupported(Locale locale) => true;
  @override Future<AppLocalizations> load(Locale locale) async => AppLocalizations();
  @override bool shouldReload(old) => false;
}

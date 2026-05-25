// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get loginSubtitle => 'Aposte no seu grupo com os amigos';

  @override
  String get login => 'Entrar';

  @override
  String get signUp => 'Cadastrar';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Senha';

  @override
  String get username => 'Nome de usuário';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get yes => 'Sim, vai fundo!';

  @override
  String get save => 'Salvar';

  @override
  String get group => 'Grupo';

  @override
  String get groups => 'GRUPOS';

  @override
  String get ranking => 'Ranking';

  @override
  String get privateLeagues => 'Ligas Privadas';

  @override
  String get settings => 'Configurações';

  @override
  String get adminPanel => 'Painel Admin';

  @override
  String get signOut => 'Sair';

  @override
  String get betsLocked => 'Apostas encerradas — prazo expirado';

  @override
  String get betsOpen => 'Apostas abertas';

  @override
  String get betDeadline => 'Prazo das Apostas';

  @override
  String get result => 'Resultado';

  @override
  String get agentOfChaos => 'Agente do Caos';

  @override
  String get chaosRandomAll => 'Aleatorizar tudo';

  @override
  String get chaosRandomAllSub => 'Preenche placares vazios aleatoriamente';

  @override
  String get chaosGuidedHint =>
      'Toque na bandeira para vitória aleatória. Toque no \'X\' para empate aleatório.';

  @override
  String get chaosMaxGoals => 'Bolas no máximo';

  @override
  String get wackyGoalAlert =>
      'Você está colocando mais de 20 gols... É sério isso? 😱';

  @override
  String get appearance => 'Aparência';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get language => 'Idioma';

  @override
  String get account => 'Conta';

  @override
  String get joinLeague => 'Entrar em liga';

  @override
  String get createLeague => 'Criar liga';

  @override
  String get joinOrCreate => 'Entrar ou criar';

  @override
  String get inviteCode => 'Código de convite';

  @override
  String get leagueName => 'Nome da liga';

  @override
  String get noLeagues => 'Nenhuma liga ainda';

  @override
  String get noLeaguesSub => 'Entre em uma liga com um código ou crie a sua';

  @override
  String get codeCopied => 'Código copiado!';

  @override
  String get myProfile => 'Meu Perfil';

  @override
  String get betsFilled => 'Apostas Preenchidas';

  @override
  String get totalPoints => 'Pontos Totais';

  @override
  String get exactHits => 'Acerto no Placar';

  @override
  String get resultHits => 'Acerto no Resultado';

  @override
  String get superPalpites => 'Super Palpites';

  @override
  String superPalpitesRemaining(int count) {
    return 'Você tem $count alterações após o prazo limite.';
  }

  @override
  String get forgotPassword => 'Esqueci minha senha';

  @override
  String get recoverPassword => 'Recuperar Senha';

  @override
  String get recoverPasswordHint =>
      'Digite o seu e-mail para receber um link de recuperação.';

  @override
  String get recoveryLinkSent =>
      'Link de recuperação enviado! Verifique seu e-mail.';

  @override
  String get send => 'Enviar';

  @override
  String errorGeneric(String error) {
    return 'Erro: $error';
  }

  @override
  String get invalidLogin => 'Login/Senha incorretos.';

  @override
  String get chooseLanguage => 'Escolha seu idioma';

  @override
  String get continueBtn => 'Continuar';

  @override
  String get advancedStats => 'Estatísticas Avançadas';

  @override
  String get advancedStatsSub => 'Por grupo, rodada, seleção — em breve!';

  @override
  String get deleteBet => 'Deletar Aposta';

  @override
  String get deleteBetConfirm => 'Deseja apagar sua aposta para este jogo?';

  @override
  String get delete => 'Deletar';

  @override
  String get helpAndRules => 'Ajuda / Regras';

  @override
  String get helpScoring => 'Pontuação';

  @override
  String get helpScoringDesc =>
      'Você ganha 3 pontos se acertar o placar exato. Se errar o placar, mas acertar o vencedor (ou o empate), você ganha 1 ponto.';

  @override
  String get helpDeadlines => 'Prazo das Apostas';

  @override
  String get helpDeadlinesDesc =>
      'As apostas fecham antes de cada partida. Fique atento aos horários de encerramento!';

  @override
  String get helpSuperPalpites => 'Super Palpites';

  @override
  String get helpSuperPalpitesDesc =>
      'Após o bloqueio global, você tem direito a algumas alterações de emergência chamadas Super Palpites. Use-os com sabedoria!';

  @override
  String get helpAgentOfChaosTitle => 'Agent of Chaos 🎲';

  @override
  String get helpAgentOfChaosDesc =>
      'Se estiver com preguiça, use o botão de dado para preencher tudo aleatoriamente! Você também pode tocar na bandeira (ou no \'X\') no cartão do jogo para forçar uma vitória/empate aleatório.';

  @override
  String get helpLeaguesTitle => 'Ligas Privadas';

  @override
  String get helpLeaguesDesc =>
      'Crie ou participe de ligas privadas usando um código de convite para competir com seus amigos.';

  @override
  String get appTitle => 'Make Bolão Great Again';

  @override
  String exportError(String error) {
    return 'Erro ao capturar imagem: $error';
  }

  @override
  String get exportStarted =>
      'Download iniciado! Verifique sua pasta de downloads.';

  @override
  String get exportBets => 'Exportar Apostas';

  @override
  String get downloadImage => 'Baixar Imagem';

  @override
  String get shareWhatsApp => 'Compartilhar no WhatsApp';

  @override
  String get settingsSaved => 'Configurações salvas com sucesso!';

  @override
  String get discardChangesTitle => 'Descartar alterações?';

  @override
  String get discardChangesDesc => 'As alterações não salvas serão perdidas.';

  @override
  String get no => 'Não';

  @override
  String get yesDiscard => 'Sim, descartar';

  @override
  String get currentTimeZone => 'Fuso Horário Atual';

  @override
  String get exportMyBets => 'Exportar minhas apostas';

  @override
  String get exportMyBetsSub => 'Gere uma imagem para salvar ou compartilhar!';

  @override
  String get waitDataLoad => 'Aguarde os dados carregarem primeiro...';

  @override
  String get changePassword => 'Trocar Senha';

  @override
  String get passwordMinLength => 'A senha deve ter pelo menos 6 caracteres.';

  @override
  String get passwordsMismatch => 'As senhas não coincidem.';

  @override
  String get passwordUpdated => 'Senha atualizada com sucesso!';

  @override
  String get portuguese => 'Português';

  @override
  String get english => 'English';

  @override
  String get italian => 'Italiano';

  @override
  String get notifications => 'Notificações';

  @override
  String get noNotifications => 'Nenhuma notificação.';

  @override
  String get markAsRead => 'Marcar como lida';

  @override
  String get close => 'Fechar';

  @override
  String get followStandings => 'Seguir uma Classificação';

  @override
  String get followStandingsSub =>
      'Escolha a ordem final e geramos os placares para você';

  @override
  String get desiredStandings => 'Classificação Desejada';

  @override
  String get dragTeams =>
      'Arraste os times para a ordem exata que você deseja vê-los terminarem na tabela.';

  @override
  String get generateChaos => 'Gerar Caos';

  @override
  String get deleteGroup => 'Deletar Grupo';

  @override
  String get deleteGroupConfirm =>
      'Tem certeza que deseja deletar todas as apostas deste grupo?';

  @override
  String get deleteAllBets => 'Deletar todas apostas';

  @override
  String rankingBetsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apostas',
      one: '1 aposta',
    );
    return '$_temp0';
  }

  @override
  String get statusScheduled => 'Agendado';

  @override
  String get statusLive => 'Ao Vivo 🔴';

  @override
  String get statusFinished => 'Encerrado';

  @override
  String get teamMexico => 'México';

  @override
  String get teamSouthAfrica => 'África do Sul';

  @override
  String get teamSouthKorea => 'Coreia do Sul';

  @override
  String get teamCzechia => 'Chéquia';

  @override
  String get teamCanada => 'Canadá';

  @override
  String get teamSwitzerland => 'Suíça';

  @override
  String get teamQatar => 'Catar';

  @override
  String get teamBosniaAndHerzegovina => 'Bósnia e Herzegovina';

  @override
  String get teamBrazil => 'Brasil';

  @override
  String get teamMorocco => 'Marrocos';

  @override
  String get teamHaiti => 'Haiti';

  @override
  String get teamScotland => 'Escócia';

  @override
  String get teamUnitedStates => 'Estados Unidos';

  @override
  String get teamParaguay => 'Paraguai';

  @override
  String get teamAustralia => 'Austrália';

  @override
  String get teamTurkiye => 'Turquia';

  @override
  String get teamGermany => 'Alemanha';

  @override
  String get teamCuracao => 'Curaçao';

  @override
  String get teamIvoryCoast => 'Costa do Marfim';

  @override
  String get teamEcuador => 'Equador';

  @override
  String get teamNetherlands => 'Holanda';

  @override
  String get teamJapan => 'Japão';

  @override
  String get teamSweden => 'Suécia';

  @override
  String get teamTunisia => 'Tunísia';

  @override
  String get teamBelgium => 'Bélgica';

  @override
  String get teamEgypt => 'Egito';

  @override
  String get teamIRIran => 'Irã';

  @override
  String get teamNewZealand => 'Nova Zelândia';

  @override
  String get teamSpain => 'Espanha';

  @override
  String get teamCaboVerde => 'Cabo Verde';

  @override
  String get teamSaudiArabia => 'Arábia Saudita';

  @override
  String get teamUruguay => 'Uruguai';

  @override
  String get teamFrance => 'França';

  @override
  String get teamSenegal => 'Senegal';

  @override
  String get teamIraq => 'Iraque';

  @override
  String get teamNorway => 'Noruega';

  @override
  String get teamArgentina => 'Argentina';

  @override
  String get teamAlgeria => 'Argélia';

  @override
  String get teamAustria => 'Áustria';

  @override
  String get teamJordan => 'Jordânia';

  @override
  String get teamPortugal => 'Portugal';

  @override
  String get teamDRCongo => 'RD Congo';

  @override
  String get teamUzbekistan => 'Uzbequistão';

  @override
  String get teamColombia => 'Colômbia';

  @override
  String get teamEngland => 'Inglaterra';

  @override
  String get teamCroatia => 'Croácia';

  @override
  String get teamGhana => 'Gana';

  @override
  String get teamPanama => 'Panamá';
}

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
  String get regularDeadlineClosed => 'Prazo regular encerrado';

  @override
  String get betsUseSuperPalpite => 'Novas apostas consomem Super Palpites';

  @override
  String get superPalpitesExhausted =>
      'Super Palpites esgotados — apostas bloqueadas';

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
  String get advancedStatsSub => 'Veja como você se compara ao bolão';

  @override
  String get statsTabRankings => 'Rankings';

  @override
  String get statsTabPersonal => 'Pessoal';

  @override
  String get statsTabAchievements => 'Conquistas';

  @override
  String get statsTabPool => 'Bolão';

  @override
  String get statExactTitle => 'Rei do Placar Exato';

  @override
  String get statExactSub => 'Quem mais cravou o placar';

  @override
  String get statExactUnit => 'exatos';

  @override
  String get statBrazilTitle => 'Pé-quente do Brasil';

  @override
  String get statBrazilSub => 'Quem mais pontuou nos jogos do Brasil';

  @override
  String get statNearMissTitle => 'Quase lá';

  @override
  String get statNearMissSub => 'Cravaria o resultado, mas ficou no quase por 1 gol';

  @override
  String get statNearMissUnit => 'quase';

  @override
  String get statDailyTitle => 'Tacada do Dia';

  @override
  String get statDailySub => 'Maior pontuação num único dia';

  @override
  String get statRegularTitle => 'Mais Regular';

  @override
  String get statRegularSub => 'Pontuou no maior número de jogos';

  @override
  String get statRegularUnit => 'jogos';

  @override
  String get statBoldTitle => 'Os Corajosos';

  @override
  String get statBoldSub => 'Quem arrisca os placares mais ousados';

  @override
  String get statBoldUnit => 'ousados';

  @override
  String get statContrarianTitle => 'Do Contra que Acertou';

  @override
  String get statContrarianSub => 'Cravou placares que quase ninguém apostou';

  @override
  String get statContrarianUnit => 'raras';

  @override
  String get statsNoGames => 'Nenhum jogo nesta estatística ainda';

  @override
  String get statsPersonalEmpty => 'Seus números aparecem conforme os jogos acontecem';

  @override
  String get statGroupPointsTitle => 'Pontos por Grupo';

  @override
  String get statGroupPointsSub => 'Onde você mais e menos pontuou';

  @override
  String get statDistributionTitle => 'Distribuição de Acertos';

  @override
  String get statDistributionSub => 'Exatos, resultados e erros';

  @override
  String get statDistResult => 'resultados';

  @override
  String get statDistZero => 'erros';

  @override
  String get statUtilization => 'Aproveitamento';

  @override
  String get statSignatureTitle => 'Placar-assinatura';

  @override
  String get statSignatureSub => 'O placar que você mais aposta';

  @override
  String get statHandTitle => 'Média de Gols';

  @override
  String get statHandSub => 'Sua média de gols por jogo vs a média da realidade';

  @override
  String get statHandReal => 'Real';

  @override
  String get statGoalsPerGame => 'gols/jogo';

  @override
  String get statLuckyTitle => 'Amuleto da Sorte / Azar';

  @override
  String get statLuckySub => 'Seleções onde você mais e menos pontua';

  @override
  String get statLucky => 'Sorte';

  @override
  String get statUnlucky => 'Azar';

  @override
  String get statStreakTitle => 'Maior Sequência';

  @override
  String get statStreakSub => 'Jogos seguidos pontuando';

  @override
  String get statBest => 'Melhor';

  @override
  String get statWorst => 'Pior';

  @override
  String get statBestPlural => 'Melhores';

  @override
  String get statWorstPlural => 'Piores';

  @override
  String get poolUnpredictableTitle => 'Jogos mais imprevisíveis';

  @override
  String get poolUnpredictableSub => 'Onde menos gente cravou o placar';

  @override
  String get poolEveryoneKnewTitle => 'Esse todo mundo sabia';

  @override
  String get poolEveryoneKnewSub => 'Onde mais gente cravou o placar';

  @override
  String get poolPopularTitle => 'Palpites mais populares';

  @override
  String get poolPopularSub => 'Os placares mais apostados do bolão';

  @override
  String get poolUniqueTitle => 'Palpites únicos';

  @override
  String get poolUniqueSub => 'Os placares mais raros do bolão';

  @override
  String get poolNailedLabel => 'cravaram';

  @override
  String get poolWhoNailed => 'Quem cravou';

  @override
  String get poolNobodyNailed => 'Ninguém cravou este jogo';

  @override
  String get poolLookupTitle => 'Consultar um placar';

  @override
  String get poolLookupHint => 'ex.: 1-1';

  @override
  String get poolLookupNotFound => 'Nenhum palpite com esse placar';

  @override
  String get achBronze => 'Bronze';

  @override
  String get achPrata => 'Prata';

  @override
  String get achOuro => 'Ouro';

  @override
  String get achRarityOf => 'dos jogadores';

  @override
  String get achUnlocked => 'Conquistado';

  @override
  String get achUnlockedOn => 'Conquistado em';

  @override
  String get achViewGames => 'Ver os jogos';

  @override
  String get achExactTitle => 'Placares Exatos';

  @override
  String get achExactDesc => 'Crave placares exatos';

  @override
  String get achEmpateName => 'Sabia do Empate';

  @override
  String get achEmpateDesc => 'Crave um empate';

  @override
  String get achOusadiaName => 'Ousadia e Alegria';

  @override
  String get achOusadiaDesc => 'Crave um palpite ousado (≥5 de diferença ou ≥7 gols)';

  @override
  String get achEmbaladoName => 'Embalado';

  @override
  String get achEmbaladoDesc => 'Pontue em vários jogos seguidos';

  @override
  String get achPequenteName => 'Pé-quente';

  @override
  String get achPequenteDesc => 'Pontue em 5 jogos seguidos';

  @override
  String get achDiaCheioName => 'Dia Cheio';

  @override
  String get achDiaCheioDesc => 'Pontue em todos os jogos de um dia';

  @override
  String get achVoltaName => 'Volta ao Mundo';

  @override
  String get achVoltaDesc => 'Pontue em todos os grupos';

  @override
  String get achDonoName => 'Dono do Grupo';

  @override
  String get achDonoDesc => 'Faça 6+ pontos num grupo';

  @override
  String get achBrasilName => 'Coração Verde-Amarelo';

  @override
  String get achBrasilDesc => 'Pontue num jogo do Brasil';

  @override
  String get achProfetaName => 'Profeta';

  @override
  String get achProfetaDesc => 'Crave um placar que menos de 10% cravou';

  @override
  String get achPanelaName => 'Bem-vindo à Panela';

  @override
  String get achPanelaDesc => 'Entre em uma liga';

  @override
  String get achMeioSeculoName => 'Tá chovendo pontos';

  @override
  String get achMeioSeculoDesc => 'Alcance 50 pontos no total';

  @override
  String get achQuaseName => 'Quase Lá';

  @override
  String get achQuaseDesc => 'Acumule 5 "quases" (errou o placar por 1 gol)';

  @override
  String get achNewUnlocked => 'Nova conquista!';

  @override
  String get achNice => 'Boa!';

  @override
  String get achViewAchievement => 'Ver conquista';

  @override
  String get achClose => 'Fechar';

  @override
  String get statPointsUnit => 'pts';

  @override
  String get statsYou => 'Você';

  @override
  String get statsSeeAll => 'Ver todos';

  @override
  String get statsSeeMore => 'Ver mais';

  @override
  String get statsSeeLess => 'Ver menos';

  @override
  String get statsComingSoon => 'Em breve, nesta aba!';

  @override
  String get statsEmpty => 'Ainda não há dados suficientes';

  @override
  String get statsError => 'Não foi possível carregar';

  @override
  String get deleteBet => 'Deletar Aposta';

  @override
  String get deleteBetConfirm => 'Deseja apagar sua aposta para este jogo?';

  @override
  String get delete => 'Excluir';

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
  String helpDeadlinesDesc(String date, String gmt) {
    return 'Todas as apostas devem ser feitas até $date no horário $gmt. Após esta data, apenas será possível alterar uma aposta utilizando um Super Palpite.';
  }

  @override
  String get helpSuperPalpites => 'Super Palpites';

  @override
  String get helpSuperPalpitesDesc =>
      'Após o bloqueio global, você tem direito a algumas alterações de emergência chamadas Super Palpites. Para um determinado jogo, o Super Palpite deve ser utilizado até 1 hora antes do horário da partida, depois disso não será mais possível alterar.';

  @override
  String get helpAgentOfChaosTitle => 'Agente do Caos 🎲';

  @override
  String get helpAgentOfChaosDesc =>
      'O Agente do Caos tem 2 modos: preencher todas as apostas para você aleatoriamente, ou preencher as apostas com base na classificação final que você indicar. O limite máximo de gols é preenchido na seção de configuração.';

  @override
  String get helpEasyBetTitle => 'Aposta Fácil ⚡';

  @override
  String get helpEasyBetDesc =>
      'Enquanto o botão de Aposta Fácil estiver ativo, você pode apostar apenas clicando nas bandeiras (ou no \'X\' central) e o Agente do Caos definirá o placar automaticamente. O limite máximo de gols é preenchido na seção de configuração.';

  @override
  String get easyBet => 'Aposta Fácil';

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
  String exportBetsOf(String userName) {
    return 'Apostas de $userName';
  }

  @override
  String exportGroupTitle(String group) {
    return 'GRUPO $group';
  }

  @override
  String get nextMatch => 'Próximo Jogo';

  @override
  String get matchesOfDay => 'Jogos do dia';

  @override
  String get yourPrediction => 'Seu palpite';

  @override
  String get makeYourPrediction => 'Faça seu palpite';

  @override
  String get previousGroup => 'Grupo anterior';

  @override
  String get nextGroup => 'Próximo grupo';

  @override
  String get searchPlayer => 'Buscar jogador...';

  @override
  String get youLabel => 'Você';

  @override
  String get exportRanking => 'Exportar classificação';

  @override
  String exportRankingOf(String leagueName) {
    return 'Classificação: $leagueName';
  }

  @override
  String get newPassword => 'Nova Senha';

  @override
  String get confirmPassword => 'Confirmar Senha';

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
  String get noNotifications => 'Nenhuma notificação';

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

  @override
  String get paymentPixTitle => 'Para usuários brasileiros, pagamento via pix.';

  @override
  String get paymentPixKey => 'chave: pix@example.com';

  @override
  String get paymentPixScan => 'Ou escaneie o QR-Code abaixo';

  @override
  String get paymentIbanTitle =>
      'Para usuários europeus, pagamento via transferência';

  @override
  String get paymentIbanKey => 'IBAN: IT93W0364601600526228392905';

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência!';

  @override
  String get paymentPixAmount => 'Valor: R\$ 20,00';

  @override
  String get paymentIbanAmount => 'Valor: € 5,00';

  @override
  String get firstName => 'Nome';

  @override
  String get lastName => 'Sobrenome';

  @override
  String get displayAs => 'Aparecer no ranking como:';

  @override
  String get displayAsUsername => 'Nome de Usuário';

  @override
  String get displayAsFullName => 'Nome Completo';

  @override
  String get completeProfileTitle => 'Complete seu Perfil';

  @override
  String get completeProfileDesc =>
      'Precisamos do seu nome para facilitar a identificação nos pagamentos e no ranking.';

  @override
  String get nameRequired => 'Preencha seu nome e sobrenome';

  @override
  String get phoneLabel => 'Telefone / WhatsApp';

  @override
  String get phoneRequired => 'Por favor, insira seu telefone';

  @override
  String get phoneInvalidBr =>
      'Telefone inválido. Use DDD + número (11 dígitos).';

  @override
  String get editProfile => 'Atualizar Dados Pessoais';

  @override
  String get leaveLeague => 'Sair da liga';

  @override
  String get leaveLeagueConfirm => 'Tem certeza que deseja sair desta liga?';

  @override
  String get paymentPending => 'Pagamento Pendente';

  @override
  String get paymentRealized => 'Pagamento Realizado';

  @override
  String get adminTabMatches => 'Partidas';

  @override
  String get adminTabUsers => 'Usuários';

  @override
  String get exportData => 'Exportar CSV';

  @override
  String get searchUsers => 'Buscar por usuário, e-mail ou nome...';

  @override
  String get visitorMode => 'visitante';

  @override
  String get yourBet => 'Você';

  @override
  String get partial => 'parcial';

  @override
  String get liveNow => 'AO VIVO';

  @override
  String get finalLabel => 'FINAL';

  @override
  String get versusShort => 'vs';

  @override
  String get hiddenUntilKickoff => 'Oculto até o jogo começar';

  @override
  String get completeBetsToView =>
      'Complete suas apostas para ver as dos outros';

  @override
  String get completeBetsToViewSub =>
      'Você precisa preencher todas as suas apostas para visualizar os palpites dos outros participantes.';

  @override
  String rankPositionShort(int rank) {
    return '$rankº lugar';
  }

  @override
  String get errGeneric => 'Algo deu errado. Tente novamente.';

  @override
  String get errConnection =>
      'Sem conexão. Verifique sua internet e tente novamente.';

  @override
  String get errAuth =>
      'Falha na autenticação. Verifique seus dados e tente novamente.';

  @override
  String get errBetMatchStarted =>
      'Este jogo já começou ou foi encerrado — não é possível alterar o palpite.';

  @override
  String get errBetDeadlinePassed =>
      'O prazo para alterar este palpite expirou (menos de 1 hora para o início).';

  @override
  String get errSuperPalpiteLimit => 'Você já usou seus 10 Super Palpites.';

  @override
  String get errSyncFailed =>
      'Não foi possível sincronizar a planilha. Verifique a conexão e tente novamente.';
}

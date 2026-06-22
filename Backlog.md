# Backlog de implementações (Bugs/Fix/Ajustes Necessários)
* **Página de Reset de Senha**: Melhorar a página e internacionalizar a página

# Implementado:


# Ideias Futuras de Implementação
* **Mapa de Classificação**: Criar um mapa de classificação com a chave dos classificados para a próxima fase para análise dos confrontos.

* **Estatísticas Avançadas** — tela dedicada com abas (Rankings · Pessoal · Conquistas · Bolão), entregue por família, uma de cada vez.

  **Princípio transversal:** toda estatística deve nascer preparada para, no futuro, ser filtrada **por liga** (além do bolão global) — espelhando o padrão de `league_rankings`, sem reescrever a UI.

  Legenda: 🔶 precisa de SQL novo (view/RPC) · ✅ client-side · ⚠️ expõe palpite alheio (respeitar reveal). _(Família D — cabeça a cabeça — descartada.)_

  **A. Você vs. o Bolão (rankings)** — ✅ **COMPLETA**
  - 👑 Rei do Placar Exato (`points=3`, com pódio) · 🇧🇷 Pé-quente do Brasil (jogos do grupo C) · 🎯 Quase lá (errou o placar exato por 1 gol) · 🔥 Tacada do Dia (maior pontuação num único dia).
  - 📈 Mais Regular (pontuou no maior número de jogos finalizados) · 🎲 Os Corajosos (mais palpites ousados, ≥4 gols somados — oposto do Cartola) · 🗳️ Do Contra que Acertou (cravou placar que <20% do bolão apostou).

  **B. Seu Raio-X pessoal (aba Pessoal)** — ✅ **COMPLETA** _(client-side)_
  - 📊 Pontos por Grupo (barras A→L, destaque melhor/pior) · 🍩 Distribuição 3/1/0 + aproveitamento · 🔢 Placar-assinatura (o resultado que você mais aposta) · ✋ Sua mão (média de gols previstos vs. real) · 🍀 Time da sorte / 💀 Time do azar · ⚡ Maior sequência pontuando.

  **C. Momentos & "Quase"** ✅ _(client-side)_
  - 😤 Por um gol (seus jogos quase cravados) · 🦓 Sua maior zebra (placar exato num jogo improvável) · 🤡 Seu pior palpite (maior diferença apostado × real).

  **E. Gamificação (aba Conquistas)** — ✅ **COMPLETA** _(álbum de emblemas; tabela user_achievements + RPC grant_achievements + view achievement_rarity)_
  - Grid com 15 conquistas (cinza→dourado, barra de progresso, raridade "% dos jogadores", evidência "ver os jogos"): tier Placares Exatos (Bronze/Prata/Ouro = 1/3/5), Sabia do Empate, Ousadia e Alegria, Embalado (3), Pé-quente (5), Dia Cheio, Volta ao Mundo, Dono do Grupo, Coração Verde-Amarelo, Profeta (<10%), Bem-vindo à Panela, Meio Século (50 pts), Quase Lá.
  - Futuro (2ª leva): 🎭 Arquétipo de Apostador · 🎁 Wrapped do Bolão · marcos competitivos (No Pódio/#1) · Fundador/Sociável · conquistas secretas.

  **F. Curiosidades coletivas (aba Bolão)** — ✅ **COMPLETA** _(views: score_popularity, match_predictability, bet_pickers)_
  - 🎲 Jogos mais imprevisíveis (menos cravaram) · 🧠 Esse todo mundo sabia (mais cravaram) — ambos mostram jogo/placar, quantos e quem cravou · 📊 Palpites mais populares (% + abs, com consulta de placar) · 🦄 Palpites únicos (mais raros; desempate por diferença de gols, depois total de gols; toque mostra jogo × usuário).



# Backlog de implementações (Bugs/Fix/Ajustes Necessários)
* **Página de Reset de Senha**: Melhorar a página e internacionalizar a página

# Implementado:


# Ideias Futuras de Implementação

* **Curiosidades da Copa (Loading Screen/Login):** Exibir fatos curiosos e históricos das Copas do Mundo, ou da Copa de 2026 especificamente, para o usuário toda vez que ele logar no sistema ou quando o aplicativo precisar realizar processamentos ligeiramente mais pesados (ex: Agente do Caos rodando dezenas de simulações).
* **Mapa de Classificação**: Criar um mapa de classificação com a chave dos classificados para a próxima fase para análise dos confrontos.

* **Estatísticas Avançadas** — tela dedicada com abas (Rankings · Pessoal · Conquistas · Bolão), entregue por família, uma de cada vez.

  **Princípio transversal:** toda estatística deve nascer preparada para, no futuro, ser filtrada **por liga** (além do bolão global) — espelhando o padrão de `league_rankings`, sem reescrever a UI.

  Legenda: 🔶 precisa de SQL novo (view/RPC) · ✅ client-side · ⚠️ expõe palpite alheio (respeitar reveal). _(Família D — cabeça a cabeça — descartada.)_

  **A. Você vs. o Bolão (rankings)** — ✅ **COMPLETA**
  - 👑 Rei do Placar Exato (`points=3`, com pódio) · 🇧🇷 Pé-quente do Brasil (jogos do grupo C) · 🎯 Quase lá (errou o placar exato por 1 gol) · 🔥 Tacada do Dia (maior pontuação num único dia).
  - 📈 Mais Regular (pontuou no maior número de jogos finalizados) · 🎲 Os Corajosos (mais palpites ousados, ≥4 gols somados — oposto do Cartola) · 🗳️ Do Contra que Acertou (cravou placar que <20% do bolão apostou).

  **B. Seu Raio-X pessoal** ✅ _(client-side)_
  - 📊 Pontos por Grupo (barras A→L, destaque melhor/pior) · 🍩 Distribuição 3/1/0 + aproveitamento · 🔢 Placar-assinatura (o resultado que você mais aposta) · ✋ Sua mão (média de gols previstos vs. real) · 🍀 Time da sorte / 💀 Time do azar · ⚡ Maior sequência pontuando.

  **C. Momentos & "Quase"** ✅ _(client-side)_
  - 😤 Por um gol (seus jogos quase cravados) · 🦓 Sua maior zebra (placar exato num jogo improvável) · 🤡 Seu pior palpite (maior diferença apostado × real).

  **E. Gamificação / diversão**
  - 🎭 Arquétipo de Apostador (O Profeta, O Patriota, O Cartola, Coração na Mão, Pé-Frio…) ✅ · 🏅 Conquistas/Badges (Hat-trick de Exatos, Patriota, Vidente, Zebreiro) ✅/🔶 · 🎁 Wrapped do Bolão (card estilo Spotify Wrapped, compartilhável, fim da fase de grupos) ✅.

  **F. Curiosidades coletivas**
  - 🧩 Jogo mais difícil do bolão (onde menos gente pontuou) · 📌 Palpite mais popular (placar mais apostado num jogo).



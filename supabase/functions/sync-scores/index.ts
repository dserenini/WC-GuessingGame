// =============================================================================
// Edge Function: sync-scores
//
// Sincroniza placares da Copa 2026 a partir da fonte gratuita worldcup26.ir
// (sem chave) para a tabela `matches`.
//
// Modo (shadow | live) é lido do banco em app_config.key = 'sync_mode' — então
// você "vira a chave" por SQL, sem redeploy:
//   - shadow: NÃO escreve em `matches`. Apenas registra em api_sync_runs o que
//             FARIA (jogos ao vivo/encerrados). Serve para validar sem interferir
//             no fluxo manual nem na pontuação.
//   - live:   escreve em `matches` (só quando algo muda). O trigger calcula
//             pontos no 'finished' e o Realtime atualiza os apps.
//
// Resolução à prova de inversão: casa por (grupo + par de seleções) e orienta os
// placares pela identidade do time, não pela posição mandante/visitante.
//
// Não precisa de secrets (a fonte é pública). SUPABASE_URL e
// SUPABASE_SERVICE_ROLE_KEY são injetados automaticamente no runtime.
// =============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SOURCE_URL = "https://worldcup26.ir/get/games";

// Nome EN da fonte -> nome EXATO como está na tabela `teams` do banco (PT).
// ATENÇÃO: dois nomes divergem das constantes do app (lib/core/constants.dart):
// o banco usa "Rep. Tcheca" (não "Tchéquia") e "Holanda" (não "Países Baixos").
// Os valores abaixo seguem o BANCO — não troque pela grafia das constantes.
const EN_TO_DB: Record<string, string> = {
  "mexico": "México",
  "south africa": "África do Sul",
  "south korea": "Coreia do Sul",
  "czech republic": "Rep. Tcheca",
  "canada": "Canadá",
  "switzerland": "Suíça",
  "qatar": "Catar",
  "bosnia and herzegovina": "Bósnia e Herzegovina",
  "brazil": "Brasil",
  "morocco": "Marrocos",
  "haiti": "Haiti",
  "scotland": "Escócia",
  "united states": "Estados Unidos",
  "paraguay": "Paraguai",
  "australia": "Austrália",
  "turkey": "Turquia",
  "germany": "Alemanha",
  "curaçao": "Curaçao",
  "ivory coast": "Costa do Marfim",
  "ecuador": "Equador",
  "netherlands": "Holanda",
  "japan": "Japão",
  "sweden": "Suécia",
  "tunisia": "Tunísia",
  "belgium": "Bélgica",
  "egypt": "Egito",
  "iran": "Irã",
  "new zealand": "Nova Zelândia",
  "spain": "Espanha",
  "cape verde": "Cabo Verde",
  "saudi arabia": "Arábia Saudita",
  "uruguay": "Uruguai",
  "france": "França",
  "senegal": "Senegal",
  "iraq": "Iraque",
  "norway": "Noruega",
  "argentina": "Argentina",
  "algeria": "Argélia",
  "austria": "Áustria",
  "jordan": "Jordânia",
  "portugal": "Portugal",
  "democratic republic of the congo": "RD Congo",
  "uzbekistan": "Uzbequistão",
  "colombia": "Colômbia",
  "england": "Inglaterra",
  "croatia": "Croácia",
  "ghana": "Gana",
  "panama": "Panamá",
};

function toDb(enName: string): string | null {
  return EN_TO_DB[(enName ?? "").trim().toLowerCase()] ?? null;
}

type Status = "scheduled" | "live" | "finished";

function mapStatus(finished: string, timeElapsed: string): Status {
  if ((finished ?? "").toUpperCase() === "TRUE") return "finished";
  const te = (timeElapsed ?? "").trim().toLowerCase();
  if (te !== "" && te !== "notstarted") return "live";
  return "scheduled";
}

function pairKey(group: string, a: string, b: string): string {
  return (group ?? "").toUpperCase() + "|" + [a, b].sort().join("/");
}

Deno.serve(async () => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // 1. Modo (shadow | live), lido do banco — troca por SQL, sem redeploy.
  const { data: cfg } = await supabase
    .from("app_config").select("value").eq("key", "sync_mode").maybeSingle();
  const mode: "shadow" | "live" = cfg?.value?.mode === "live" ? "live" : "shadow";

  // 2. Nossas partidas, indexadas por (grupo + par de seleções).
  const { data: matchesRaw, error: mErr } = await supabase
    .from("matches")
    .select(
      "id, group_letter, home_score, away_score, status, match_date, " +
        "home_team:teams!matches_home_team_id_fkey(name), " +
        "away_team:teams!matches_away_team_id_fkey(name)",
    );
  if (mErr) return json(500, { error: "matches: " + mErr.message });

  const byPair = new Map<string, {
    id: string; group: string; home: string; away: string;
    curHome: number | null; curAway: number | null; curStatus: string;
    matchDate: string | null;
  }>();
  for (const m of matchesRaw ?? []) {
    const home = (m as any).home_team?.name;
    const away = (m as any).away_team?.name;
    if (!home || !away) continue;
    byPair.set(pairKey(m.group_letter, home, away), {
      id: m.id, group: m.group_letter, home, away,
      curHome: m.home_score, curAway: m.away_score, curStatus: m.status,
      matchDate: m.match_date,
    });
  }

  // 3. Fonte (worldcup26.ir) — só jogos da fase de grupos.
  const res = await fetch(SOURCE_URL, {
    headers: { "Accept": "application/json", "User-Agent": "bolaocopa-sync/1.0" },
  });
  if (!res.ok) return json(502, { error: `source ${res.status}` });
  const body = await res.json();
  const games: any[] = (body?.games ?? []).filter((g: any) => g.type === "group");

  const unmatchedNames: string[] = [];
  const unmatchedFixtures: string[] = [];
  let matched = 0, changed = 0, logged = 0;

  for (const g of games) {
    const homeDb = toDb(g.home_team_name_en);
    const awayDb = toDb(g.away_team_name_en);
    if (!homeDb || !awayDb) {
      unmatchedNames.push(`${g.home_team_name_en} / ${g.away_team_name_en}`);
      continue;
    }
    const our = byPair.get(pairKey(g.group, homeDb, awayDb));
    if (!our) {
      unmatchedFixtures.push(`${g.group}: ${homeDb} x ${awayDb}`);
      continue;
    }
    matched++;

    let status = mapStatus(g.finished, g.time_elapsed);

    // Guarda anti-lixo: a fonte é gratuita/não-oficial e às vezes reporta jogos
    // FUTUROS como live/finished com placar de placeholder. Um jogo não pode
    // estar ao vivo/encerrado antes do horário marcado — força 'scheduled' para
    // não gravar placar fantasma nem pontuar palpites num placar inventado.
    if (status !== "scheduled" && our.matchDate) {
      const kickoff = new Date(our.matchDate).getTime();
      if (Number.isFinite(kickoff) && kickoff > Date.now()) {
        status = "scheduled";
      }
    }

    // Trava anti-flap: só encerra (e pontua) um jogo que JÁ estava 'live' no
    // nosso banco — evita o pulo scheduled->finished por flap da fonte. Se a
    // fonte declara 'finished' mas ainda não passamos por 'live', rebaixa para
    // 'live' neste ciclo (captura o placar provisório); no próximo poll, já com
    // curStatus='live', o encerramento/pontuação acontece de fato.
    if (status === "finished" && our.curStatus !== "live" &&
        our.curStatus !== "finished") {
      status = "live";
    }

    const setScores = status !== "scheduled"; // não grava placar de jogo não iniciado

    // Orienta pela identidade do time (à prova de inversão mandante/visitante).
    const srcHome = parseInt(g.home_score ?? "0", 10);
    const srcAway = parseInt(g.away_score ?? "0", 10);
    const homeScore = our.home === homeDb ? srcHome : srcAway;
    const awayScore = our.home === homeDb ? srcAway : srcHome;

    const logRow = {
      mode,
      source_game_id: String(g.id),
      match_id: our.id,
      group_letter: our.group,
      home_team: our.home,
      away_team: our.away,
      src_home_score: setScores ? homeScore : null,
      src_away_score: setScores ? awayScore : null,
      src_status: status,
      src_raw_finished: String(g.finished ?? ""),
      src_time_elapsed: String(g.time_elapsed ?? ""),
      applied: false,
    };

    if (mode === "shadow") {
      // Registra apenas jogos ao vivo/encerrados (mantém o log enxuto).
      if (status !== "scheduled") {
        await supabase.from("api_sync_runs").insert(logRow);
        logged++;
      }
      continue;
    }

    // Alvo: jogo iniciado guarda o placar; jogo 'scheduled' NÃO tem placar
    // (limpa qualquer placar fantasma que tenha sobrado de um tick anterior).
    const targetHome = setScores ? homeScore : null;
    const targetAway = setScores ? awayScore : null;

    // LIVE: só escreve se mudou (evita disparos redundantes de trigger/pontos).
    const sameStatus = our.curStatus === status;
    const sameScore = our.curHome === targetHome && our.curAway === targetAway;
    if (sameStatus && sameScore) continue;

    const patch: Record<string, unknown> = {
      status,
      api_fixture_id: Number(g.id),
      home_score: targetHome,
      away_score: targetAway,
    };

    const { error: uErr } = await supabase.from("matches").update(patch).eq("id", our.id);
    if (uErr) {
      console.error(`update ${our.id}: ${uErr.message}`);
      continue;
    }
    changed++;
    await supabase.from("api_sync_runs").insert({ ...logRow, applied: true });
  }

  // 4. Preenche os 16-avos com as seleções já classificadas MATEMATICAMENTE
  //    (1º/2º de cada grupo; rigoroso FIFA). Só em modo live; idempotente.
  let koFilled = 0;
  if (mode === "live") {
    try {
      koFilled = await fillKnockout(supabase);
    } catch (e) {
      console.error("fillKnockout: " + (e as Error).message);
    }
  }

  return json(200, {
    mode,
    groupGames: games.length,
    matched,
    unmatchedNames,
    unmatchedFixtures,
    ...(mode === "shadow" ? { logged } : { changed, koFilled }),
  });
});

// =============================================================================
// AUTO-PREENCHIMENTO DO MATA-MATA
//   Recalcula a classificação REAL dos grupos (só jogos encerrados) e preenche
//   os slots dos 16-avos cujo 1º/2º já está MATEMATICAMENTE garantido.
//   Rigoroso/seguro: só preenche quando é impossível mudar. Desempate FIFA
//   (pontos→saldo→gols→confronto direto) só é aplicado com o grupo encerrado;
//   com jogos a disputar, usa cota de pontos (empate possível = ainda não trava).
// =============================================================================

type GMatch = {
  group: string;
  home: string;
  away: string;
  hs: number | null;
  as: number | null;
  finished: boolean;
};

// deno-lint-ignore no-explicit-any
async function fillKnockout(supabase: any): Promise<number> {
  // Partidas de grupo FRESCAS (após as gravações deste ciclo).
  const { data: rows, error } = await supabase
    .from("matches")
    .select(
      "group_letter, home_score, away_score, status, " +
        "home_team:teams!matches_home_team_id_fkey(name), " +
        "away_team:teams!matches_away_team_id_fkey(name)",
    );
  if (error) throw new Error("matches: " + error.message);

  const byGroup = new Map<string, GMatch[]>();
  for (const m of rows ?? []) {
    const home = (m as any).home_team?.name;
    const away = (m as any).away_team?.name;
    if (!home || !away || !m.group_letter) continue;
    const g = String(m.group_letter).toUpperCase();
    if (!byGroup.has(g)) byGroup.set(g, []);
    byGroup.get(g)!.push({
      group: g, home, away,
      hs: m.home_score, as: m.away_score,
      finished: m.status === "finished",
    });
  }

  const winner = new Map<string, string>();
  const runnerUp = new Map<string, string>();
  for (const [g, ms] of byGroup) {
    const c = clinchedPositions(ms);
    if (c.winner) winner.set(g, c.winner);
    if (c.runnerUp) runnerUp.set(g, c.runnerUp);
  }
  if (winner.size === 0 && runnerUp.size === 0) return 0;

  const { data: teams } = await supabase.from("teams").select("id, name");
  const idByName = new Map<string, string>();
  for (const t of teams ?? []) idByName.set(t.name, t.id);

  const { data: ko } = await supabase
    .from("ko_match")
    .select(
      "id, home_team_id, away_team_id, " +
        "home_src_kind, home_src_group, away_src_kind, away_src_group",
    )
    .eq("round", "16avos");

  const wantId = (kind: string | null, grp: string | null): string | null => {
    if (!grp) return null;
    const g = grp.toUpperCase();
    const name = kind === "winner"
      ? winner.get(g)
      : kind === "runnerup"
      ? runnerUp.get(g)
      : undefined; // 'third' não é preenchido por ora
    return name ? idByName.get(name) ?? null : null;
  };

  let filled = 0;
  for (const row of ko ?? []) {
    const patch: Record<string, unknown> = {};
    const wh = wantId(row.home_src_kind, row.home_src_group);
    const wa = wantId(row.away_src_kind, row.away_src_group);
    if (wh && wh !== row.home_team_id) patch.home_team_id = wh;
    if (wa && wa !== row.away_team_id) patch.away_team_id = wa;
    if (Object.keys(patch).length > 0) {
      const { error: uErr } = await supabase
        .from("ko_match").update(patch).eq("id", row.id);
      if (!uErr) filled++;
    }
  }
  return filled;
}

/// 1º/2º colocado já garantidos do grupo (ou undefined se ainda em aberto).
function clinchedPositions(
  matches: GMatch[],
): { winner?: string; runnerUp?: string } {
  const teams = [...new Set(matches.flatMap((m) => [m.home, m.away]))];
  const pts: Record<string, number> = {};
  const gf: Record<string, number> = {};
  const ga: Record<string, number> = {};
  const remaining: Record<string, number> = {};
  for (const t of teams) { pts[t] = 0; gf[t] = 0; ga[t] = 0; remaining[t] = 0; }

  let allFinished = true;
  for (const m of matches) {
    if (m.finished && m.hs != null && m.as != null) {
      gf[m.home] += m.hs; ga[m.home] += m.as;
      gf[m.away] += m.as; ga[m.away] += m.hs;
      if (m.hs > m.as) pts[m.home] += 3;
      else if (m.hs < m.as) pts[m.away] += 3;
      else { pts[m.home] += 1; pts[m.away] += 1; }
    } else {
      allFinished = false;
      remaining[m.home]++; remaining[m.away]++;
    }
  }

  // Grupo encerrado: classificação final com desempate FIFA completo.
  if (allFinished) {
    const sorted = [...teams].sort((a, b) => {
      if (pts[b] !== pts[a]) return pts[b] - pts[a];
      const gdA = gf[a] - ga[a], gdB = gf[b] - ga[b];
      if (gdB !== gdA) return gdB - gdA;
      if (gf[b] !== gf[a]) return gf[b] - gf[a];
      const h2h = matches.find((x) =>
        x.finished && x.hs != null && x.as != null &&
        ((x.home === a && x.away === b) || (x.home === b && x.away === a))
      );
      if (h2h) {
        const sa = h2h.home === a ? h2h.hs! : h2h.as!;
        const sb = h2h.home === b ? h2h.hs! : h2h.as!;
        if (sb !== sa) return sb - sa;
      }
      return a.localeCompare(b);
    });
    return { winner: sorted[0], runnerUp: sorted[1] };
  }

  // Grupo em andamento: cota de pontos (seguro). Empate possível = não trava.
  const maxPts: Record<string, number> = {};
  for (const t of teams) maxPts[t] = pts[t] + 3 * remaining[t];

  // 1º: piso de pontos do time supera o teto de TODOS os outros (sem empate).
  const winner = teams.find((t) =>
    teams.every((u) => u === t || maxPts[u] < pts[t])
  );

  // 2º: só com o 1º cravado; no máx. 1 outro time pode alcançar o piso de t
  //     (esse 1 é justamente o 1º) → t é o 2º garantido.
  let runnerUp: string | undefined;
  if (winner) {
    runnerUp = teams.find((t) =>
      t !== winner &&
      teams.filter((u) => u !== t && maxPts[u] >= pts[t]).length <= 1
    );
  }

  return { winner, runnerUp };
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

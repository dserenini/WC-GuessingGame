import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// GLOBAL BET DEADLINE — 2026-06-11 14:30 GMT-3 (17:30 UTC)
// ─────────────────────────────────────────────
final kBetDeadline = DateTime.utc(2026, 6, 11, 17, 30);

// ─────────────────────────────────────────────
// DEBUG ONLY — force the "reveal other users' bets" feature open locally,
// so the Visitor Profile can be tested before the real deadline.
// Has effect ONLY in debug builds (kDebugMode); ignored in release/production.
// Leave false for production builds.
// ─────────────────────────────────────────────
const bool kDebugForceReveal = false;

// Mínimo de palpites próprios para liberar a visualização das apostas de outros
// jogadores (perfil visitante). Antes exigia todos os 72; agora basta atingir
// este limite.
const int kRevealMinBets = 65;

bool get isBettingLocked =>
    (kDebugMode && kDebugForceReveal) ||
    DateTime.now().toUtc().isAfter(kBetDeadline);

// ─────────────────────────────────────────────
// APP VERSION
// ─────────────────────────────────────────────
const String kAppVersion = '1.0';

// ─────────────────────────────────────────────
// SUPER PALPITES
// ─────────────────────────────────────────────
const int kMaxSuperPalpites = 10;

// ─────────────────────────────────────────────
// SCORING RULES
// ─────────────────────────────────────────────
const int kPointsExactScore = 3;
const int kPointsCorrectResult = 1;

// ─────────────────────────────────────────────
// AGENT OF CHAOS — defaults
// ─────────────────────────────────────────────
const int kDefaultMaxGoals = 5;
const int kWackyGoalThreshold = 20; // "Are you serious?" threshold

// ─────────────────────────────────────────────
// SINCRONIZAÇÃO DE PLACARES
// A sincronização automática roda no servidor (Supabase Edge Function
// `sync-scores`, fonte worldcup26.ir) — ver supabase/functions/sync-scores.
// Não há chave/configuração de API no cliente.
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// ADMIN UIDs
// After creating your Supabase project and 3 admin accounts,
// replace these placeholder strings with the real UUIDs.
const List<String> kAdminUids = [
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333',
];

// ─────────────────────────────────────────────
// APP GROUPS A–L
// ─────────────────────────────────────────────
const List<String> kGroups = ['A','B','C','D','E','F','G','H','I','J','K','L'];

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
const Color kPrimaryGreen = Color(0xFF1B5E20);
const Color kPrimaryGreenLight = Color(0xFF4CAF50);
const Color kGold = Color(0xFFFFD700);
const Color kSilver = Color(0xFFC0C0C0);
const Color kBronze = Color(0xFFCD7F32);

// Realce âmbar dos cards premiados no Ranking Geral (11 primeiros + último).
const Color kPrizeHighlight = Color(0xFFFFB300);

// Quantos primeiros colocados do Ranking Geral entram na zona de premiação.
// Fonte única para o realce dos cards e para o filtro "Top N" na comparação
// de palpites.
const int kPrizeTopN = 11;

// ─────────────────────────────────────────────
// WIKIPEDIA FLAG BASE URL
// Usage: '$kFlagBaseUrl/Flag_of_Brazil.svg'
// ─────────────────────────────────────────────
const String kFlagBaseUrl =
    'https://upload.wikimedia.org/wikipedia/commons/thumb';

// ─────────────────────────────────────────────
// TEAM FLAG URLS (Wikipedia SVG)
// ─────────────────────────────────────────────
const Map<String, String> kTeamFlags = {
  // Group A
  'México':        'https://flagcdn.com/w320/mx.png',
  'África do Sul': 'https://flagcdn.com/w320/za.png',
  'Coreia do Sul': 'https://flagcdn.com/w320/kr.png',
  'Tchéquia':      'https://flagcdn.com/w320/cz.png',
  // Group B
  'Canadá':               'https://flagcdn.com/w320/ca.png',
  'Suíça':                'https://flagcdn.com/w320/ch.png',
  'Catar':                'https://flagcdn.com/w320/qa.png',
  'Bósnia e Herzegovina': 'https://flagcdn.com/w320/ba.png',
  // Group C
  'Brasil':   'https://flagcdn.com/w320/br.png',
  'Marrocos': 'https://flagcdn.com/w320/ma.png',
  'Haiti':    'https://flagcdn.com/w320/ht.png',
  'Escócia':  'https://flagcdn.com/w320/gb-sct.png',
  // Group D
  'Estados Unidos': 'https://flagcdn.com/w320/us.png',
  'Paraguai':       'https://flagcdn.com/w320/py.png',
  'Austrália':      'https://flagcdn.com/w320/au.png',
  'Turquia':        'https://flagcdn.com/w320/tr.png',
  // Group E
  'Alemanha':        'https://flagcdn.com/w320/de.png',
  'Curaçao':         'https://flagcdn.com/w320/cw.png',
  'Costa do Marfim': 'https://flagcdn.com/w320/ci.png',
  'Equador':         'https://flagcdn.com/w320/ec.png',
  // Group F
  'Países Baixos': 'https://flagcdn.com/w320/nl.png',
  'Japão':         'https://flagcdn.com/w320/jp.png',
  'Suécia':        'https://flagcdn.com/w320/se.png',
  'Tunísia':       'https://flagcdn.com/w320/tn.png',
  // Group G
  'Bélgica':       'https://flagcdn.com/w320/be.png',
  'Egito':         'https://flagcdn.com/w320/eg.png',
  'Irã':           'https://flagcdn.com/w320/ir.png',
  'Nova Zelândia': 'https://flagcdn.com/w320/nz.png',
  // Group H
  'Espanha':        'https://flagcdn.com/w320/es.png',
  'Cabo Verde':     'https://flagcdn.com/w320/cv.png',
  'Arábia Saudita': 'https://flagcdn.com/w320/sa.png',
  'Uruguai':        'https://flagcdn.com/w320/uy.png',
  // Group I
  'França':  'https://flagcdn.com/w320/fr.png',
  'Senegal': 'https://flagcdn.com/w320/sn.png',
  'Iraque':  'https://flagcdn.com/w320/iq.png',
  'Noruega': 'https://flagcdn.com/w320/no.png',
  // Group J
  'Argentina': 'https://flagcdn.com/w320/ar.png',
  'Argélia':   'https://flagcdn.com/w320/dz.png',
  'Áustria':   'https://flagcdn.com/w320/at.png',
  'Jordânia':  'https://flagcdn.com/w320/jo.png',
  // Group K
  'Portugal':    'https://flagcdn.com/w320/pt.png',
  'RD Congo':    'https://flagcdn.com/w320/cd.png',
  'Uzbequistão': 'https://flagcdn.com/w320/uz.png',
  'Colômbia':    'https://flagcdn.com/w320/co.png',
  // Group L
  'Inglaterra': 'https://flagcdn.com/w320/gb-eng.png',
  'Croácia':    'https://flagcdn.com/w320/hr.png',
  'Gana':       'https://flagcdn.com/w320/gh.png',
  'Panamá':     'https://flagcdn.com/w320/pa.png',
};

// ─────────────────────────────────────────────
// GROUPS → TEAMS MAPPING
// ─────────────────────────────────────────────
const Map<String, List<String>> kGroupTeams = {
  'A': ['México', 'África do Sul', 'Coreia do Sul', 'Tchéquia'],
  'B': ['Canadá', 'Suíça', 'Catar', 'Bósnia e Herzegovina'],
  'C': ['Brasil', 'Marrocos', 'Haiti', 'Escócia'],
  'D': ['Estados Unidos', 'Paraguai', 'Austrália', 'Turquia'],
  'E': ['Alemanha', 'Curaçao', 'Costa do Marfim', 'Equador'],
  'F': ['Países Baixos', 'Japão', 'Suécia', 'Tunísia'],
  'G': ['Bélgica', 'Egito', 'Irã', 'Nova Zelândia'],
  'H': ['Espanha', 'Cabo Verde', 'Arábia Saudita', 'Uruguai'],
  'I': ['França', 'Senegal', 'Iraque', 'Noruega'],
  'J': ['Argentina', 'Argélia', 'Áustria', 'Jordânia'],
  'K': ['Portugal', 'RD Congo', 'Uzbequistão', 'Colômbia'],
  'L': ['Inglaterra', 'Croácia', 'Gana', 'Panamá'],
};

// Each group has 6 matches (round-robin of 4 teams)
// Matchup pairs by index: (0v1),(0v2),(0v3),(1v2),(1v3),(2v3)
List<List<int>> get kGroupMatchPairs =>
    [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]];

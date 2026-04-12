import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// GLOBAL BET DEADLINE — 2026-06-10 23:59 GMT-3
// ─────────────────────────────────────────────
final kBetDeadline = DateTime(2026, 6, 10, 23, 59, 0).toUtc().add(
  const Duration(hours: 3), // GMT-3 → UTC
);

bool get isBettingLocked => DateTime.now().toUtc().isAfter(kBetDeadline);

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
// FOOTBALL API (API-Football / RapidAPI)
// Set your key here when ready.
// ─────────────────────────────────────────────
/// Set to your API-Football key from rapidapi.com/api-sports/api/api-football
/// Leave empty to use manual input mode.
const String kFootballApiKey = ''; // TODO: add your key here
const String kFootballApiBase = 'https://v3.football.api-sports.io';
const int kWorldCup2026Id = 1; // TODO: verify WC2026 competition ID once available

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
  'Mexico':       'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Flag_of_Mexico.svg/320px-Flag_of_Mexico.svg.png',
  'South Africa': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/Flag_of_South_Africa.svg/320px-Flag_of_South_Africa.svg.png',
  'South Korea':  'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/Flag_of_South_Korea.svg/320px-Flag_of_South_Korea.svg.png',
  'Czechia':      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Flag_of_the_Czech_Republic.svg/320px-Flag_of_the_Czech_Republic.svg.png',
  // Group B
  'Canada':               'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Flag_of_Canada_%28Pantone%29.svg/320px-Flag_of_Canada_%28Pantone%29.svg.png',
  'Switzerland':          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Flag_of_Switzerland.svg/240px-Flag_of_Switzerland.svg.png',
  'Qatar':                'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Flag_of_Qatar.svg/320px-Flag_of_Qatar.svg.png',
  'Bosnia and Herzegovina':'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Flag_of_Bosnia_and_Herzegovina.svg/320px-Flag_of_Bosnia_and_Herzegovina.svg.png',
  // Group C
  'Brazil':   'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Flag_of_Brazil.svg/320px-Flag_of_Brazil.svg.png',
  'Morocco':  'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Flag_of_Morocco.svg/320px-Flag_of_Morocco.svg.png',
  'Haiti':    'https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/Flag_of_Haiti.svg/320px-Flag_of_Haiti.svg.png',
  'Scotland': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Flag_of_Scotland.svg/320px-Flag_of_Scotland.svg.png',
  // Group D
  'United States': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Flag_of_the_United_States.svg/320px-Flag_of_the_United_States.svg.png',
  'Paraguay':      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/27/Flag_of_Paraguay.svg/320px-Flag_of_Paraguay.svg.png',
  'Australia':     'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Flag_of_Australia.svg/320px-Flag_of_Australia.svg.png',
  'Türkiye':       'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Flag_of_Turkey.svg/320px-Flag_of_Turkey.svg.png',
  // Group E
  'Germany':      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/ba/Flag_of_Germany.svg/320px-Flag_of_Germany.svg.png',
  'Curaçao':      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b1/Flag_of_Cura%C3%A7ao.svg/320px-Flag_of_Cura%C3%A7ao.svg.png',
  'Ivory Coast':  'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Flag_of_C%C3%B4te_d%27Ivoire.svg/320px-Flag_of_C%C3%B4te_d%27Ivoire.svg.png',
  'Ecuador':      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Flag_of_Ecuador.svg/320px-Flag_of_Ecuador.svg.png',
  // Group F
  'Netherlands': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Flag_of_the_Netherlands.svg/320px-Flag_of_the_Netherlands.svg.png',
  'Japan':       'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Flag_of_Japan.svg/320px-Flag_of_Japan.svg.png',
  'Sweden':      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Flag_of_Sweden.svg/320px-Flag_of_Sweden.svg.png',
  'Tunisia':     'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Flag_of_Tunisia.svg/320px-Flag_of_Tunisia.svg.png',
  // Group G
  'Belgium':     'https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Flag_of_Belgium.svg/320px-Flag_of_Belgium.svg.png',
  'Egypt':       'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Flag_of_Egypt.svg/320px-Flag_of_Egypt.svg.png',
  'IR Iran':     'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Flag_of_Iran.svg/320px-Flag_of_Iran.svg.png',
  'New Zealand': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Flag_of_New_Zealand.svg/320px-Flag_of_New_Zealand.svg.png',
  // Group H
  'Spain':        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Flag_of_Spain.svg/320px-Flag_of_Spain.svg.png',
  'Cabo Verde':   'https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Flag_of_Cape_Verde.svg/320px-Flag_of_Cape_Verde.svg.png',
  'Saudi Arabia': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/Flag_of_Saudi_Arabia.svg/320px-Flag_of_Saudi_Arabia.svg.png',
  'Uruguay':      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Flag_of_Uruguay.svg/320px-Flag_of_Uruguay.svg.png',
  // Group I
  'France':  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Flag_of_France.svg/320px-Flag_of_France.svg.png',
  'Senegal': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/Flag_of_Senegal.svg/320px-Flag_of_Senegal.svg.png',
  'Iraq':    'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Flag_of_Iraq.svg/320px-Flag_of_Iraq.svg.png',
  'Norway':  'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Flag_of_Norway.svg/320px-Flag_of_Norway.svg.png',
  // Group J
  'Argentina': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Flag_of_Argentina.svg/320px-Flag_of_Argentina.svg.png',
  'Algeria':   'https://upload.wikimedia.org/wikipedia/commons/thumb/7/77/Flag_of_Algeria.svg/320px-Flag_of_Algeria.svg.png',
  'Austria':   'https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Flag_of_Austria.svg/320px-Flag_of_Austria.svg.png',
  'Jordan':    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Flag_of_Jordan.svg/320px-Flag_of_Jordan.svg.png',
  // Group K
  'Portugal':   'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Flag_of_Portugal.svg/320px-Flag_of_Portugal.svg.png',
  'DR Congo':   'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Flag_of_the_Democratic_Republic_of_the_Congo.svg/320px-Flag_of_the_Democratic_Republic_of_the_Congo.svg.png',
  'Uzbekistan': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Flag_of_Uzbekistan.svg/320px-Flag_of_Uzbekistan.svg.png',
  'Colombia':   'https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/Flag_of_Colombia.svg/320px-Flag_of_Colombia.svg.png',
  // Group L
  'England': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/be/Flag_of_England.svg/320px-Flag_of_England.svg.png',
  'Croatia': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/Flag_of_Croatia.svg/320px-Flag_of_Croatia.svg.png',
  'Ghana':   'https://upload.wikimedia.org/wikipedia/commons/thumb/1/19/Flag_of_Ghana.svg/320px-Flag_of_Ghana.svg.png',
  'Panama':  'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/Flag_of_Panama.svg/320px-Flag_of_Panama.svg.png',
};

// ─────────────────────────────────────────────
// GROUPS → TEAMS MAPPING
// ─────────────────────────────────────────────
const Map<String, List<String>> kGroupTeams = {
  'A': ['Mexico', 'South Africa', 'South Korea', 'Czechia'],
  'B': ['Canada', 'Switzerland', 'Qatar', 'Bosnia and Herzegovina'],
  'C': ['Brazil', 'Morocco', 'Haiti', 'Scotland'],
  'D': ['United States', 'Paraguay', 'Australia', 'Türkiye'],
  'E': ['Germany', 'Curaçao', 'Ivory Coast', 'Ecuador'],
  'F': ['Netherlands', 'Japan', 'Sweden', 'Tunisia'],
  'G': ['Belgium', 'Egypt', 'IR Iran', 'New Zealand'],
  'H': ['Spain', 'Cabo Verde', 'Saudi Arabia', 'Uruguay'],
  'I': ['France', 'Senegal', 'Iraq', 'Norway'],
  'J': ['Argentina', 'Algeria', 'Austria', 'Jordan'],
  'K': ['Portugal', 'DR Congo', 'Uzbekistan', 'Colombia'],
  'L': ['England', 'Croatia', 'Ghana', 'Panama'],
};

// Each group has 6 matches (round-robin of 4 teams)
// Matchup pairs by index: (0v1),(0v2),(0v3),(1v2),(1v3),(2v3)
List<List<int>> get kGroupMatchPairs =>
    [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]];

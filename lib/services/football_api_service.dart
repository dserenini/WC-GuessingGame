// =============================================================================
// FOOTBALL API SERVICE
//
// Currently runs in MANUAL MODE (kFootballApiKey is empty).
//
// HOW TO ACTIVATE LIVE SCORES:
//   1. Sign up at https://rapidapi.com/api-sports/api/api-football (free plan)
//   2. Copy your API key
//   3. In lib/core/constants.dart, set: kFootballApiKey = 'your-key-here'
//   4. The syncMatches() call below will automatically start working.
//
// Free plan limits: 100 requests/day â€” enough for daily syncing during WC2026.
// =============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:copa2026/core/constants.dart';

class FootballApiService {
  static const _host = 'v3.football.api-sports.io';
  static const _rapidApiHost = 'api-football-v1.p.rapidapi.com';

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // PUBLIC ENTRY POINT
  // Call this daily (e.g., from a scheduled Supabase Edge Function)
  // to sync live and finished match scores.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> syncMatches() async {
    if (kFootballApiKey.isEmpty) {
      debugPrint('âš½ FootballApiService: Manual mode â€” no API key set.');
      return;
    }

    try {
      final fixtures = await _fetchLiveAndFinished();
      await _upsertToSupabase(fixtures);
      debugPrint('âš½ FootballApiService: Synced ${fixtures.length} matches.');
    } catch (e) {
      debugPrint('âš½ FootballApiService error: $e');
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // FETCH â€” GET /fixtures?league={id}&season=2026&round=Group Stage
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<List<_Fixture>> _fetchLiveAndFinished() async {
    // TODO: Confirm kWorldCup2026Id once API-Football publishes it
    final uri = Uri.https(_rapidApiHost, '/v3/fixtures', {
      'league': '$kWorldCup2026Id',
      'season': '2026',
    });

    final response = await http.get(uri, headers: {
      'X-RapidAPI-Key': kFootballApiKey,
      'X-RapidAPI-Host': _rapidApiHost,
    });

    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final fixtures = (json['response'] as List).cast<Map<String, dynamic>>();

    return fixtures
        .map(_Fixture.fromJson)
        .where((f) =>
            f.statusShort == 'FT' ||
            f.statusShort == 'LIVE' ||
            f.statusShort == '1H' ||
            f.statusShort == '2H')
        .toList();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // UPSERT to Supabase matches table
  // Matches by api_match_id
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> _upsertToSupabase(List<_Fixture> fixtures) async {
    final client = Supabase.instance.client;

    for (final f in fixtures) {
      final isFinished = f.statusShort == 'FT';
      final isLive = ['1H', '2H', 'HT', 'ET', 'P', 'LIVE'].contains(f.statusShort);

      await client.from('matches').update({
        'home_score': f.homeGoals,
        'away_score': f.awayGoals,
        'status': isFinished
            ? 'finished'
            : isLive
                ? 'live'
                : 'scheduled',
      }).eq('api_match_id', f.apiId.toString());
    }
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Internal fixture model
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _Fixture {
  final int apiId;
  final String statusShort;
  final int? homeGoals;
  final int? awayGoals;

  const _Fixture({
    required this.apiId,
    required this.statusShort,
    this.homeGoals,
    this.awayGoals,
  });

  factory _Fixture.fromJson(Map<String, dynamic> json) => _Fixture(
        apiId: json['fixture']['id'] as int,
        statusShort: json['fixture']['status']['short'] as String,
        homeGoals: json['goals']['home'] as int?,
        awayGoals: json['goals']['away'] as int?,
      );
}

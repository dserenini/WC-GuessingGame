import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MasterDataService {
  static Future<(int, int)> syncMatchesFromSheet() async {
    const envUrl = String.fromEnvironment('MASTER_DATA_CSV_URL');
    String? url = envUrl.isNotEmpty ? envUrl : dotenv.env['MASTER_DATA_CSV_URL'];

    if (url == null || url.isEmpty || url.contains('YOUR_PUBLISHED_CSV_ID_HERE')) {
      // Fallback para a URL do Google Sheets caso o .env não seja carregado em produção
      url = 'https://docs.google.com/spreadsheets/d/16tsP_ai8qXPBhlyT5osjuewqEOsZ93qMo1uUVdRxE8A/export?format=csv';
    }

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Erro ao baixar CSV: ${response.statusCode}');
      }

      // Converte bytes ou string direto
      // O Google Sheets costuma mandar em UTF-8
      final csvString = response.body;
      
      // Parse do CSV. Considera que a primeira linha tem os cabecalhos:
      // match_id, home_score, away_score, status
      final List<List<dynamic>> rows = Csv(
        dynamicTyping: true,
      ).decode(csvString);

      if (rows.isEmpty || rows.length == 1) {
        return (0, 0); // Planilha vazia
      }

      // Pega cabecalhos
      final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      final matchIdIndex = headers.indexOf('match_id');
      final homeScoreIndex = headers.indexOf('home_score');
      final awayScoreIndex = headers.indexOf('away_score');
      final statusIndex = headers.indexOf('status');

      if (matchIdIndex == -1 || homeScoreIndex == -1 || awayScoreIndex == -1 || statusIndex == -1) {
        throw Exception('Formato do CSV inválido. Faltam colunas obrigatórias.');
      }

      int updated = 0;
      int errors = 0;
      final client = Supabase.instance.client;

      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          final matchId = row[matchIdIndex].toString().trim();
          
          if (matchId.isEmpty) continue;

          final homeScoreRaw = row[homeScoreIndex];
          final awayScoreRaw = row[awayScoreIndex];
          final status = row[statusIndex].toString().trim();

          int? homeScore;
          int? awayScore;

          if (homeScoreRaw != null && homeScoreRaw.toString().trim().isNotEmpty) {
            homeScore = int.tryParse(homeScoreRaw.toString());
          }
          if (awayScoreRaw != null && awayScoreRaw.toString().trim().isNotEmpty) {
            awayScore = int.tryParse(awayScoreRaw.toString());
          }

          // Se status for vazio, ignorar
          if (status.isEmpty) continue;

          // Valida status
          final validStatuses = ['scheduled', 'live', 'finished'];
          final statusToUse = validStatuses.contains(status) ? status : 'scheduled';

          await client.from('matches').update({
            if (homeScore != null) 'home_score': homeScore,
            if (awayScore != null) 'away_score': awayScore,
            'status': statusToUse,
          }).eq('api_match_id', matchId);

          updated++;
        } catch (e) {
          debugPrint('⚽ MasterDataService: Erro na linha $i -> $e');
          errors++;
        }
      }

      return (updated, errors);

    } catch (e) {
      debugPrint('⚽ MasterDataService erro: $e');
      rethrow;
    }
  }
}

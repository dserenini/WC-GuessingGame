import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/utils/downloader.dart' as downloader;

class ExportBetsScreen extends StatefulWidget {
  final List<MatchModel> matches;
  final Map<String, BetModel> bets;
  final String userName;

  const ExportBetsScreen({
    super.key,
    required this.matches,
    required this.bets,
    required this.userName,
  });

  @override
  State<ExportBetsScreen> createState() => _ExportBetsScreenState();
}

class _ExportBetsScreenState extends State<ExportBetsScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  static String _getTeamAbbr(String name) {
    final map = {
      'Países Baixos': 'NED', 'Nova Zelândia': 'NZL', 'Costa Rica': 'CRC',
      'Arábia Saudita': 'KSA', 'Coreia do Sul': 'KOR', 'RD Congo': 'COD',
      'Cabo Verde': 'CPV', 'Estados Unidos': 'USA', 'Costa do Marfim': 'CIV',
      'Irã': 'IRN',
    };
    if (map.containsKey(name)) return map[name]!;
    
    String clean = name.replaceAll('í', 'i').replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('ã', 'a').replaceAll('ç', 'c').toUpperCase();
    if (clean.contains(' ')) {
      final parts = clean.split(' ').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        String res = '${parts[0][0]}${parts[1]}';
        if (res.length >= 3) return res.substring(0, 3);
        return res.padRight(3, 'A');
      }
    }
    if (clean.length >= 3) return clean.substring(0, 3);
    return clean.padRight(3, 'A');
  }

  Future<void> _captureAndShare() async {
    setState(() => _isCapturing = true);
    try {
      // Usando capture() direto, que tira foto do widget que JÁ ESTÁ na tela. É 100% à prova de falhas.
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 20));
      
      if (image != null && mounted) {
        if (kIsWeb) {
          downloader.downloadImage(image, 'minhas_apostas.png');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download iniciado! Verifique sua pasta de downloads.')));
        } else {
          final xFile = XFile.fromData(image, mimeType: 'image/png', name: 'apostas.png');
          await Share.shareXFiles([xFile], text: 'Minhas apostas para a Copa 2026!');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<MatchModel>> groups = {};
    for (var m in widget.matches) {
      groups.putIfAbsent(m.groupLetter, () => []).add(m);
    }
    final sortedGroups = groups.keys.toList()..sort();

    final exportWidget = Container(
      width: 1200,
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🏆 Bolão Copa 2026',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Apostas de ${widget.userName}',
            style: const TextStyle(fontSize: 22, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 1100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColumn(sortedGroups.take(4).toList(), groups, widget.bets),
                _buildColumn(sortedGroups.skip(4).take(4).toList(), groups, widget.bets),
                _buildColumn(sortedGroups.skip(8).take(4).toList(), groups, widget.bets),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Apostas'),
        actions: [
          if (_isCapturing)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: CircularProgressIndicator()))
          else
            IconButton(
              icon: Icon(kIsWeb ? Icons.download : Icons.share),
              onPressed: _captureAndShare,
              tooltip: kIsWeb ? 'Baixar Imagem' : 'Compartilhar',
            ),
        ],
      ),
      // InteractiveViewer allows the user to pinch-zoom the big 1200px image on mobile
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(32),
        minScale: 0.1,
        maxScale: 2.0,
        child: Screenshot(
          controller: _screenshotController,
          child: exportWidget,
        ),
      ),
    );
  }

  Widget _buildColumn(List<String> groupLetters, Map<String, List<MatchModel>> groups, Map<String, BetModel> bets) {
    return Expanded(
      child: Column(
        children: groupLetters.map((g) {
          final gMatches = groups[g]!;
          gMatches.sort((a, b) {
            final dateA = a.matchDate ?? DateTime.now();
            final dateB = b.matchDate ?? DateTime.now();
            return dateA.compareTo(dateB);
          });
          
          return Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('GRUPO $g', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 18)),
                const Divider(color: Colors.white24),
                ...gMatches.map((m) {
                  final bet = bets[m.id];
                  final homeAbbr = _getTeamAbbr(m.homeTeam.name);
                  final awayAbbr = _getTeamAbbr(m.awayTeam.name);
                  final homeScore = bet?.homeScoreBet.toString() ?? '-';
                  final awayScore = bet?.awayScoreBet.toString() ?? '-';
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '$homeAbbr  $homeScore x $awayScore  $awayAbbr',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

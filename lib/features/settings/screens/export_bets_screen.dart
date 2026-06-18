import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:screenshot/screenshot.dart';
import 'package:copa2026/shared/models/match.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/utils/downloader.dart' as downloader;
import 'package:copa2026/l10n/team_translator.dart';

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

  // ── Captura ─────────────────────────────────────────────────────────────────

  /// Captura a screenshot e retorna os bytes. Exibe SnackBar de erro se falhar.
  Future<Uint8List?> _captureImage() async {
    setState(() => _isCapturing = true);
    try {
      return await _screenshotController.capture(
        delay: const Duration(milliseconds: 20),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.exportError(e.toString()))),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ── Ações ────────────────────────────────────────────────────────────────────

  /// Download direto da imagem — funciona em desktop e mobile browser.
  Future<void> _captureAndDownload() async {
    final image = await _captureImage();
    if (image == null || !mounted) return;

    downloader.downloadImage(image, 'apostas_${widget.userName}.png');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.exportStarted),
      ),
    );
  }

  /// Compartilha via Web Share API — no mobile browser abre o seletor nativo
  /// do sistema operacional (Android/iOS) com WhatsApp como opção direta.
  /// Fallback automático: faz o download se o browser não suportar a API.
  Future<void> _captureAndShareWhatsApp() async {
    final image = await _captureImage();
    if (image == null || !mounted) return;

    // Compartilhamento sem legenda: a mensagem (WhatsApp etc.) vai vazia, só a
    // imagem das apostas é anexada.
    final shared = await downloader.shareImageNative(
      image,
      'apostas_${widget.userName}.png',
      '',
    );

    if (!mounted) return;

    if (!shared) {
      // Fallback: browser não suporta Web Share API — salva a imagem
      downloader.downloadImage(image, 'apostas_${widget.userName}.png');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compartilhamento não disponível neste browser. '
            'Imagem salva — envie pelo WhatsApp a partir da sua galeria.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final Map<String, List<MatchModel>> groups = {};
    for (final m in widget.matches) {
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
            '🏆 Make Bolão Great Again',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.exportBetsOf(widget.userName),
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
        title: Text(AppLocalizations.of(context)!.exportBets),
        actions: [
          if (_isCapturing)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            // Botão Download — sempre visível
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _captureAndDownload,
              tooltip: AppLocalizations.of(context)!.downloadImage,
            ),
            // Botão WhatsApp — apenas na web (mobile e desktop),
            // pois é onde a Web Share API funciona
            if (kIsWeb)
              IconButton(
                icon: const Icon(Icons.ios_share, color: Color(0xFF25D366)),
                onPressed: _captureAndShareWhatsApp,
                tooltip: AppLocalizations.of(context)!.shareWhatsApp,
              ),
          ],
        ],
      ),
      // InteractiveViewer permite pinch-zoom na imagem grande no mobile
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

  Widget _buildColumn(
    List<String> groupLetters,
    Map<String, List<MatchModel>> groups,
    Map<String, BetModel> bets,
  ) {
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
                Text(
                  AppLocalizations.of(context)!.exportGroupTitle(g),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                    fontSize: 18,
                  ),
                ),
                const Divider(color: Colors.white24),
                ...gMatches.map((m) {
                  final bet = bets[m.id];
                  final homeAbbr = getTeamAbbreviation(context, m.homeTeam.name);
                  final awayAbbr = getTeamAbbreviation(context, m.awayTeam.name);
                  final homeScore = bet?.homeScoreBet.toString() ?? '-';
                  final awayScore = bet?.awayScoreBet.toString() ?? '-';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '$homeAbbr  $homeScore x $awayScore  $awayAbbr',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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

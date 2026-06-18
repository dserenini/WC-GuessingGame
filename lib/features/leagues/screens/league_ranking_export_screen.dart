import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';
import 'package:screenshot/screenshot.dart';
import 'package:copa2026/shared/models/bet.dart';
import 'package:copa2026/features/ranking/screens/ranking_screen.dart';
import 'package:copa2026/utils/downloader.dart' as downloader;

/// Exporta a classificação de uma liga como imagem — mesmo padrão do
/// [ExportBetsScreen]: captura via Screenshot e oferece download + share
/// (WhatsApp via Web Share API na web). Reaproveita utils/downloader.dart.
class LeagueRankingExportScreen extends StatefulWidget {
  final String leagueName;
  final List<RankingEntry> entries;

  const LeagueRankingExportScreen({
    super.key,
    required this.leagueName,
    required this.entries,
  });

  @override
  State<LeagueRankingExportScreen> createState() =>
      _LeagueRankingExportScreenState();
}

class _LeagueRankingExportScreenState extends State<LeagueRankingExportScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  String get _fileName {
    final safe = widget.leagueName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return 'classificacao_$safe.png';
  }

  // ── Captura ──────────────────────────────────────────────────────────────
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

  Future<void> _captureAndDownload() async {
    final image = await _captureImage();
    if (image == null || !mounted) return;

    downloader.downloadImage(image, _fileName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.exportStarted)),
    );
  }

  Future<void> _captureAndShareWhatsApp() async {
    final image = await _captureImage();
    if (image == null || !mounted) return;

    // Compartilhamento sem legenda: a mensagem (WhatsApp etc.) vai vazia, só a
    // imagem do ranking é anexada.
    final shared = await downloader.shareImageNative(image, _fileName, '');
    if (!mounted) return;

    if (!shared) {
      downloader.downloadImage(image, _fileName);
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

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // "Print" da classificação: reaproveita o próprio RankingTile da tela das
    // Ligas, sobre o fundo do app, para ficar idêntico ao exibido em tela.
    final exportWidget = Container(
      width: 460,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  '🏆 Make Bolão Great Again',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.leagueName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Mesmas linhas da tela (medalha, avatar, nº de apostas, pontos,
          // chevron). dense rank já vem aplicado pelo provider.
          ...widget.entries.map((e) => RankingTile(entry: e, isMe: false, l: l)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.exportRanking),
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
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _captureAndDownload,
              tooltip: l.downloadImage,
            ),
            if (kIsWeb)
              IconButton(
                icon: const Icon(Icons.ios_share, color: Color(0xFF25D366)),
                onPressed: _captureAndShareWhatsApp,
                tooltip: l.shareWhatsApp,
              ),
          ],
        ],
      ),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(32),
        minScale: 0.1,
        maxScale: 2.0,
        child: Screenshot(
          controller: _screenshotController,
          // IgnorePointer: as linhas reusam RankingTile (com InkWell de
          // navegação); aqui é só visualização/captura, então neutralizamos
          // o toque. O InteractiveViewer (pai) segue com pan/zoom.
          child: IgnorePointer(child: exportWidget),
        ),
      ),
    );
  }
}

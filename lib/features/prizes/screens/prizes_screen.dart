import 'package:flutter/material.dart';

import 'package:copa2026/core/constants.dart';
import 'package:copa2026/l10n/app_localizations.dart';

/// Tela dedicada de Premiação, acessada pelo card "Premiação" na Ajuda.
/// Os valores são fixos (definidos pela organização) e expressos em reais (R$).
///   • Ranking geral, após todos os jogos: 11 primeiros + último colocado.
///   • Por rodada (1ª, 2ª e 3ª): os 3 primeiros de CADA rodada.
class PrizesScreen extends StatelessWidget {
  const PrizesScreen({super.key});

  // Ranking geral (após todos os jogos) — posição (key) : valor em R$ (value).
  static const List<MapEntry<int, int>> _generalPrizes = [
    MapEntry(1, 600),
    MapEntry(2, 400),
    MapEntry(3, 350),
    MapEntry(4, 300),
    MapEntry(5, 250),
    MapEntry(6, 200),
    MapEntry(7, 175),
    MapEntry(8, 150),
    MapEntry(9, 125),
    MapEntry(10, 100),
    MapEntry(11, 85),
  ];

  static const int _lastPlacePrize = 50;

  // Os 3 primeiros de CADA rodada (1ª, 2ª e 3ª) recebem estes valores.
  static const List<MapEntry<int, int>> _roundPrizes = [
    MapEntry(1, 50),
    MapEntry(2, 35),
    MapEntry(3, 20),
  ];

  // "R$ 1.000" — separador de milhar com ponto (padrão pt-BR).
  static String _money(int v) =>
      'R\$ ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.prizesTitle),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            icon: Icons.emoji_events,
            iconColor: kGold,
            title: l.prizesGeneralTitle,
            note: l.prizesGeneralNote,
            children: [
              for (final p in _generalPrizes)
                _PrizeRow(pos: p.key, label: l.rankPositionShort(p.key), value: _money(p.value)),
              const Divider(height: 24),
              _PrizeRow(
                leadingEmoji: '🐢',
                label: l.prizesLastPlace,
                value: _money(_lastPlacePrize),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.flag_rounded,
            iconColor: Colors.blueAccent,
            title: l.prizesPerRoundTitle,
            note: l.prizesPerRoundNote,
            children: [
              for (final p in _roundPrizes)
                _PrizeRow(pos: p.key, label: l.rankPositionShort(p.key), value: _money(p.value)),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              l.appTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Card de uma seção (cabeçalho + linhas de prêmio) ─────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String note;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.note,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ── Uma linha de prêmio: posição (medalha/nº ou emoji) + rótulo + valor ──────
class _PrizeRow extends StatelessWidget {
  final int? pos;
  final String? leadingEmoji;
  final String label;
  final String value;

  const _PrizeRow({
    this.pos,
    this.leadingEmoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final medalColor = switch (pos) {
      1 => kGold,
      2 => kSilver,
      3 => kBronze,
      _ => cs.onSurface.withOpacity(0.55),
    };
    final leading = leadingEmoji ??
        switch (pos) {
          1 => '🥇',
          2 => '🥈',
          3 => '🥉',
          _ => '$posº',
        };
    final highlight = pos != null && pos! <= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              leading,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: medalColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.85),
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: highlight ? medalColor : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

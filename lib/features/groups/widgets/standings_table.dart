import 'package:flutter/material.dart';
import 'package:copa2026/features/groups/providers/group_provider.dart';

class StandingsTable extends StatelessWidget {
  final List<StandingEntry> standings;

  const StandingsTable({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _header(context, '#', width: 28, align: TextAlign.center),
                _header(context, 'Time', flex: 3),
                _header(context, 'J', width: 28, align: TextAlign.center),
                _header(context, 'G', width: 28, align: TextAlign.center),
                _header(context, 'SG', width: 32, align: TextAlign.center),
                _header(context, 'Pts', width: 32, align: TextAlign.center),
              ],
            ),
          ),
          const Divider(height: 1),
          // â”€â”€ Rows â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          ...standings.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final qualified = i < 2;
            return Container(
              decoration: BoxDecoration(
                color: qualified
                    ? cs.primary.withOpacity(0.04)
                    : Colors.transparent,
                borderRadius: i == standings.length - 1
                    ? const BorderRadius.vertical(
                        bottom: Radius.circular(16))
                    : null,
                border: i < standings.length - 1
                    ? Border(bottom: BorderSide(color: cs.outline.withOpacity(0.2)))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}',
                      textAlign: TextAlign.center,
                      style: tt.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: qualified ? cs.primary : cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        if (s.flagUrl != null)
                          ClipOval(
                            child: Image.network(
                              s.flagUrl!,
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 20, height: 20),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.teamName,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _cell(context, '${s.played}'),
                  _cell(context, '${s.goalsFor}:${s.goalsAgainst}', width: 28),
                  _cell(context, '${s.goalDiff > 0 ? '+' : ''}${s.goalDiff}', width: 32),
                  _cell(
                    context,
                    '${s.points}',
                    width: 32,
                    bold: true,
                    color: qualified ? cs.primary : null,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _header(
    BuildContext context,
    String label, {
    double? width,
    int flex = 1,
    TextAlign align = TextAlign.left,
  }) {
    final w = Text(
      label,
      textAlign: align,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w600,
          ),
    );
    if (width != null) return SizedBox(width: width, child: w);
    return Expanded(flex: flex, child: w);
  }

  Widget _cell(
    BuildContext context,
    String label, {
    double width = 28,
    bool bold = false,
    Color? color,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: color,
            ),
      ),
    );
  }
}

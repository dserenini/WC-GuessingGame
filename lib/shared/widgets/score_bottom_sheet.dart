import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';

class ScoreBottomSheet extends StatefulWidget {
  final String homeTeam;
  final String awayTeam;
  final int initialHome;
  final int initialAway;
  final bool focusHome;

  const ScoreBottomSheet({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.initialHome,
    required this.initialAway,
    this.focusHome = true,
  });

  @override
  State<ScoreBottomSheet> createState() => _ScoreBottomSheetState();
}

class _ScoreBottomSheetState extends State<ScoreBottomSheet> {
  late int _home;
  late int _away;
  late bool _editingHome;

  @override
  void initState() {
    super.initState();
    _home = widget.initialHome;
    _away = widget.initialAway;
    _editingHome = widget.focusHome;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Teams
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(widget.homeTeam,
                        textAlign: TextAlign.center,
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('vs',
                        style: TextStyle(fontWeight: FontWeight.w400)),
                  ),
                  Expanded(
                    child: Text(widget.awayTeam,
                        textAlign: TextAlign.center,
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Score display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ScoreSelector(
                    value: _home,
                    selected: _editingHome,
                    onTap: () => setState(() => _editingHome = true),
                    onIncrement: () => setState(() => _home++),
                    onDecrement: () =>
                        setState(() => _home = (_home - 1).clamp(0, 99)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('–',
                        style: tt.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w300)),
                  ),
                  _ScoreSelector(
                    value: _away,
                    selected: !_editingHome,
                    onTap: () => setState(() => _editingHome = false),
                    onIncrement: () => setState(() => _away++),
                    onDecrement: () =>
                        setState(() => _away = (_away - 1).clamp(0, 99)),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Confirm
              ElevatedButton(
                onPressed: () => Navigator.pop(context, (_home, _away)),
                child: Text(l.confirm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Score Selector sub-widget
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ScoreSelector extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ScoreSelector({
    required this.value,
    required this.selected,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // + button
            IconButton(
              onPressed: onIncrement,
              icon: Icon(Icons.add, color: cs.primary),
              style: IconButton.styleFrom(
                backgroundColor: cs.primary.withOpacity(0.08),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),
            ),
            // Score
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '$value',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? cs.primary : null,
                    ),
              ),
            ),
            // - button
            IconButton(
              onPressed: onDecrement,
              icon: Icon(Icons.remove, color: cs.onSurface.withOpacity(0.6)),
              style: IconButton.styleFrom(
                backgroundColor: cs.surfaceContainerHighest,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

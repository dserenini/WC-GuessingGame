import 'package:flutter/material.dart';
import 'package:copa2026/l10n/app_localizations.dart';

import 'package:copa2026/features/profile/widgets/achievements_cards.dart';
import 'package:copa2026/shared/widgets/app_drawer.dart';
import 'package:copa2026/features/notifications/widgets/notification_bell.dart';

/// Dedicated "Conquistas" page (split out of Advanced Stats). Reuses the exact
/// same [AchievementsTab] body, now as a top-level menu destination.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('🏅 ${l.statsTabAchievements}'),
        leadingWidth: 100,
        leading: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const NotificationBell(),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: const AchievementsTab(),
    );
  }
}

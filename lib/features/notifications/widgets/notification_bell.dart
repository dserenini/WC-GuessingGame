import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/features/notifications/providers/notifications_provider.dart';
import 'package:copa2026/features/notifications/widgets/notifications_dialog.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 9 ? '9+' : unreadCount.toString()),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const NotificationsDialog(),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:copa2026/features/notifications/providers/notifications_provider.dart';
import 'package:copa2026/features/notifications/models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationsDialog extends ConsumerWidget {
  const NotificationsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final actions = ref.read(notificationActionsProvider);
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Notificações'),
      content: SizedBox(
        width: double.maxFinite,
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const Center(child: Text('Nenhuma notificação.'));
            }

            return ListView.separated(
              shrinkWrap: true,
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif.isRead;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey[300] : cs.primaryContainer,
                    child: Icon(
                      isRead ? Icons.notifications_none : Icons.notifications_active,
                      color: isRead ? Colors.grey[600] : cs.primary,
                    ),
                  ),
                  title: Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    notif.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    if (!isRead) actions.markAsRead(notif.id);
                    _showNotificationDetails(context, notif, actions);
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'read') {
                        actions.markAsRead(notif.id);
                      } else if (value == 'delete') {
                        actions.delete(notif.id);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isRead)
                        const PopupMenuItem(
                          value: 'read',
                          child: Text('Marcar como lida'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Deletar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  void _showNotificationDetails(BuildContext context, NotificationModel notif, NotificationActions actions) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(notif.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(notif.createdAt.toLocal()),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text(notif.message),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              actions.delete(notif.id);
              Navigator.pop(ctx);
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

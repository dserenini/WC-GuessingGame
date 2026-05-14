import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:copa2026/features/notifications/models/notification_model.dart';
import 'package:copa2026/features/auth/providers/auth_provider.dart';

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  ref.watch(authStateProvider); // To refresh on login/logout
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  if (userId == null) {
    return Stream.value([]);
  }

  return Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((data) => data.map((e) => NotificationModel.fromJson(e)).toList());
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});

class NotificationActions {
  final Ref ref;
  NotificationActions(this.ref);

  Future<void> markAsRead(String id) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
      
      // Força a UI a atualizar buscando novamente os dados no banco
      ref.invalidate(notificationsProvider);
    } catch (e) {
      print('Erro ao marcar como lido: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('id', id);
          
      // Força a UI a atualizar buscando novamente os dados no banco
      ref.invalidate(notificationsProvider);
    } catch (e) {
      print('Erro ao deletar: $e');
    }
  }
}

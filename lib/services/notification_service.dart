import 'dart:async';
import 'dart:convert';
import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  Future<List<NotificationItem>> getNotifications() async {
    final response = await ApiClient().get('/notifications');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((d) => NotificationItem.fromJson({
        'id': d['id'],
        'user_id': d['user_id'],
        'title': d['title'],
        'desc_text': d['desc_text'],
        'icon_code': d['icon_code'],
        'color_hex': d['color_hex'],
        'is_read': d['is_read'],
        'created_at': d['created_at'],
      })).toList();
    } else {
      throw Exception('Error al obtener notificaciones.');
    }
  }

  Stream<List<NotificationItem>> streamNotifications(String userId) async* {
    while (true) {
      try {
        final list = await getNotifications();
        yield list;
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 8));
    }
  }

  Future<void> sendNotification({
    required String targetUserId,
    required NotificationItem notification,
  }) async {
    final response = await ApiClient().post('/notifications', {
      'userId': targetUserId,
      'title': notification.title,
      'desc': notification.desc,
      'iconCode': notification.iconCode,
      'colorHex': notification.colorHex,
    });
    if (response.statusCode != 201) {
      throw Exception('Error al enviar notificación.');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final response = await ApiClient().put('/notifications/$notificationId/read', {});
    if (response.statusCode != 200) {
      throw Exception('Error al marcar notificación como leída.');
    }
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/api_client.dart';
import '../../core/models/models.dart';

mixin WorkerChatRepositoryMixin {
  ApiClient get client;
  Future<String?> getCurrentUserId();

  Future<List<Conversation>> conversations() async {
    final response = await client.dio.get('/conversations');
    final currentUserId = await getCurrentUserId();
    final raw = response.data;
    List items = [];
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) {
        items = d;
      } else if (d is Map) {
        if (d['data'] is List) {
          items = d['data'];
        } else if (d['items'] is List) {
          items = d['items'];
        }
      }
    } else if (raw is List) {
      items = raw;
    }
    return items
        .map((item) => Conversation.fromJson(
              Map<String, dynamic>.from(item),
              currentUserId: currentUserId,
            ))
        .toList();
  }

  Future<Conversation?> getConversationById(String conversationId) async {
    try {
      final response = await client.dio.get('/conversations/$conversationId');
      final currentUserId = await getCurrentUserId();
      final raw = response.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      if (data is Map) {
        return Conversation.fromJson(
          Map<String, dynamic>.from(data),
          currentUserId: currentUserId,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final response = await client.dio.get('/conversations/$conversationId/messages');
    final currentUserId = await getCurrentUserId();
    final raw = response.data;
    List items = [];
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) {
        items = d;
      } else if (d is Map && d['data'] is List) {
        items = d['data'];
      } else if (d is Map && d['items'] is List) {
        items = d['items'];
      }
    } else if (raw is List) {
      items = raw;
    }
    return items
        .map((item) => ChatMessage.fromJson(
              Map<String, dynamic>.from(item),
              currentUserId: currentUserId,
            ))
        .toList();
  }

  Future<void> sendMessage(String conversationId, String text) async =>
      client.dio.post('/conversations/$conversationId/messages', data: {'text': text});

  Future<void> markConversationRead(String conversationId) async =>
      client.dio.patch('/conversations/$conversationId/read');

  Future<List<WorkerNotification>> notifications({int page = 1, int limit = 20}) async {
    try {
      final response = await client.dio.get('/notifications', queryParameters: {
        'page': page,
        'limit': limit,
      });
      final payload = response.data;
      dynamic itemsRaw;
      if (payload['data'] is Map) {
        if (payload['data']['data'] is Map && payload['data']['data']['items'] is List) {
          itemsRaw = payload['data']['data']['items'];
        } else if (payload['data']['items'] is List) {
          itemsRaw = payload['data']['items'];
        }
      } else if (payload['items'] is List) {
        itemsRaw = payload['items'];
      } else if (payload['data'] is List) {
        itemsRaw = payload['data'];
      }
      if (itemsRaw is List) {
        return itemsRaw
            .map((item) => WorkerNotification.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<int> unreadNotificationsCount() async {
    try {
      final response = await client.dio.get('/notifications', queryParameters: {'page': 1, 'limit': 1});
      final payload = response.data;
      if (payload['data'] is Map && payload['data']['unreadCount'] != null) {
        return (payload['data']['unreadCount'] as num).toInt();
      }
      if (payload['data'] is Map && payload['data']['data'] is Map && payload['data']['data']['unreadCount'] != null) {
        return (payload['data']['data']['unreadCount'] as num).toInt();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markNotificationRead(String id) async =>
      client.dio.patch('/notifications/$id/read');

  Future<void> markAllNotificationsRead() async =>
      client.dio.patch('/notifications/read-all');

  Future<void> registerDeviceToken(String token, {String platform = 'android'}) async {
    try {
      await client.dio.post('/notifications/register-device', data: {
        'token': token,
        'platform': platform,
      });
    } catch (_) {}
  }

  Future<void> unregisterDeviceToken(String token) async {
    try {
      await client.dio.delete('/notifications/unregister-device', data: {
        'token': token,
      });
    } catch (_) {}
  }

  Future<void> logout({String? fcmToken}) async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      String? refreshToken;
      try {
        refreshToken = await storage.read(key: 'refreshToken');
      } catch (_) {}
      await client.dio.post('/auth/logout', data: {
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        if (refreshToken != null && refreshToken.isNotEmpty)
          'refreshToken': refreshToken,
      });
    } catch (_) {}
  }
}

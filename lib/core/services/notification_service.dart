import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/repositories/worker_repository.dart';
import '../../main.dart';
import '../../screens/notifications/notifications_screen.dart';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ignore: avoid_print
  print('🔔 [FCM] Background message: ${message.messageId} — ${message.notification?.title ?? message.data['title']}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _repo = WorkerRepository();
  final _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const _tokenKey = 'fcmDeviceToken';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id matching AndroidManifest.xml
    'High Importance Notifications', // title
    description: 'This channel is used for important heads-up popup notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize FCM & Local Notifications:
  /// - Sets up notification channels for Android heads-up popup banners
  /// - Requests runtime permissions on Android 13+ and iOS
  /// - Registers FCM token with backend
  /// - Displays foreground push notifications as visible popups
  /// - Handles notification click interactions
  Future<void> initialize() async {
    try {
      // 1. Initialize local notification display
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
      const initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationTap(response.payload);
        },
      );

      // 2. Create the Android Notification Channel with MAX importance
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
        // Request POST_NOTIFICATIONS permission on Android 13+
        await androidPlugin.requestNotificationsPermission();
      }

      // 3. Request FCM notification permission (Android 13+ and iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      // ignore: avoid_print
      print('🔔 [FCM] Permission status: ${settings.authorizationStatus}');

      // Enable foreground notification presentation options for iOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 4. Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          // ignore: avoid_print
          print('🔔 [FCM] Device Token: $token');
          await registerDeviceToken(token);
        }

        // 5. Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          registerDeviceToken(newToken);
        });

        // 6. Handle foreground messages -> Display popup heads-up banner!
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          // ignore: avoid_print
          print('🔔 [FCM] Foreground message received: ${message.notification?.title ?? message.data['title']}');
          _showForegroundNotification(message);
        });

        // 7. Handle when user taps on background notification
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          // ignore: avoid_print
          print('🔔 [FCM] Notification tapped from background: ${message.data}');
          _handleNotificationTap(jsonEncode(message.data));
        });

        // 8. Handle if app was opened directly from a terminated state notification
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          // ignore: avoid_print
          print('🔔 [FCM] App opened from terminated notification: ${initialMessage.data}');
          _handleNotificationTap(jsonEncode(initialMessage.data));
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [FCM] Initialization error: $e');
    }
  }

  /// Displays incoming FCM message as a system heads-up popup banner
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'BuildHire Notification';
    final body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? '';

    await showLocalNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  /// Displays an immediate high-priority system popup banner on the device
  Future<void> showLocalNotification({
    int? id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final notificationId = id ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000).abs();
      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [Notification] Failed to show local notification: $e');
    }
  }

  /// Handle navigation when a notification banner is tapped
  void _handleNotificationTap(String? payload) {
    if (payload != null && kDebugMode) {
      // ignore: avoid_print
      print('🔔 [Notification] Tapped payload: $payload');
    }
    // Navigate to Notifications Screen
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    }
  }

  /// Register or update device token with the backend API
  Future<void> registerDeviceToken(String fcmToken) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _repo.registerDeviceToken(fcmToken, platform: platform);
      await _storage.write(key: _tokenKey, value: fcmToken);
      // ignore: avoid_print
      print('🔔 [FCM] Successfully registered device token with backend ($platform)');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [FCM] Failed to register device token: $e');
    }
  }

  /// Get locally stored device token
  Future<String?> getStoredToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  /// Explicitly unregister device token
  Future<void> unregisterDeviceToken() async {
    try {
      final token = await getStoredToken();
      if (token != null && token.isNotEmpty) {
        await _repo.unregisterDeviceToken(token);
        await _storage.delete(key: _tokenKey);
        // ignore: avoid_print
        print('🔔 [FCM] Unregistered device token');
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [FCM] Failed to unregister device token: $e');
    }
  }

  /// Ensure device token is registered for the currently logged-in user.
  /// Called on login/register/app-startup.
  Future<void> syncDeviceToken({String? token}) async {
    try {
      String? activeToken = token;
      if (activeToken == null || activeToken.isEmpty) {
        // Try to get real FCM token
        activeToken = await _messaging.getToken();
      }
      if (activeToken == null || activeToken.isEmpty) {
        // Fallback: use stored token
        activeToken = await getStoredToken();
      }
      if (activeToken != null && activeToken.isNotEmpty) {
        await registerDeviceToken(activeToken);
      } else {
        if (kDebugMode) {
          print('⚠️ [FCM] No FCM token available — push notifications will not work');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [FCM] syncDeviceToken error: $e');
      }
    }
  }

  /// Clean logout passing the FCM token to backend
  Future<void> handleLogout() async {
    try {
      final token = await getStoredToken();
      await _repo.logout(fcmToken: token);
      await _storage.delete(key: _tokenKey);
      // ignore: avoid_print
      print('🔔 [FCM] Logged out device with token');
    } catch (_) {}
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// =========================================================
// BACKGROUND FCM HANDLER
// =========================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Background handler Firebase.initializeApp error: $e');
  }

  debugPrint(
    'Background FCM: ${message.messageId}',
  );

  debugPrint(
    'Background Title: '
    '${message.notification?.title}',
  );

  debugPrint(
    'Background Body: '
    '${message.notification?.body}',
  );

  debugPrint(
    'Background Data: ${message.data}',
  );
}

// =========================================================
// NOTIFICATION SERVICE
// =========================================================

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  // =======================================================
  // FIREBASE MESSAGING
  // =======================================================

  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  // =======================================================
  // LOCAL NOTIFICATIONS
  // =======================================================

  final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  // =======================================================
  // ANDROID CHANNEL
  // =======================================================

  static const AndroidNotificationChannel
      _channel =
      AndroidNotificationChannel(
    'khempay_high_importance',
    'KhemPay Notifications',
    description:
        'Notifications for transfers and transactions',
    importance:
        Importance.max,
  );

  // =========================================================
  // INITIALIZE
  // =========================================================

  Future<void> initialize() async {
    // =====================================================
    // BACKGROUND FCM
    // =====================================================
    try {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );
    } catch (e) {
      debugPrint('FCM background handler error: $e');
    }

    // =====================================================
    // LOCAL NOTIFICATION
    // =====================================================
    try {
      await _initializeLocalNotification();
    } catch (e) {
      debugPrint('Local notification init error: $e');
    }

    // =====================================================
    // REQUEST FIREBASE NOTIFICATION PERMISSION
    // =====================================================
    try {
      final NotificationSettings settings =
          await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint(
        'Notification permission: '
        '${settings.authorizationStatus}',
      );
    } catch (e) {
      debugPrint('FCM requestPermission error: $e');
    }

    // =====================================================
    // FCM TOKEN
    // =====================================================
    try {
      final String? token = await _messaging.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('FCM getToken timed out');
          return null;
        },
      );

      debugPrint(
        '================================',
      );

      debugPrint(
        'FCM TOKEN: $token',
      );

      debugPrint(
        '================================',
      );
    } catch (e) {
      debugPrint('FCM getToken error: $e');
    }

    // =====================================================
    // FOREGROUND MESSAGE
    // =====================================================
    try {
      FirebaseMessaging.onMessage.listen(
        (
          RemoteMessage message,
        ) async {
          debugPrint(
            '========== FCM RECEIVED ==========',
          );

          debugPrint(
            'Message ID: '
            '${message.messageId}',
          );

          debugPrint(
            'Title: '
            '${message.notification?.title}',
          );

          debugPrint(
            'Body: '
            '${message.notification?.body}',
          );

          debugPrint(
            'Data: ${message.data}',
          );

          debugPrint(
            '==================================',
          );

          // SHOW POPUP WHEN APP IS OPEN
          await _showLocalNotification(
            message,
          );
        },
      );
    } catch (e) {
      debugPrint('FCM onMessage listener error: $e');
    }

    // =====================================================
    // USER CLICK FCM NOTIFICATION
    // APP WAS BACKGROUND
    // =====================================================
    try {
      FirebaseMessaging.onMessageOpenedApp.listen(
        (
          RemoteMessage message,
        ) {
          debugPrint(
            'FCM notification clicked',
          );

          debugPrint(
            'Data: ${message.data}',
          );

          _handleNotificationClick(
            message.data,
          );
        },
      );
    } catch (e) {
      debugPrint('FCM onMessageOpenedApp listener error: $e');
    }

    // =====================================================
    // APP OPENED FROM TERMINATED STATE
    // =====================================================
    try {
      final RemoteMessage? initialMessage =
          await _messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          'App opened from terminated notification',
        );

        debugPrint(
          'Data: ${initialMessage.data}',
        );

        _handleNotificationClick(
          initialMessage.data,
        );
      }
    } catch (e) {
      debugPrint('FCM getInitialMessage error: $e');
    }

    // =====================================================
    // FCM TOKEN REFRESH
    // =====================================================
    try {
      _messaging.onTokenRefresh.listen(
        (
          String token,
        ) {
          debugPrint(
            '================================',
          );

          debugPrint(
            'NEW FCM TOKEN: $token',
          );

          debugPrint(
            '================================',
          );
        },
      );
    } catch (e) {
      debugPrint('FCM onTokenRefresh listener error: $e');
    }
  }

  // =========================================================
  // INITIALIZE LOCAL NOTIFICATION
  // =========================================================

  Future<void> _initializeLocalNotification() async {
    try {
      // ANDROID INITIALIZATION
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );

      // INITIALIZATION SETTINGS
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidSettings,
      );

      // INITIALIZE PLUGIN
      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (
          NotificationResponse response,
        ) async {
          debugPrint(
            'Local notification clicked',
          );

          debugPrint(
            'Payload: ${response.payload}',
          );
        },
      );

      // GET ANDROID PLUGIN
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // CREATE CHANNEL
      await androidPlugin?.createNotificationChannel(
        _channel,
      );

      // ANDROID 13+ PERMISSION
      final bool? permissionGranted =
          await androidPlugin?.requestNotificationsPermission();

      debugPrint(
        'Android notification permission: '
        '$permissionGranted',
      );
    } catch (e) {
      debugPrint('Local notifications init error: $e');
    }
  }

  // =========================================================
  // SHOW LOCAL NOTIFICATION
  // =========================================================

  Future<void> _showLocalNotification(
    RemoteMessage message,
  ) async {
    try {
      final RemoteNotification? notification =
          message.notification;

      // NO NOTIFICATION PAYLOAD
      if (notification == null) {
        debugPrint(
          'FCM notification payload is null',
        );
        return;
      }

      final String title =
          notification.title ??
              'KhemPay';

      final String body =
          notification.body ??
              '';

      // ANDROID NOTIFICATION DETAILS
      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription:
            _channel.description,
        importance:
            Importance.max,
        priority:
            Priority.high,
        playSound:
            true,
        enableVibration:
            true,
        icon:
            '@mipmap/launcher_icon',
      );

      // NOTIFICATION DETAILS
      final NotificationDetails notificationDetails =
          NotificationDetails(
        android:
            androidNotificationDetails,
      );

      // SHOW POPUP
      await _localNotifications.show(
        id: notification.hashCode,
        title: title,
        body: body,
        notificationDetails:
            notificationDetails,
        payload:
            message.data.toString(),
      );

      debugPrint(
        'Local notification shown',
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  // =========================================================
  // NOTIFICATION CLICK HANDLER
  // =========================================================

  void _handleNotificationClick(
    Map<String, dynamic> data,
  ) {
    final String type =
        data['type']
                ?.toString()
                .trim() ??
            '';

    final String transactionId =
        data['transaction_id']
                ?.toString()
                .trim() ??
            '';

    debugPrint(
      'Notification type: $type',
    );

    debugPrint(
      'Transaction ID: $transactionId',
    );
  }

  // =========================================================
  // GET FCM TOKEN
  // =========================================================

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // =========================================================
  // DELETE FCM TOKEN
  // =========================================================

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint(
        'FCM token deleted',
      );
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}

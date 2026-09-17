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
  await Firebase.initializeApp();

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

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );


    // =====================================================
    // LOCAL NOTIFICATION
    // =====================================================

    await _initializeLocalNotification();


    // =====================================================
    // REQUEST FIREBASE NOTIFICATION PERMISSION
    // =====================================================

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


    // =====================================================
    // FCM TOKEN
    // =====================================================

    final String? token =
        await _messaging.getToken();


    debugPrint(
      '================================',
    );

    debugPrint(
      'FCM TOKEN: $token',
    );

    debugPrint(
      '================================',
    );


    // =====================================================
    // FOREGROUND MESSAGE
    // =====================================================

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


        // =================================================
        // SHOW POPUP WHEN APP IS OPEN
        // =================================================

        await _showLocalNotification(
          message,
        );
      },
    );


    // =====================================================
    // USER CLICK FCM NOTIFICATION
    // APP WAS BACKGROUND
    // =====================================================

    FirebaseMessaging
        .onMessageOpenedApp
        .listen(
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


    // =====================================================
    // APP OPENED FROM TERMINATED STATE
    // =====================================================

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


    // =====================================================
    // FCM TOKEN REFRESH
    // =====================================================

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


        /*
         * Later:
         *
         * Send new FCM token
         * to FastAPI backend.
         *
         * Example:
         *
         * NotificationApi()
         *     .saveFcmToken(token);
         */
      },
    );
  }


  // =========================================================
  // INITIALIZE LOCAL NOTIFICATION
  // =========================================================

  Future<void>
      _initializeLocalNotification() async {
    // =====================================================
    // ANDROID INITIALIZATION
    // =====================================================

    const AndroidInitializationSettings
        androidSettings =
        AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );


    // =====================================================
    // INITIALIZATION SETTINGS
    // =====================================================

    const InitializationSettings
        initializationSettings =
        InitializationSettings(
      android:
          androidSettings,
    );


    // =====================================================
    // INITIALIZE PLUGIN
    // =====================================================

    await _localNotifications.initialize(
      settings:
          initializationSettings,

      onDidReceiveNotificationResponse:
          (
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


    // =====================================================
    // GET ANDROID PLUGIN
    // =====================================================

    final AndroidFlutterLocalNotificationsPlugin?
        androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();


    // =====================================================
    // CREATE CHANNEL
    // =====================================================

    await androidPlugin
        ?.createNotificationChannel(
      _channel,
    );


    // =====================================================
    // ANDROID 13+ PERMISSION
    // =====================================================

    final bool? permissionGranted =
        await androidPlugin
            ?.requestNotificationsPermission();


    debugPrint(
      'Android notification permission: '
      '$permissionGranted',
    );
  }


  // =========================================================
  // SHOW LOCAL NOTIFICATION
  // =========================================================

  Future<void> _showLocalNotification(
    RemoteMessage message,
  ) async {
    final RemoteNotification? notification =
        message.notification;


    // =====================================================
    // NO NOTIFICATION PAYLOAD
    // =====================================================

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


    // =====================================================
    // ANDROID NOTIFICATION DETAILS
    // =====================================================

    final AndroidNotificationDetails
        androidNotificationDetails =
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


    // =====================================================
    // NOTIFICATION DETAILS
    // =====================================================

    final NotificationDetails
        notificationDetails =
        NotificationDetails(
      android:
          androidNotificationDetails,
    );


    // =====================================================
    // SHOW POPUP
    // =====================================================

    await _localNotifications.show(
      id:
          notification.hashCode,

      title:
          title,

      body:
          body,

      notificationDetails:
          notificationDetails,

      payload:
          message.data.toString(),
    );


    debugPrint(
      'Local notification shown',
    );
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


    // =====================================================
    // EXAMPLE NAVIGATION LATER
    // =====================================================

    /*
    if (
        type == 'transfer_received' ||
        type == 'transfer_sent') {

      Get.toNamed(
        AppRoutes.transactionDetail,

        arguments: {
          'transaction_id':
              transactionId,
        },
      );
    }
    */
  }


  // =========================================================
  // GET FCM TOKEN
  // =========================================================

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }


  // =========================================================
  // DELETE FCM TOKEN
  // =========================================================

  Future<void> deleteToken() async {
    await _messaging.deleteToken();

    debugPrint(
      'FCM token deleted',
    );
  }
}
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/app/routes/page_route.dart';
import 'package:mobile_banking_app/core/service/notification_service.dart';
import 'package:mobile_banking_app/screen/security/pin/pin_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage
  await GetStorage.init();

  // PIN Controller
  Get.put<PinController>(
    PinController(),
    permanent: true,
  );

  // Initialize Firebase safely
  try {
    await Firebase.initializeApp();
    // Initialize Notification service in the background (non-blocking)
    NotificationService.instance.initialize().catchError((dynamic e) {
      debugPrint('NotificationService init error: $e');
    });
  } catch (e) {
    debugPrint('Firebase.initializeApp error: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}

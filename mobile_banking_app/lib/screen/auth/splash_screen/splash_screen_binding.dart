import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/auth/splash_screen/splash_screen_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashViewController>(
      SplashViewController(),
    );
  }
}
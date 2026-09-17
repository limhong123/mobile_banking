import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/security/pin/pin_controller.dart';

class PinBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PinController>()) {
      Get.put<PinController>(
        PinController(),
        permanent: true,
      );
    }
  }
}
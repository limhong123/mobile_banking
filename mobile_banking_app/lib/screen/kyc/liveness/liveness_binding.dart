import 'package:get/get.dart';

import 'package:mobile_banking_app/screen/kyc/liveness/liveness_controller.dart';

class LivenessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LivenessController>(
      () => LivenessController(),
    );
  }
}
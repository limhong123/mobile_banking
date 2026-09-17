import 'package:get/get.dart';

import 'package:mobile_banking_app/screen/kyc/result/result_controller.dart';

class ResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResultController>(
      () => ResultController(),
    );
  }
}
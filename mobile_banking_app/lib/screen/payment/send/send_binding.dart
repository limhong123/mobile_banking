import 'package:get/get.dart';

import 'package:mobile_banking_app/screen/payment/send/send_controller.dart';


class SendBinding
    extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<
        SendController>(
      () =>
          SendController(),
    );
  }
}
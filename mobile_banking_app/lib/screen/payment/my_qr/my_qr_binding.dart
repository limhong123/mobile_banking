

import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/payment/my_qr/my_qr_controller.dart';

class MyQrBinding
    extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<
        MyQrController>(
      () =>
          MyQrController(),
    );
  }
}
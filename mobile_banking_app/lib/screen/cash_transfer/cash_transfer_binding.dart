import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/cash_transfer/cash_transfer_controller.dart';




class CashReceiveBinding
    extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<
        CashReceiveController>(
      () =>
          CashReceiveController(),
    );
  }
}
import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/scan_qr/scan_qr_controller.dart';



class ScanQrBinding
    extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<
        ScanQrController>(
      () =>
          ScanQrController(),
    );
  }
}
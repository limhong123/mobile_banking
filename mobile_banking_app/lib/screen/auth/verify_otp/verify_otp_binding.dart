import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/auth/verify_otp/verify_otp_controller.dart';

class VerifyOtpBinding
    extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<
        VerifyOtpViewController>(
      () => VerifyOtpViewController(),
    );
  }
}
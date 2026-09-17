import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/auth/login/login_controller.dart';

class LoginViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginViewController>(
      () => LoginViewController(),
    );
  }
}
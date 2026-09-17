
import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/auth/register/register_controller.dart';

class RegisterViewBinding extends Bindings {

   @override
   void dependencies() {
       Get.lazyPut(() => RegisterViewController());
   }
}
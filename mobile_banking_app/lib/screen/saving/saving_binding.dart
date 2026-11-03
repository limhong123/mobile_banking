import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/saving/saving_controller.dart';

class SavingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SavingController>(() => SavingController());
  }
}

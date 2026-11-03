import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/home/home_controller.dart';

class HomeViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeViewController());
  }
}

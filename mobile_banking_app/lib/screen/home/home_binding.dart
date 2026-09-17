

import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:mobile_banking_app/screen/home/home_controller.dart';

class HomeViewBinding extends Bindings {

   @override
   void dependencies() {
       Get.lazyPut(() => HomeViewController());
   }
}
import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/analyst/analys_date/analys_date_controller.dart';

class AnalysDateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnalysDateController>(
      () => AnalysDateController(),
    );
  }
}
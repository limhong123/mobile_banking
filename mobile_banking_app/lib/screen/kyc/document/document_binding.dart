import 'package:get/get.dart';

import 'package:mobile_banking_app/screen/kyc/document/document_controller.dart';

class DocumentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DocumentController>(
      () => DocumentController(),
    );
  }
}
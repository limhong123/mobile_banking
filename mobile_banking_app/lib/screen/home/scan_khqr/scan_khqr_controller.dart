part of 'scan_khqr_view.dart';

class ScanKhqrViewController extends GetxController {
  void goToScanner() {
    Get.toNamed(AppRoutes.scanQr);
  }

  void goToMyQr() {
    Get.toNamed(AppRoutes.myQr);
  }
}

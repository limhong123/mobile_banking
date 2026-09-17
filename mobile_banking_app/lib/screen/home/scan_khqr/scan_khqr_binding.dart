part of 'scan_khqr_view.dart';

class ScanKhqrViewBinding extends Bindings {

   @override
   void dependencies() {
       Get.lazyPut(() => ScanKhqrViewController());
   }
}
part of 'bottom_nav_view.dart';

class BottomNavViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BottomNavViewController());
    Get.lazyPut<HomeViewController>(
      () => HomeViewController(),
    );

    Get.lazyPut<SavingController>(
      () => SavingController(),
    );

    Get.lazyPut<AnalysDateController>(
      () => AnalysDateController(),
    );

    Get.lazyPut<ProfileViewController>(
      () => ProfileViewController(),
    );
  }
}

part of 'profile_view.dart';

class ProfileViewController extends GetxController {

  @override
  void onInit() {
    super.onInit();
  }
  void logout(){
    AuthApi().logout();
    Get.offAllNamed(AppRoutes.login);
  }
}
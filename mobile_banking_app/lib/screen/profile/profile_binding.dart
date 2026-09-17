part of 'profile_view.dart';

class ProfileViewBinding extends Bindings {

   @override
   void dependencies() {
       Get.lazyPut(() => ProfileViewController());
   }
}
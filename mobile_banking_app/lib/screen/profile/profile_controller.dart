import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/core/api/auth/auth_api.dart';
import 'package:mobile_banking_app/core/api/profile/profile_api.dart';
import 'package:mobile_banking_app/screen/home/home_controller.dart';

class ProfileViewController extends GetxController {
  final ProfileApi _profileApi = ProfileApi();
  final ImagePicker _picker = ImagePicker();
  
  final isLoading = false.obs;
  

  void logout() {
    AuthApi().logout();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> uploadPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      isLoading.value = true;
      
      await _profileApi.uploadProfilePhoto(
        filePath: image.path,
        fileName: image.name,
      );

      // Refresh user data in HomeController
      if (Get.isRegistered<HomeViewController>()) {
        await Get.find<HomeViewController>().getUser();
      }

      Get.snackbar('Success', 'Profile photo uploaded successfully', 
        backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload photo: $e', 
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfileInfo(String firstName, String lastName) async {
    try {
      isLoading.value = true;
      await _profileApi.updateProfile(
        firstName: firstName.isNotEmpty ? firstName : null,
        lastName: lastName.isNotEmpty ? lastName : null,
      );
      
      // Refresh user data in HomeController
      if (Get.isRegistered<HomeViewController>()) {
        await Get.find<HomeViewController>().getUser();
      }
      
      Get.back(); // close dialog
      Get.snackbar('Success', 'Profile updated successfully',
        backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e',
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
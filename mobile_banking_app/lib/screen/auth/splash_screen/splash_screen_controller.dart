import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/core/api/auth/auth_api.dart';
import 'package:mobile_banking_app/core/api/config.dart';


class SplashViewController
    extends GetxController {
  final GetStorage box =
      GetStorage();

  final AuthApi authApi =
      AuthApi();

  final Config config =
      Config.instance;


  @override
  void onInit() {
    super.onInit();

    checkLogin();
  }


  // =========================================================
  // CHECK LOGIN
  // =========================================================

  Future<void> checkLogin() async {
    await Future.delayed(
      const Duration(
        seconds: 2,
      ),
    );


    final String token =
        config
                .getToken()
                ?.trim() ??
            '';


    if (kDebugMode) {
      debugPrint(
        'SPLASH TOKEN EXISTS: ${token.isNotEmpty}',
      );
    }


    // =====================================================
    // NO ACCESS TOKEN
    // =====================================================

    if (token.isEmpty) {
      Get.offAllNamed(
        AppRoutes.login,
      );

      return;
    }


    try {
      // ===================================================
      // GET CURRENT USER
      // ===================================================

      final dynamic response =
          await authApi.getMe();


      if (kDebugMode) {
        debugPrint(
          'GET ME RESPONSE: $response',
        );
      }


      if (response is! Map) {
        throw Exception(
          'User response មិនត្រឹមត្រូវ',
        );
      }


      // ===================================================
      // IMPORTANT:
      // /auth/me returns user inside data
      // ===================================================

      final dynamic data =
          response['data'];


      if (data is! Map) {
        throw Exception(
          'User data មិនត្រឹមត្រូវ',
        );
      }


      final String role =
          data['role']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              'user';


      final String status =
          data['kyc_status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';


      final bool isVerified =
          data['is_verified'] ==
              true;


      final String phoneNumber =
          data['phone_number']
                  ?.toString()
                  .trim() ??
              '';


      if (kDebugMode) {
        debugPrint(
          'ROLE: $role',
        );

        debugPrint(
          'KYC STATUS: $status',
        );

        debugPrint(
          'PHONE VERIFIED: $isVerified',
        );
      }


      // ===================================================
      // APPROVED CUSTOMER
      // ===================================================

      if (
          role == 'user' &&
          status ==
              'approved') {
        // clean old KYC session
        await box.remove(
          'kyc_token',
        );

        await box.remove(
          'kyc_status',
        );

        await box.remove(
          'kyc_phone_number',
        );


        Get.offAllNamed(
          AppRoutes.bottomNavigation,
        );

        return;
      }


      // ===================================================
      // PHONE NOT VERIFIED
      // ===================================================

      if (!isVerified) {
        await config.removeToken();

        Get.offAllNamed(
          AppRoutes.login,
          arguments: {
            'phone_number':
                phoneNumber,
          },
        );

        return;
      }


      // ===================================================
      // KYC INCOMPLETE
      //
      // Do NOT automatically send user to NID here.
      // Login -> resumeKyc() should decide next_step.
      // ===================================================

      await config.removeToken();


      Get.offAllNamed(
        AppRoutes.login,
        arguments: {
          'phone_number':
              phoneNumber,
        },
      );

    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'SPLASH ERROR: $error',
        );
      }


      // token expired / invalid
      await config.removeToken();


      Get.offAllNamed(
        AppRoutes.login,
      );
    }
  }
}
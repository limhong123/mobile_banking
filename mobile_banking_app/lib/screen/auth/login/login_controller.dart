import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/core/api/auth/auth_api.dart';
import 'package:mobile_banking_app/core/api/config.dart';
import 'package:mobile_banking_app/core/api/notification_api.dart';
import 'package:mobile_banking_app/core/service/notification_service.dart';


class LoginViewController extends GetxController {
  final AuthApi authApi = AuthApi();

  final NotificationApi notificationApi =
      NotificationApi();

  final Config config =
      Config.instance;

  final GetStorage box =
      GetStorage();

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController pinController =
      TextEditingController();

  final isLoading =
      false.obs;

  final isResumingKyc =
      false.obs;

  final isPinHidden =
      true.obs;


  // =========================================================
  // INIT
  // =========================================================

  @override
  void onInit() {
    super.onInit();

    _loadPhone();
  }


  // =========================================================
  // LOAD PHONE
  // =========================================================

  void _loadPhone() {
    final dynamic arguments =
        Get.arguments;

    if (arguments is Map) {
      final String phone =
          arguments['phone_number']
                  ?.toString()
                  .trim() ??
              '';

      if (phone.isNotEmpty) {
        phoneController.text =
            phone;

        return;
      }
    }

    final String savedPhone =
        box
                .read(
                  'kyc_phone_number',
                )
                ?.toString()
                .trim() ??
            '';

    if (savedPhone.isNotEmpty) {
      phoneController.text =
          savedPhone;
    }
  }


  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> login() async {
    if (
        isLoading.value ||
        isResumingKyc.value) {
      return;
    }

    final bool isValid =
        formKey.currentState
                ?.validate() ??
            false;

    if (!isValid) {
      return;
    }

    final String phone =
        phoneController.text
            .trim();

    final String pin =
        pinController.text
            .trim();

    try {
      isLoading.value =
          true;

      // =====================================================
      // REMOVE OLD SESSION
      // =====================================================

      await config.removeToken();

      // =====================================================
      // LOGIN API
      // =====================================================

      final dynamic response =
          await authApi.login(
        phoneNumber:
            phone,

        pin:
            pin,
      );

      if (response is! Map) {
        throw Exception(
          'Login response មិនត្រឹមត្រូវ',
        );
      }

      // =====================================================
      // ACCESS TOKEN
      // =====================================================

      final String accessToken =
          response['access_token']
                  ?.toString()
                  .trim() ??
              '';

      if (accessToken.isEmpty) {
        throw Exception(
          'Server មិនបានផ្ញើ access token',
        );
      }

      // =====================================================
      // USER
      // =====================================================

      final dynamic user =
          response['user'];

      if (user is! Map) {
        throw Exception(
          'User response មិនត្រឹមត្រូវ',
        );
      }

      final String role =
          user['role']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              'user';

      final String kycStatus =
          user['kyc_status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              'not_submitted';

      // =====================================================
      // CHECK KYC
      // =====================================================

      if (
          role == 'user' &&
          kycStatus !=
              'approved') {
        throw Exception(
          'KYC_INCOMPLETE:$kycStatus',
        );
      }

      // =====================================================
      // SAVE ACCESS TOKEN FIRST
      // =====================================================

      await config.saveToken(
        accessToken,
      );

      // =====================================================
      // SAVE REFRESH TOKEN
      // =====================================================

      final String refreshToken =
          response['refresh_token']
                  ?.toString()
                  .trim() ??
              '';

      if (refreshToken.isNotEmpty) {
        await box.write(
          'refresh_token',
          refreshToken,
        );
      }

      // =====================================================
      // SAVE FCM TOKEN TO BACKEND
      // =====================================================

      await _saveFcmToken();

      // =====================================================
      // CLEAN KYC SESSION
      // =====================================================

      await box.remove(
        'kyc_token',
      );

      await box.remove(
        'kyc_status',
      );

      // =====================================================
      // NORMAL USER LOGIN
      // =====================================================

      if (role == 'user') {
        Get.offAllNamed(
          AppRoutes.bottomNavigation,
        );

        return;
      }

      Get.offAllNamed(
        AppRoutes.bottomNavigation,
      );

    } catch (error) {
      await config.removeToken();

      final String message =
          _cleanError(
        error,
      );

      isLoading.value =
          false;

      // =====================================================
      // KYC INCOMPLETE
      // =====================================================

      if (
          _isKycIncompleteError(
            message,
          )) {
        await _showResumeKycDialog(
          phone,
          pin,
        );

        return;
      }

      // =====================================================
      // PHONE OTP NOT VERIFIED
      // =====================================================

      if (
          _isOtpRequiredError(
            message,
          )) {
        Get.snackbar(
          'ត្រូវផ្ទៀងផ្ទាត់ OTP',
          'លេខទូរស័ព្ទនេះមិនទាន់បានផ្ទៀងផ្ទាត់ទេ។',
          snackPosition:
              SnackPosition.BOTTOM,
        );

        return;
      }

      Get.snackbar(
        'Login បរាជ័យ',
        message,
        snackPosition:
            SnackPosition.BOTTOM,
      );

    } finally {
      isLoading.value =
          false;
    }
  }


  // =========================================================
  // SAVE FCM TOKEN
  // =========================================================

  Future<void> _saveFcmToken() async {
    try {
      final String? fcmToken =
          await NotificationService
              .instance
              .getToken();

      if (
          fcmToken == null ||
          fcmToken.isEmpty) {
        debugPrint(
          'FCM token is empty',
        );

        return;
      }

      debugPrint(
        'FCM TOKEN LOGIN: $fcmToken',
      );

      await notificationApi
          .saveFcmToken(
        fcmToken,
      );

      debugPrint(
        'FCM token saved to backend',
      );

    } catch (error) {
      /*
       * Important:
       * Notification error must NOT
       * block user login.
       */
      debugPrint(
        'Save FCM token error: $error',
      );
    }
  }


  // =========================================================
  // DETECT KYC ERROR
  // =========================================================

  bool _isKycIncompleteError(
    String message,
  ) {
    final String value =
        message.toLowerCase();

    return value.contains(
          'kyc_incomplete',
        ) ||
        value.contains(
          'please complete identity verification',
        ) ||
        value.contains(
          'please complete kyc',
        );
  }


  // =========================================================
  // DETECT OTP ERROR
  // =========================================================

  bool _isOtpRequiredError(
    String message,
  ) {
    final String value =
        message.toLowerCase();

    return value.contains(
          'phone verification required',
        ) ||
        value.contains(
          'verify_otp',
        );
  }


  // =========================================================
  // RESUME KYC DIALOG
  // =========================================================

  Future<void>
      _showResumeKycDialog(
    String phone,
    String pin,
  ) async {
    await Get.dialog(
      AlertDialog(
        title:
            const Text(
          'KYC មិនទាន់បញ្ចប់',
        ),

        content:
            const Text(
          'គណនីនេះបានផ្ទៀងផ្ទាត់លេខទូរស័ព្ទរួចហើយ '
          'ប៉ុន្តែ KYC មិនទាន់រួច។ '
          'តើអ្នកចង់បន្ត KYC ទេ?',
        ),

        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },

            child:
                const Text(
              'បោះបង់',
            ),
          ),

          ElevatedButton(
            onPressed: () {
              Get.back();

              resumeKyc(
                phone:
                    phone,

                pin:
                    pin,
              );
            },

            child:
                const Text(
              'បន្ត KYC',
            ),
          ),
        ],
      ),

      barrierDismissible:
          false,
    );
  }


  // =========================================================
  // RESUME KYC
  // =========================================================

  Future<void> resumeKyc({
    required String phone,
    required String pin,
  }) async {
    if (
        isResumingKyc.value) {
      return;
    }

    try {
      isResumingKyc.value =
          true;

      final dynamic response =
          await authApi.resumeKyc(
        phoneNumber:
            phone,

        pin:
            pin,
      );

      if (response is! Map) {
        throw Exception(
          'Resume KYC response មិនត្រឹមត្រូវ',
        );
      }

      final String kycStatus =
          response['kyc_status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              'not_submitted';

      final String nextStep =
          response['next_step']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      // =====================================================
      // ALREADY APPROVED
      // =====================================================

      if (
          kycStatus ==
              'approved' ||
          nextStep ==
              'login') {
        Get.snackbar(
          'KYC រួចរាល់',
          'KYC បានអនុម័តរួច។ សូម Login ម្តងទៀត។',
          snackPosition:
              SnackPosition.BOTTOM,
        );

        return;
      }

      // =====================================================
      // SAVE KYC TOKEN
      // =====================================================

      final String kycToken =
          response['kyc_token']
                  ?.toString()
                  .trim() ??
              '';

      if (kycToken.isEmpty) {
        throw Exception(
          'Server មិនបានផ្ញើ KYC token',
        );
      }

      await box.write(
        'kyc_token',
        kycToken,
      );

      await box.write(
        'kyc_phone_number',
        phone,
      );

      await box.write(
        'kyc_status',
        kycStatus,
      );

      // =====================================================
      // KYC ROUTING
      // =====================================================

      _goToKycStep(
        nextStep,
        phone,
      );

    } catch (error) {
      Get.snackbar(
        'បន្ត KYC បរាជ័យ',
        _cleanError(
          error,
        ),
        snackPosition:
            SnackPosition.BOTTOM,
      );

    } finally {
      isResumingKyc.value =
          false;
    }
  }


  // =========================================================
  // KYC ROUTING
  // =========================================================

  void _goToKycStep(
    String nextStep,
    String phone,
  ) {
    switch (nextStep) {

      case 'scan_nid_front':
        Get.offAllNamed(
          AppRoutes.kycDocument,

          arguments: {
            'phone_number':
                phone,
          },
        );

        break;

      case 'face_scan':
        Get.offAllNamed(
          AppRoutes.kycLiveness,

          arguments: {
            'phone_number':
                phone,
          },
        );

        break;

      case 'login':
        Get.snackbar(
          'KYC រួចរាល់',
          'សូម Login ដើម្បីបន្ត',
          snackPosition:
              SnackPosition.BOTTOM,
        );

        break;

      default:
        Get.offAllNamed(
          AppRoutes.kycDocument,

          arguments: {
            'phone_number':
                phone,
          },
        );

        break;
    }
  }


  // =========================================================
  // PIN VISIBILITY
  // =========================================================

  void togglePinVisibility() {
    isPinHidden.value =
        !isPinHidden.value;
  }


  // =========================================================
  // PHONE VALIDATION
  // =========================================================

  String? validatePhone(
    String? value,
  ) {
    final String phone =
        value?.trim() ??
            '';

    if (phone.isEmpty) {
      return (
        'សូមបញ្ចូលលេខទូរស័ព្ទ'
      );
    }

    if (phone.length < 8) {
      return (
        'លេខទូរស័ព្ទមិនត្រឹមត្រូវ'
      );
    }

    return null;
  }


  // =========================================================
  // PIN VALIDATION
  // =========================================================

  String? validatePin(
    String? value,
  ) {
    final String pin =
        value?.trim() ??
            '';

    if (pin.isEmpty) {
      return (
        'សូមបញ្ចូល PIN'
      );
    }

    if (
        !RegExp(
          r'^[0-9]{6}$',
        ).hasMatch(
          pin,
        )) {
      return (
        'PIN ត្រូវមានតែលេខ 6 ខ្ទង់'
      );
    }

    return null;
  }


  // =========================================================
  // KYC MESSAGE
  // =========================================================

  String kycMessage(
    String status,
  ) {
    switch (status) {

      case 'not_submitted':
        return (
          'សូមថត NID ខាងមុខ'
        );

      case 'nid_uploaded':
        return (
          'សូមបន្តផ្ទៀងផ្ទាត់មុខ'
        );

      case 'approved':
        return (
          'KYC បានអនុម័ត'
        );

      case 'rejected':
        return (
          'KYC មិនជោគជ័យ។ សូមធ្វើម្តងទៀត'
        );

      default:
        return (
          'KYC មិនទាន់រួចរាល់'
        );
    }
  }


  // =========================================================
  // CLEAN ERROR
  // =========================================================

  String _cleanError(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }


  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void onClose() {
    phoneController.dispose();

    pinController.dispose();

    super.onClose();
  }
}
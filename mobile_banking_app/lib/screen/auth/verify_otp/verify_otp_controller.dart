import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/core/api/auth/auth_api.dart';

class VerifyOtpViewController
    extends GetxController {
  final AuthApi authApi = AuthApi();
  final GetStorage box = GetStorage();

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final TextEditingController otpController =
      TextEditingController();

  final phoneNumber = ''.obs;

  final isLoading = false.obs;
  final isResending = false.obs;
  final secondsRemaining = 60.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();

    _getArguments();
    _startTimer();
  }

  void _getArguments() {
    final dynamic arguments =
        Get.arguments;

    if (arguments is Map) {
      phoneNumber.value =
          arguments['phone_number']
                  ?.toString()
                  .trim() ??
              '';
    }
  }

  Future<void> verifyOtp() async {
    if (isLoading.value) {
      return;
    }

    final bool isValid =
        formKey.currentState?.validate() ??
            false;

    if (!isValid) {
      return;
    }

    if (phoneNumber.value.isEmpty) {
      Get.snackbar(
        'មានបញ្ហា',
        'រកមិនឃើញលេខទូរស័ព្ទ',
        snackPosition:
            SnackPosition.BOTTOM,
      );

      return;
    }

    try {
      isLoading.value = true;

      final dynamic response =
          await authApi.verifyOtp(
        phoneNumber:
            phoneNumber.value,
        otpCode:
            otpController.text.trim(),
      );

      if (response is! Map) {
        throw Exception(
          'Verify OTP response មិនត្រឹមត្រូវ',
        );
      }

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

      final String nextStep =
          response['next_step']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      await box.write(
        'kyc_token',
        kycToken,
      );

      await box.write(
        'kyc_phone_number',
        phoneNumber.value,
      );

      await box.write(
        'kyc_status',
        response['kyc_status']
                ?.toString() ??
            'not_submitted',
      );

      Get.snackbar(
        'ជោគជ័យ',
        response['message']
                ?.toString() ??
            'ផ្ទៀងផ្ទាត់ OTP ជោគជ័យ',
        snackPosition:
            SnackPosition.BOTTOM,
      );

      switch (nextStep) {
        case 'scan_nid_front':
        case 'kyc':
        case '':
          Get.offAllNamed(
            AppRoutes.kycDocument,
            arguments: {
              'phone_number':
                  phoneNumber.value,
            },
          );
          break;

        default:
          Get.offAllNamed(
            AppRoutes.kycDocument,
            arguments: {
              'phone_number':
                  phoneNumber.value,
            },
          );
      }
    } catch (error) {
      Get.snackbar(
        'Verify OTP បរាជ័យ',
        _cleanError(error),
        snackPosition:
            SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (secondsRemaining.value > 0 ||
        isResending.value) {
      return;
    }

    if (phoneNumber.value.isEmpty) {
      Get.snackbar(
        'មានបញ្ហា',
        'រកមិនឃើញលេខទូរស័ព្ទ',
        snackPosition:
            SnackPosition.BOTTOM,
      );

      return;
    }

    try {
      isResending.value = true;

      final dynamic response =
          await authApi.resendOtp(
        phoneNumber:
            phoneNumber.value,
      );

      otpController.clear();

      int resendAfter = 60;

      if (response is Map) {
        resendAfter =
            int.tryParse(
              response['resend_after']
                      ?.toString() ??
                  '',
            ) ??
                60;
      }

      _startTimer(
        seconds: resendAfter,
      );

      Get.snackbar(
        'ជោគជ័យ',
        response is Map &&
                response['message'] != null
            ? response['message']
                .toString()
            : 'OTP ត្រូវបានផ្ញើម្ដងទៀត',
        snackPosition:
            SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'ផ្ញើ OTP បរាជ័យ',
        _cleanError(error),
        snackPosition:
            SnackPosition.BOTTOM,
      );
    } finally {
      isResending.value = false;
    }
  }

  void _startTimer({
    int seconds = 60,
  }) {
    _timer?.cancel();

    secondsRemaining.value =
        seconds;

    _timer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (Timer timer) {
        if (secondsRemaining.value <=
            0) {
          timer.cancel();
          return;
        }

        secondsRemaining.value--;
      },
    );
  }

  String? validateOtp(
    String? value,
  ) {
    final String otp =
        value?.trim() ?? '';

    if (otp.isEmpty) {
      return 'សូមបញ្ចូលលេខកូដ OTP';
    }

    if (!RegExp(
      r'^[0-9]{6}$',
    ).hasMatch(otp)) {
      return 'OTP ត្រូវមានតែលេខ 6 ខ្ទង់';
    }

    return null;
  }

  String get maskedPhoneNumber {
    final String phone =
        phoneNumber.value.trim();

    if (phone.isEmpty) {
      return '';
    }

    if (phone.length <= 6) {
      return phone;
    }

    final String firstThree =
        phone.substring(
      0,
      3,
    );

    final String lastThree =
        phone.substring(
      phone.length - 3,
    );

    return '$firstThree****$lastThree';
  }

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

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();

    super.onClose();
  }
}
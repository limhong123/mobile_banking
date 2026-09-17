import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/core/api/auth/auth_api.dart';

class RegisterViewController
    extends GetxController {
  final AuthApi authApi = AuthApi();

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final TextEditingController firstNameController =
      TextEditingController();

  final TextEditingController lastNameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController pinController =
      TextEditingController();

  final isLoading = false.obs;
  final isPinHidden = true.obs;

  Future<void> register() async {
    if (isLoading.value) {
      return;
    }

    final bool isValid =
        formKey.currentState?.validate() ??
            false;

    if (!isValid) {
      return;
    }

    try {
      isLoading.value = true;

      final String phone =
          phoneController.text.trim();

      final dynamic response =
          await authApi.register(
        firstName:
            firstNameController.text.trim(),
        lastName:
            lastNameController.text.trim(),
        phoneNumber: phone,
        pin:
            pinController.text.trim(),
      );

      if (response is! Map) {
        throw Exception(
          'Register response មិនត្រឹមត្រូវ',
        );
      }

      final bool otpSent =
          response['otp_sent'] == true;

      final String message =
          response['message']
                  ?.toString() ??
              'បង្កើតគណនីបានជោគជ័យ';

      if (!otpSent) {
        Get.snackbar(
          'បង្កើតគណនីបានជោគជ័យ',
          '$message សូមផ្ញើ OTP ម្តងទៀត',
          snackPosition:
              SnackPosition.BOTTOM,
        );
      }

      Get.offNamed(
        AppRoutes.verifyOtp,
        arguments: {
          'phone_number': phone,
        },
      );
    } catch (error) {
      Get.snackbar(
        'Register បរាជ័យ',
        _cleanError(error),
        snackPosition:
            SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void togglePinVisibility() {
    isPinHidden.value =
        !isPinHidden.value;
  }

  String? validateRequired(
    String? value,
    String field,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'សូមបញ្ចូល $field';
    }

    return null;
  }

  String? validatePhone(
    String? value,
  ) {
    final String phone =
        value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'សូមបញ្ចូលលេខទូរស័ព្ទ';
    }

    if (phone.length < 8) {
      return 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ';
    }

    return null;
  }

  String? validatePin(
    String? value,
  ) {
    final String pin =
        value?.trim() ?? '';

    if (pin.isEmpty) {
      return 'សូមបញ្ចូល PIN';
    }

    if (!RegExp(
      r'^[0-9]{6}$',
    ).hasMatch(pin)) {
      return 'PIN ត្រូវមានតែលេខ 6 ខ្ទង់';
    }

    return null;
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
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    pinController.dispose();

    super.onClose();
  }
}
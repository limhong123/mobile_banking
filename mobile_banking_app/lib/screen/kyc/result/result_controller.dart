import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/core/api/config.dart';


class ResultController
    extends GetxController {
  final GetStorage box =
      GetStorage();

  final Config config =
      Config.instance;


  final status =
      'rejected'.obs;


  final phoneNumber =
      ''.obs;


  final matchScore =
      0.0.obs;


  @override
  void onInit() {
    super.onInit();

    _loadArguments();
  }


  void _loadArguments() {
    final dynamic arguments =
        Get.arguments;


    if (arguments is Map) {
      status.value =
          arguments['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              'rejected';


      phoneNumber.value =
          arguments['phone_number']
                  ?.toString()
                  .trim() ??
              '';


      matchScore.value =
          double.tryParse(
                arguments[
                            'match_score']
                        ?.toString() ??
                    '0',
              ) ??
              0;
    }


    if (
        phoneNumber
            .value
            .isEmpty) {
      phoneNumber.value =
          box
                  .read(
                    'kyc_phone_number',
                  )
                  ?.toString()
                  .trim() ??
              '';
    }
  }


  bool get isApproved =>
      status.value ==
      'approved';


  bool get isRejected =>
      status.value ==
      'rejected';


  String get title {
    if (isApproved) {
      return (
        'ការផ្ទៀងផ្ទាត់ជោគជ័យ'
      );
    }

    return (
      'ការផ្ទៀងផ្ទាត់មិនជោគជ័យ'
    );
  }


  String get description {
    if (isApproved) {
      return (
        'NID និងមុខរបស់អ្នកត្រូវបានផ្ទៀងផ្ទាត់ជោគជ័យ។ អ្នកអាច Login ចូល KhmerPay បាន។'
      );
    }

    return (
      'មុខរបស់អ្នកមិនត្រូវគ្នាជាមួយ NID។ សូមថត NID និងផ្ទៀងផ្ទាត់មុខម្តងទៀត។'
    );
  }


  // =====================================================
  // LOGIN
  // =====================================================

  Future<void> goToLogin() async {
    await box.remove(
      'kyc_token',
    );


    await config.removeToken();


    Get.offAllNamed(
      AppRoutes.login,

      arguments: {
        'phone_number':
            phoneNumber.value,
      },
    );
  }


  // =====================================================
  // RETRY KYC
  // =====================================================

  void retryVerification() {
    Get.offAllNamed(
      AppRoutes.kycDocument,

      arguments: {
        'phone_number':
            phoneNumber.value,
      },
    );
  }
}
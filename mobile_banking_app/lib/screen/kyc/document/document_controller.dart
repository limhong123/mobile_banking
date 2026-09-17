import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/core/api/kyc/kyc_api.dart';


class DocumentController extends GetxController {
  final KycApi kycApi =
      KycApi();

  final ImagePicker imagePicker =
      ImagePicker();

  final GetStorage box =
      GetStorage();

  final frontImagePath =
      ''.obs;

  final isLoading =
      false.obs;


  String get currentImagePath =>
      frontImagePath.value;


  // =====================================================
  // CAMERA
  // =====================================================

  Future<void> captureDocument() async {
    if (isLoading.value) {
      return;
    }

    try {
      final XFile? image =
          await imagePicker.pickImage(
        source:
            ImageSource.camera,

        preferredCameraDevice:
            CameraDevice.rear,

        imageQuality:
            90,

        maxWidth:
            2000,

        maxHeight:
            1400,
      );

      if (image == null) {
        return;
      }

      _printImageInfo(
        image,
        source: 'CAMERA',
      );

      frontImagePath.value =
          image.path;

    } catch (error) {
      Get.snackbar(
        'Camera error',
        _cleanError(
          error,
        ),
        snackPosition:
            SnackPosition.BOTTOM,
      );
    }
  }


  // =====================================================
  // GALLERY
  // =====================================================

  Future<void> selectFromGallery() async {
    if (isLoading.value) {
      return;
    }

    try {
      final XFile? image =
          await imagePicker.pickImage(
        source:
            ImageSource.gallery,

        imageQuality:
            90,

        maxWidth:
            2000,

        maxHeight:
            1400,
      );

      if (image == null) {
        return;
      }

      _printImageInfo(
        image,
        source: 'GALLERY',
      );

      frontImagePath.value =
          image.path;

    } catch (error) {
      Get.snackbar(
        'Gallery error',
        _cleanError(
          error,
        ),
        snackPosition:
            SnackPosition.BOTTOM,
      );
    }
  }


  // =====================================================
  // UPLOAD NID FRONT
  // =====================================================

  Future<void> uploadDocument() async {
    if (isLoading.value) {
      return;
    }

    final String path =
        frontImagePath.value
            .trim();

    if (path.isEmpty) {
      Get.snackbar(
        'មិនទាន់មានរូបភាព',
        'សូមថត NID ខាងមុខ',
        snackPosition:
            SnackPosition.BOTTOM,
      );

      return;
    }


    final String kycToken =
        box
                .read(
                  'kyc_token',
                )
                ?.toString()
                .trim() ??
            '';


    if (kycToken.isEmpty) {
      Get.snackbar(
        'KYC session ផុតកំណត់',
        'សូម Login ឬ Verify OTP ម្តងទៀត',
        snackPosition:
            SnackPosition.BOTTOM,
      );

      return;
    }


    try {
      isLoading.value =
          true;


      final Map<String, dynamic>
          response =
          await kycApi.uploadNidFront(
        filePath:
            path,

        kycToken:
            kycToken,
      );


      if (kDebugMode) {
        debugPrint(
          'NID FRONT RESPONSE: '
          '$response',
        );
      }


      final bool success =
          response['success'] ==
              true;


      final String nextStep =
          response['next_step']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';


      final String status =
          response['kyc_status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';


      if (
          success &&
          (
            nextStep ==
                'face_scan' ||
            status ==
                'nid_uploaded'
          )
      ) {
        Get.offNamed(
          AppRoutes.kycLiveness,
        );

        return;
      }


      throw Exception(
        response['message']
                ?.toString() ??
            'Unable to process NID',
      );

    } catch (error) {
      final String message =
          _cleanError(
        error,
      );

      Get.snackbar(
        'NID មិនជោគជ័យ',
        message,
        snackPosition:
            SnackPosition.BOTTOM,
        duration:
            const Duration(
          seconds: 5,
        ),
      );

    } finally {
      isLoading.value =
          false;
    }
  }


  // =====================================================
  // RETAKE
  // =====================================================

  void retake() {
    frontImagePath.value =
        '';
  }


  // =====================================================
  // DEBUG
  // =====================================================

  void _printImageInfo(
    XFile image, {
    required String source,
  }) {
    if (!kDebugMode) {
      return;
    }

    debugPrint(
      '========== NID IMAGE ==========',
    );

    debugPrint(
      'SOURCE: $source',
    );

    debugPrint(
      'PATH: ${image.path}',
    );

    debugPrint(
      'NAME: ${image.name}',
    );

    debugPrint(
      'MIME TYPE: ${image.mimeType}',
    );

    debugPrint(
      '===============================',
    );
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
}
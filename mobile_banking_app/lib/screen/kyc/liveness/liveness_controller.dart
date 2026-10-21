import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/core/api/kyc/kyc_api.dart';


enum LivenessStep {
  positionFace,
  blink,
  turnLeft,
  turnRight,
  completed,
}


class LivenessController
    extends GetxController {
  final KycApi kycApi =
      KycApi();

  final GetStorage box =
      GetStorage();


  final Rxn<CameraController>
      cameraController =
      Rxn<CameraController>();


  final isCameraReady =
      false.obs;

  final isProcessing =
      false.obs;

  final isUploading =
      false.obs;

  final errorMessage =
      ''.obs;


  final currentStep =
      LivenessStep
          .positionFace
          .obs;


  final progress =
      0.0.obs;


  late final FaceDetector
      faceDetector;


  bool _blinkStarted =
      false;

  bool _leftCompleted =
      false;

  bool _captured =
      false;


  DateTime _lastProcessed =
      DateTime.fromMillisecondsSinceEpoch(
    0,
  );


  // =====================================================
  // INIT
  // =====================================================

  @override
  void onInit() {
    super.onInit();

    faceDetector =
        FaceDetector(
      options:
          FaceDetectorOptions(
        enableClassification:
            true,

        enableTracking:
            true,

        performanceMode:
            FaceDetectorMode.fast,
      ),
    );

    initializeCamera();
  }


  // =====================================================
  // CAMERA
  // =====================================================

  Future<void> initializeCamera() async {
    try {
      errorMessage.value =
          '';

      final PermissionStatus
          permission =
          await Permission.camera
              .request();


      if (!permission.isGranted) {
        errorMessage.value =
            'សូមអនុញ្ញាត Camera ដើម្បីបន្ត';

        return;
      }


      final List<CameraDescription>
          cameras =
          await availableCameras();


      if (cameras.isEmpty) {
        errorMessage.value =
            'រកមិនឃើញ Camera';

        return;
      }


      final CameraDescription
          frontCamera =
          cameras.firstWhere(
        (
          CameraDescription camera,
        ) =>
            camera.lensDirection ==
            CameraLensDirection.front,

        orElse:
            () => cameras.first,
      );


      final CameraController
          controller =
          CameraController(
        frontCamera,

        ResolutionPreset.high,

        enableAudio:
            false,

        imageFormatGroup:
            Platform.isAndroid
                ? ImageFormatGroup.nv21
                : ImageFormatGroup
                    .bgra8888,
      );


      cameraController.value =
          controller;


      await controller.initialize();


      isCameraReady.value =
          true;


      await controller
          .startImageStream(
        _processCameraImage,
      );

    } catch (error) {
      errorMessage.value =
          _cleanError(
        error,
      );

      if (kDebugMode) {
        debugPrint(
          'CAMERA INIT ERROR: '
          '$error',
        );
      }
    }
  }


  // =====================================================
  // PROCESS CAMERA
  // =====================================================

  Future<void> _processCameraImage(
    CameraImage image,
  ) async {
    if (
        isProcessing.value ||
        isUploading.value ||
        _captured) {
      return;
    }


    final DateTime now =
        DateTime.now();


    if (
        now.difference(
          _lastProcessed,
        ) <
        const Duration(
          milliseconds: 250,
        )) {
      return;
    }


    _lastProcessed =
        now;


    isProcessing.value =
        true;


    try {
      final CameraController?
          controller =
          cameraController.value;


      if (controller == null) {
        return;
      }


      final InputImage?
          inputImage =
          _convertCameraImage(
        image,
        controller.description,
      );


      if (inputImage == null) {
        return;
      }


      final List<Face> faces =
          await faceDetector
              .processImage(
        inputImage,
      );


      if (faces.length != 1) {
        currentStep.value =
            LivenessStep
                .positionFace;

        progress.value =
            0;

        _blinkStarted =
            false;

        _leftCompleted =
            false;

        return;
      }


      _evaluateFace(
        faces.first,
      );

    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'FACE DETECTION ERROR: '
          '$error',
        );
      }

    } finally {
      isProcessing.value =
          false;
    }
  }


  // =====================================================
  // LIVENESS LOGIC
  // =====================================================

  void _evaluateFace(
    Face face,
  ) {
    final double leftEye =
        face
                .leftEyeOpenProbability ??
            1.0;


    final double rightEye =
        face
                .rightEyeOpenProbability ??
            1.0;


    final double headY =
        face.headEulerAngleY ??
            0.0;


    switch (
        currentStep.value) {
      case LivenessStep
          .positionFace:

        currentStep.value =
            LivenessStep.blink;

        progress.value =
            0.20;

        break;


      case LivenessStep.blink:

        final bool eyesClosed =
            leftEye < 0.25 &&
            rightEye < 0.25;


        final bool eyesOpen =
            leftEye > 0.65 &&
            rightEye > 0.65;


        if (eyesClosed) {
          _blinkStarted =
              true;
        }


        if (
            _blinkStarted &&
            eyesOpen) {
          currentStep.value =
              LivenessStep
                  .turnLeft;

          progress.value =
              0.45;
        }

        break;


      case LivenessStep
          .turnLeft:

        if (headY < -20) {
          _leftCompleted =
              true;

          currentStep.value =
              LivenessStep
                  .turnRight;

          progress.value =
              0.70;
        }

        break;


      case LivenessStep
          .turnRight:

        if (
            _leftCompleted &&
            headY > 20) {
          currentStep.value =
              LivenessStep
                  .completed;

          progress.value =
              1.0;

          captureAndUpload();
        }

        break;


      case LivenessStep
          .completed:

        break;
    }
  }


  // =====================================================
  // CAMERA IMAGE CONVERSION
  // =====================================================

  InputImage? _convertCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final InputImageRotation
        rotation =
        InputImageRotationValue
                .fromRawValue(
              camera
                  .sensorOrientation,
            ) ??
            InputImageRotation
                .rotation0deg;


    final InputImageFormat?
        format =
        InputImageFormatValue
            .fromRawValue(
      image.format.raw,
    );


    if (
        format == null ||
        image.planes.isEmpty) {
      return null;
    }


    final Plane plane =
        image.planes.first;


    return InputImage.fromBytes(
      bytes:
          plane.bytes,

      metadata:
          InputImageMetadata(
        size:
            Size(
          image.width
              .toDouble(),

          image.height
              .toDouble(),
        ),

        rotation:
            rotation,

        format:
            format,

        bytesPerRow:
            plane.bytesPerRow,
      ),
    );
  }


  // =====================================================
  // CAPTURE + FACE MATCH
  // =====================================================

  Future<void> captureAndUpload() async {
    if (
        _captured ||
        isUploading.value) {
      return;
    }


    _captured =
        true;


    final CameraController?
        controller =
        cameraController.value;


    if (
        controller == null ||
        !controller
            .value
            .isInitialized) {
      _captured =
          false;

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
      _captured =
          false;

      Get.snackbar(
        'KYC session ផុតកំណត់',
        'សូម Login ហើយចាប់ផ្តើម KYC ម្តងទៀត',
        snackPosition:
            SnackPosition.BOTTOM,
      );

      return;
    }


    try {
      isUploading.value =
          true;


      if (
          controller
              .value
              .isStreamingImages) {
        await controller
            .stopImageStream();
      }


      final XFile image =
          await controller
              .takePicture();


      if (kDebugMode) {
        debugPrint(
          'SELFIE PATH: '
          '${image.path}',
        );
      }


      final Map<String, dynamic>
          response =
          await kycApi.uploadFace(
        imagePath:
            image.path,

        kycToken:
            kycToken,
      );


      if (kDebugMode) {
        debugPrint(
          'FACE RESPONSE: '
          '$response',
        );
      }


      final bool faceVerified =
          response[
                  'face_verified'] ==
              true;


      final String status =
          response[
                      'kyc_status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';


      final String nextStep =
          response[
                      'next_step']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';


      final dynamic faceMatch =
          response[
              'face_match'];


      double matchScore =
          0;


      if (faceMatch is Map) {
        matchScore =
            double.tryParse(
                  faceMatch[
                              'match_score']
                          ?.toString() ??
                      '0',
                ) ??
                0;
      }


      // =================================================
      // APPROVED
      // =================================================

      if (
          faceVerified &&
          status ==
              'approved' &&
          nextStep ==
              'result') {
        Get.offAllNamed(
          AppRoutes.kycResult,

          arguments: {
            'status':
                'approved',

            'phone_number':
                box.read(
              'kyc_phone_number',
            ),

            'match_score':
                matchScore,

            'nid_data':
                response['nid_data'],
          },
        );

        return;
      }


      // =================================================
      // REJECTED
      // =================================================

      if (
          !faceVerified &&
          status ==
              'rejected' &&
          nextStep ==
              'result') {
        Get.offAllNamed(
          AppRoutes.kycResult,

          arguments: {
            'status':
                'rejected',

            'phone_number':
                box.read(
              'kyc_phone_number',
            ),

            'match_score':
                matchScore,
          },
        );

        return;
      }


      throw Exception(
        response['message']
                ?.toString() ??
            'Face verification failed',
      );

    } catch (error) {
      _captured =
          false;


      final String message =
          _cleanError(
        error,
      );


      if (kDebugMode) {
        debugPrint(
          'FACE ERROR: '
          '$message',
        );
      }


      if (
          _needsNewNid(
            message,
          )) {
        Get.snackbar(
          'ត្រូវថត NID ម្តងទៀត',

          'មិនអាចរកមុខពី NID បាន។ សូមថត NID ខាងមុខឱ្យច្បាស់។',

          snackPosition:
              SnackPosition.BOTTOM,

          duration:
              const Duration(
            seconds: 5,
          ),
        );


        Get.offAllNamed(
          AppRoutes.kycDocument,
        );

        return;
      }


      Get.snackbar(
        'Face verification បរាជ័យ',

        message,

        snackPosition:
            SnackPosition.BOTTOM,

        duration:
            const Duration(
          seconds: 5,
        ),
      );


      await resetLiveness();

    } finally {
      isUploading.value =
          false;
    }
  }


  // =====================================================
  // NID ERROR
  // =====================================================

  bool _needsNewNid(
    String message,
  ) {
    final String value =
        message.toLowerCase();


    return value.contains(
          'nid face is not available',
        ) ||
        value.contains(
          'nid face file does not exist',
        ) ||
        value.contains(
          'capture nid again',
        ) ||
        value.contains(
          'please upload nid first',
        );
  }


  // =====================================================
  // RESET
  // =====================================================

  Future<void> resetLiveness() async {
    _blinkStarted =
        false;

    _leftCompleted =
        false;

    _captured =
        false;


    currentStep.value =
        LivenessStep
            .positionFace;


    progress.value =
        0;


    final CameraController?
        controller =
        cameraController.value;


    if (
        controller == null ||
        !controller
            .value
            .isInitialized) {
      return;
    }


    if (
        !controller
            .value
            .isStreamingImages) {
      try {
        await controller
            .startImageStream(
          _processCameraImage,
        );

      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            'RESTART CAMERA ERROR: '
            '$error',
          );
        }
      }
    }
  }


  // =====================================================
  // INSTRUCTION
  // =====================================================

  String get instruction {
    switch (
        currentStep.value) {
      case LivenessStep
          .positionFace:
        return (
          'ដាក់មុខរបស់អ្នកនៅកណ្ដាលស៊ុម'
        );

      case LivenessStep.blink:
        return (
          'សូមព្រិចភ្នែកមួយដង'
        );

      case LivenessStep
          .turnLeft:
        return (
          'សូមបង្វិលមុខទៅឆ្វេង'
        );

      case LivenessStep
          .turnRight:
        return (
          'សូមបង្វិលមុខទៅស្ដាំ'
        );

      case LivenessStep
          .completed:
        return (
          'កំពុងផ្ទៀងផ្ទាត់មុខ...'
        );
    }
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


  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void onClose() {
    final CameraController?
        controller =
        cameraController.value;


    if (controller != null) {
      if (
          controller
              .value
              .isStreamingImages) {
        controller
            .stopImageStream();
      }

      controller.dispose();
    }


    faceDetector.close();

    super.onClose();
  }
}
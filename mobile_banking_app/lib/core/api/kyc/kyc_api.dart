import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import 'package:mobile_banking_app/core/api/base_api.dart';


class KycApi {
  final BaseApi baseApi =
      BaseApi();


  // =========================================================
  // UPLOAD NID FRONT
  // =========================================================

  Future<Map<String, dynamic>>
      uploadNidFront({
    required String filePath,
    required String kycToken,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '========== NID FRONT ==========',
      );

      debugPrint(
        'FILE PATH: $filePath',
      );

      debugPrint(
        'TOKEN EXISTS: ${kycToken.isNotEmpty}',
      );

      debugPrint(
        'CONTENT TYPE: ${_getImageMediaType(filePath)}',
      );

      debugPrint(
        '===============================',
      );
    }


    final FormData formData =
        FormData.fromMap({
      'file':
          await MultipartFile.fromFile(
        filePath,

        contentType:
            _getImageMediaType(
          filePath,
        ),
      ),
    });


    final dynamic response =
        await baseApi.post(
      endpoint:
          '/kyc/nid/front',

      data:
          formData,

      options:
          _kycOptions(
        kycToken,
        multipart: true,
      ),
    );


    if (response is! Map) {
      throw Exception(
        'Upload NID response មិនត្រឹមត្រូវ',
      );
    }


    final Map<String, dynamic>
        result =
        Map<String, dynamic>.from(
      response,
    );


    if (kDebugMode) {
      debugPrint(
        'NID FRONT RESPONSE: '
        '$result',
      );
    }


    return result;
  }


  // =========================================================
  // UPLOAD LIVE FACE
  // =========================================================

  Future<Map<String, dynamic>>
      uploadFace({
    required String imagePath,
    required String kycToken,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '========== LIVE FACE ==========',
      );

      debugPrint(
        'FILE PATH: $imagePath',
      );

      debugPrint(
        'TOKEN EXISTS: ${kycToken.isNotEmpty}',
      );

      debugPrint(
        'CONTENT TYPE: ${_getImageMediaType(imagePath)}',
      );

      debugPrint(
        '===============================',
      );
    }


    final FormData formData =
        FormData.fromMap({
      /*
       * Backend:
       *
       * @router.post("/face")
       *
       * selfie: UploadFile = File(...)
       *
       * ដូច្នេះ field name ត្រូវជា:
       *
       * selfie
       */
      'selfie':
          await MultipartFile.fromFile(
        imagePath,

        contentType:
            _getImageMediaType(
          imagePath,
        ),
      ),
    });


    final dynamic response =
        await baseApi.post(
      endpoint:
          '/kyc/face',

      data:
          formData,

      options:
          _kycOptions(
        kycToken,
        multipart: true,
      ),
    );


    if (response is! Map) {
      throw Exception(
        'Face verification response មិនត្រឹមត្រូវ',
      );
    }


    final Map<String, dynamic>
        result =
        Map<String, dynamic>.from(
      response,
    );


    if (kDebugMode) {
      debugPrint(
        'FACE RESPONSE: '
        '$result',
      );
    }


    return result;
  }


  // =========================================================
  // KYC STATUS
  // =========================================================

  Future<Map<String, dynamic>>
      getKycStatus({
    required String kycToken,
  }) async {
    final dynamic response =
        await baseApi.get(
      endpoint:
          '/kyc/status',

      options:
          _kycOptions(
        kycToken,
      ),
    );


    if (response is! Map) {
      throw Exception(
        'KYC status response មិនត្រឹមត្រូវ',
      );
    }


    final Map<String, dynamic>
        result =
        Map<String, dynamic>.from(
      response,
    );


    if (kDebugMode) {
      debugPrint(
        'KYC STATUS RESPONSE: '
        '$result',
      );
    }


    return result;
  }


  // =========================================================
  // AUTHORIZATION OPTIONS
  // =========================================================

  Options _kycOptions(
    String kycToken, {
    bool multipart = false,
  }) {
    final String token =
        kycToken.trim();


    if (token.isEmpty) {
      throw Exception(
        'KYC token is missing',
      );
    }


    return Options(
      headers: {
        'Authorization':
            'Bearer $token',
      },

      /*
       * Dio បង្កើត multipart boundary
       * ដោយស្វ័យប្រវត្តិ។
       */
      contentType:
          multipart
              ? Headers
                  .multipartFormDataContentType
              : Headers
                  .jsonContentType,
    );
  }


  // =========================================================
  // IMAGE MIME TYPE
  // =========================================================

  MediaType _getImageMediaType(
    String filePath,
  ) {
    final String path =
        filePath
            .trim()
            .toLowerCase();


    if (
        path.endsWith(
          '.png',
        )) {
      return MediaType(
        'image',
        'png',
      );
    }


    if (
        path.endsWith(
          '.jpg',
        ) ||
        path.endsWith(
          '.jpeg',
        )) {
      return MediaType(
        'image',
        'jpeg',
      );
    }


    /*
     * Camera / image_picker នៅ Android
     * ភាគច្រើនជា JPEG។
     */
    return MediaType(
      'image',
      'jpeg',
    );
  }
}
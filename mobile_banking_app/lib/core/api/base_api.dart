import 'package:dio/dio.dart';
import 'package:mobile_banking_app/core/api/config.dart';

class BaseApi {
  final Dio dio =
      Config.instance.dio;

  Future<dynamic> get({
    required String endpoint,
    Map<String, dynamic>?
        queryParameters,
    Options? options,
  }) async {
    try {
      final Response<dynamic> response =
          await dio.get(
        endpoint,
        queryParameters:
            queryParameters,
        options: options,
      );

      return _handleResponse(
        response,
      );
    } on DioException catch (error) {
      throw _handleDioError(
        error,
      );
    }
  }

  Future<dynamic> post({
    required String endpoint,
    dynamic data,
    Map<String, dynamic>?
        queryParameters,
    Options? options,
  }) async {
    try {
      final Response<dynamic> response =
          await dio.post(
        endpoint,
        data: data,
        queryParameters:
            queryParameters,
        options: options,
      );

      return _handleResponse(
        response,
      );
    } on DioException catch (error) {
      throw _handleDioError(
        error,
      );
    }
  }

  dynamic _handleResponse(
    Response<dynamic> response,
  ) {
    final int statusCode =
        response.statusCode ?? 500;

    if (statusCode >= 200 &&
        statusCode < 300) {
      return response.data;
    }

    throw Exception(
      _extractErrorMessage(
        response.data,
      ),
    );
  }

  Exception _handleDioError(
    DioException error,
  ) {
    switch (error.type) {
      case DioExceptionType
            .connectionTimeout:
        return Exception(
          'ការតភ្ជាប់យូរពេក',
        );

      case DioExceptionType
            .sendTimeout:
        return Exception(
          'ការផ្ញើទិន្នន័យយូរពេក',
        );

      case DioExceptionType
            .receiveTimeout:
        return Exception(
          'ការទទួលទិន្នន័យយូរពេក',
        );

      case DioExceptionType
            .connectionError:
        return Exception(
          'មិនអាចភ្ជាប់ទៅ Server បាន',
        );

      case DioExceptionType
            .badResponse:
        return Exception(
          _extractErrorMessage(
            error.response?.data,
          ),
        );

      case DioExceptionType.cancel:
        return Exception(
          'Request ត្រូវបានបោះបង់',
        );

      case DioExceptionType
            .badCertificate:
        return Exception(
          'Certificate មិនត្រឹមត្រូវ',
        );

      case DioExceptionType
            .transformTimeout:
        return Exception(
          'ការបម្លែងទិន្នន័យយូរពេក',
        );

      case DioExceptionType.unknown:
        return Exception(
          error.message ??
              'មានបញ្ហាមិនស្គាល់',
        );
    }
  }

  String _extractErrorMessage(
    dynamic data,
  ) {
    if (data == null) {
      return 'Server error';
    }

    if (data is Map) {
      final dynamic detail =
          data['detail'] ??
          data['message'] ??
          data['error'];

      if (detail is List) {
        return detail
            .map(
              (dynamic item) {
                if (item is Map) {
                  return item['msg']
                          ?.toString() ??
                      item.toString();
                }

                return item.toString();
              },
            )
            .join('\n');
      }

      return detail?.toString() ??
          'Server error';
    }

    return data.toString();
  }
}
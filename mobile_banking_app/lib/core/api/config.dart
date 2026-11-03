import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class Config {
  Config._() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final String? token = box.read<String>('token');

          final bool alreadyHasAuthorization = options.headers.containsKey(
            'Authorization',
          );

          if (!alreadyHasAuthorization &&
              token != null &&
              token.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${token.trim()}';
          }

          if (kDebugMode) {
            debugPrint('REQUEST: ${options.method} ${options.uri}');

            debugPrint('HEADERS: ${options.headers}');

            debugPrint('DATA: ${options.data}');
          }

          handler.next(options);
        },

        onResponse:
            (Response<dynamic> response, ResponseInterceptorHandler handler) {
              if (kDebugMode) {
                debugPrint('STATUS: ${response.statusCode}');

                debugPrint('RESPONSE: ${response.data}');
              }

              handler.next(response);
            },

        onError: (DioException error, ErrorInterceptorHandler handler) {
          if (kDebugMode) {
            debugPrint('DIO STATUS: ${error.response?.statusCode}');

            debugPrint('DIO ERROR: ${error.response?.data}');

            debugPrint('DIO MESSAGE: ${error.message}');

            debugPrint('DIO TYPE: ${error.type}');

            debugPrint('REQUEST URL: ${error.requestOptions.uri}');
          }

          handler.next(error);
        },
      ),
    );
  }

  static final Config instance = Config._();

  final GetStorage box = GetStorage();

  static const String computerIp = '172.26.176.1';

  String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    if (Platform.isAndroid) {
      return 'http://$computerIp:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  Future<void> saveToken(String token) async {
    await box.write('token', token.trim());
  }

  String? getToken() {
    return box.read<String>('token');
  }

  Future<void> removeToken() async {
    await box.remove('token');
  }

  bool get hasToken {
    final String? token = getToken();

    return token != null && token.trim().isNotEmpty;
  }
}

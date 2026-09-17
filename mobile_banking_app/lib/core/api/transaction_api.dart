import 'package:flutter/foundation.dart';
import 'package:mobile_banking_app/core/api/base_api.dart';

class TransactionApi {
  final BaseApi baseApi = BaseApi();

  // =====================================================
  // ANALYTICS
  // =====================================================

  Future<Map<String, dynamic>> getAnalytics({
    required String filter,
  }) async {
    final dynamic response =
        await baseApi.get(
      endpoint: '/transactions/analytics',
      queryParameters: {
        'filter': filter,
      },
    );

    if (response is! Map) {
      throw Exception(
        'Analytics response invalid',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }

  // =====================================================
  // HISTORY
  // =====================================================

  Future<Map<String, dynamic>> getHistory() async {
    final dynamic response =
        await baseApi.get(
      endpoint: '/transactions/history',
    );

    debugPrint(
      'TRANSACTION HISTORY RESPONSE: $response',
    );

    if (response is! Map) {
      throw Exception(
        'Transaction history response invalid',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }

  // =====================================================
  // DETAIL
  // =====================================================

  Future<Map<String, dynamic>> getDetail({
    required String transactionId,
  }) async {
    if (transactionId.trim().isEmpty) {
      throw Exception(
        'Transaction ID is empty',
      );
    }

    debugPrint(
      'DETAIL TRANSACTION ID: $transactionId',
    );

    final dynamic response =
        await baseApi.get(
      endpoint:
          '/transactions/$transactionId',
    );

    debugPrint(
      'DETAIL RESPONSE: $response',
    );

    if (response is! Map) {
      throw Exception(
        'Transaction detail response invalid',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }
}
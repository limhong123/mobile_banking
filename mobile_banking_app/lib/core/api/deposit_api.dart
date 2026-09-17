import 'package:mobile_banking_app/core/api/base_api.dart';

class DepositApi {
  final BaseApi baseApi =
      BaseApi();

  // =====================================================
  // GET BALANCE
  // =====================================================

  Future<Map<String, dynamic>>
      getBalance() async {
    final dynamic response =
        await baseApi.get(
      endpoint:
          '/deposits/balance',
    );

    if (response is! Map) {
      throw Exception(
        'Balance response មិនត្រឹមត្រូវ',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }

  // =====================================================
  // HISTORY
  // =====================================================

  Future<Map<String, dynamic>>
      getHistory() async {
    final dynamic response =
        await baseApi.get(
      endpoint:
          '/deposits/history',
    );

    if (response is! Map) {
      throw Exception(
        'History response មិនត្រឹមត្រូវ',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }

  // =====================================================
  // DETAIL
  // =====================================================

  Future<Map<String, dynamic>>
      getDetail(
    String transactionId,
  ) async {
    final dynamic response =
        await baseApi.get(
      endpoint:
          '/deposits/history/$transactionId',
    );

    if (response is! Map) {
      throw Exception(
        'Transaction detail response មិនត្រឹមត្រូវ',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }
}
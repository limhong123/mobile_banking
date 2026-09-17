import 'package:mobile_banking_app/core/api/base_api.dart';


class CashTransferApi {
  final BaseApi baseApi =
      BaseApi();


  // =====================================================
  // CHECK CODE
  // =====================================================

  Future<Map<String, dynamic>>
      checkCode({
    required String code,
  }) async {
    final dynamic response =
        await baseApi.post(
      endpoint:
          '/cash-transfers/account/check',

      data: {
        'code':
            code.trim(),
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }


  // =====================================================
  // RECEIVE TO ACCOUNT
  // =====================================================

  Future<Map<String, dynamic>>
      claimToAccount({
    required String code,
  }) async {
    final dynamic response =
        await baseApi.post(
      endpoint:
          '/cash-transfers/account/claim',

      data: {
        'code':
            code.trim(),
      },
    );

    if (response is! Map) {
      throw Exception(
        'Invalid response',
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
          '/cash-transfers/my-history',
    );

    if (response is! Map) {
      throw Exception(
        'Invalid history response',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }
}
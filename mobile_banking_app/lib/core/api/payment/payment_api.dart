import 'package:mobile_banking_app/core/api/base_api.dart';


class PaymentApi {
  final BaseApi baseApi =
      BaseApi();


  // =====================================================
  // MY ACCOUNT
  // =====================================================

  Future<Map<String, dynamic>>
      getMyAccount() async {
    final dynamic response =
        await baseApi.get(
      endpoint:
          '/accounts/me',
    );

    if (response is! Map) {
      throw Exception(
        'Account response invalid',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }


  // =====================================================
  // MY QR
  // =====================================================

  Future<Map<String, dynamic>>
      getMyQr() async {
    final dynamic response =
        await baseApi.get(
      endpoint:
          '/accounts/my-qr',
    );

    if (response is! Map) {
      throw Exception(
        'QR response invalid',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }


  // =====================================================
  // RESOLVE ACCOUNT NUMBER
  // =====================================================

  Future<Map<String, dynamic>>
      resolveAccount({
    required String accountNumber,
  }) async {
    final dynamic response =
        await baseApi.post(
      endpoint:
          '/transfers/resolve-account',

      data: {
        'account_number':
            accountNumber.trim(),
      },
    );

    if (response is! Map) {
      throw Exception(
        'Receiver response invalid',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }


  // =====================================================
  // RESOLVE QR
  // =====================================================

  Future<Map<String, dynamic>>
      resolveQr({
    required String qrPayload,
  }) async {
    final dynamic response =
        await baseApi.post(
      endpoint:
          '/transfers/resolve-qr',

      data: {
        'qr_payload':
            qrPayload.trim(),
      },
    );

    if (response is! Map) {
      throw Exception(
        'QR receiver response invalid',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }


  // =====================================================
  // TRANSFER BY ACCOUNT
  // =====================================================

  Future<Map<String, dynamic>>
      transferByAccount({
    required String accountNumber,
    required double amount,
    String description = '',
  }) async {
    final dynamic response =
        await baseApi.post(
      endpoint:
          '/transfers',

      data: {
        'receiver_account_number':
            accountNumber.trim(),

        'amount':
            amount,

        'description':
            description,
      },
    );

    if (response is! Map) {
      throw Exception(
        'Transfer response invalid',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }


  // =====================================================
  // TRANSFER BY QR
  // =====================================================

  Future<Map<String, dynamic>>
      transferByQr({
    required String receiverQrId,
    required double amount,
    String description = '',
  }) async {
    final dynamic response =
        await baseApi.post(
      endpoint:
          '/transfers',

      data: {
        'receiver_qr_id':
            receiverQrId.trim(),

        'amount':
            amount,

        'description':
            description,
      },
    );

    if (response is! Map) {
      throw Exception(
        'Transfer response invalid',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }

  Future<Map<String, dynamic>>
    getTransactions() async {
  final dynamic response =
      await baseApi.get(
    endpoint:
        '/transfers/history',
  );

  if (response is! Map) {
    throw Exception(
      'Transaction history response invalid',
    );
  }

  return Map<String, dynamic>.from(
    response,
  );
}}
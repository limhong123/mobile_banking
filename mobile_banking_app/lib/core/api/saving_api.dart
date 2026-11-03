import 'package:mobile_banking_app/core/api/base_api.dart';
import 'package:mobile_banking_app/core/model/saving_model.dart';

class SavingApi {
  final BaseApi baseApi = BaseApi();

  /// Fetch all active savings terms configured by the bank admin
  /// GET /savings/terms
  Future<List<SavingTermModel>> getTerms() async {
    final dynamic response = await baseApi.get(
      endpoint: '/savings/terms',
    );

    if (response is! Map || response['data'] is! List) {
      throw Exception('Failed to load savings terms');
    }

    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => SavingTermModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Open savings deposit with term_id and amount
  /// POST /savings/open
  Future<Map<String, dynamic>> openSaving({
    required String termId,
    required double amount,
    String? notes,
  }) async {
    final dynamic response = await baseApi.post(
      endpoint: '/savings/open',
      data: {
        'term_id': termId,
        'amount': amount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    if (response is! Map) {
      throw Exception('Open savings deposit failed');
    }

    return Map<String, dynamic>.from(response);
  }

  /// Fetch savings interest rate settings configured by admin (legacy fallback)
  Future<SavingSettingsModel> getRates() async {
    final dynamic response = await baseApi.get(
      endpoint: '/savings/settings',
    );

    if (response is! Map || response['data'] is! Map) {
      throw Exception('Failed to load savings settings');
    }

    return SavingSettingsModel.fromJson(
      Map<String, dynamic>.from(response['data']),
    );
  }

  /// Fetch customer's savings records & totals
  Future<MySavingsData> getMySavings() async {
    final dynamic response = await baseApi.get(
      endpoint: '/savings/my-savings',
    );

    if (response is! Map || response['data'] is! Map) {
      throw Exception('Failed to load my savings data');
    }

    return MySavingsData.fromJson(
      Map<String, dynamic>.from(response['data']),
    );
  }

  /// Deposit money into savings to earn interest (funds will be locked) - legacy compat
  Future<Map<String, dynamic>> createDeposit({
    required double amount,
    required String durationType,
    required int durationMonths,
    String? notes,
  }) async {
    final dynamic response = await baseApi.post(
      endpoint: '/savings/deposit',
      data: {
        'amount': amount,
        'duration_type': durationType,
        'duration_months': durationMonths,
        'notes': notes ?? '',
      },
    );

    if (response is! Map) {
      throw Exception('Deposit to savings failed');
    }

    return Map<String, dynamic>.from(response);
  }

  /// Withdraw matured savings
  /// Enforces: User cannot withdraw if savings is still active/locked
  Future<Map<String, dynamic>> withdraw({
    required String savingId,
  }) async {
    final dynamic response = await baseApi.post(
      endpoint: '/savings/$savingId/withdraw',
    );

    if (response is! Map) {
      throw Exception('Withdrawal failed');
    }

    return Map<String, dynamic>.from(response);
  }
}

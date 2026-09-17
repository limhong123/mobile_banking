import 'package:get/get.dart';
import 'package:mobile_banking_app/core/api/transaction_api.dart';

class AnalysDateController
    extends GetxController {
  final TransactionApi transactionApi =
      TransactionApi();

  final selectedFilter =
      'day'.obs;

  final income =
      0.0.obs;

  final expense =
      0.0.obs;

  final incomeCount =
      0.obs;

  final expenseCount =
      0.obs;

  final isLoading =
      false.obs;

  final errorMessage =
      ''.obs;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void onInit() {
    super.onInit();

    fetchAnalytics(
      'day',
    );
  }

  // =====================================================
  // CHANGE FILTER
  // =====================================================

  Future<void> changeFilter(
    String filter,
  ) async {
    if (
        selectedFilter.value ==
            filter &&
        !errorMessage.value.isNotEmpty) {
      return;
    }

    selectedFilter.value =
        filter;

    await fetchAnalytics(
      filter,
    );
  }

  // =====================================================
  // FETCH ANALYTICS
  // =====================================================

  Future<void> fetchAnalytics(
    String filter,
  ) async {
    try {
      isLoading.value =
          true;

      errorMessage.value =
          '';

      final response =
          await transactionApi
              .getAnalytics(
        filter:
            filter,
      );

      if (
          response['success'] !=
              true) {
        throw Exception(
          response['message'] ??
              'Unable to load analytics',
        );
      }

      final dynamic rawData =
          response['data'];

      if (rawData is! Map) {
        throw Exception(
          'Analytics data invalid',
        );
      }

      final data =
          Map<String, dynamic>.from(
        rawData,
      );

      income.value =
          _toDouble(
        data['income'],
      );

      expense.value =
          _toDouble(
        data['expense'],
      );

      incomeCount.value =
          _toInt(
        data['income_count'],
      );

      expenseCount.value =
          _toInt(
        data['expense_count'],
      );
    } catch (error) {
      income.value =
          0;

      expense.value =
          0;

      incomeCount.value =
          0;

      expenseCount.value =
          0;

      errorMessage.value =
          error
              .toString()
              .replaceFirst(
                'Exception: ',
                '',
              );
    } finally {
      isLoading.value =
          false;
    }
  }

  // =====================================================
  // REFRESH
  // =====================================================

  Future<void> refreshData() async {
    await fetchAnalytics(
      selectedFilter.value,
    );
  }

  // =====================================================
  // TOTAL
  // =====================================================

  double get total =>
      income.value +
      expense.value;

  // =====================================================
  // INCOME PERCENT
  // =====================================================

  double get incomePercent {
    if (total <= 0) {
      return 0;
    }

    return (
        income.value /
            total *
            100);
  }

  // =====================================================
  // EXPENSE PERCENT
  // =====================================================

  double get expensePercent {
    if (total <= 0) {
      return 0;
    }

    return (
        expense.value /
            total *
            100);
  }

  // =====================================================
  // NUMBER TO DOUBLE
  // =====================================================

  double _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // =====================================================
  // NUMBER TO INT
  // =====================================================

  int _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }
}
import 'package:get/get.dart';

import 'package:mobile_banking_app/core/api/transaction_api.dart';
import 'package:mobile_banking_app/core/model/transaction_model.dart';

class TransactionHistoryController extends GetxController {
  final TransactionApi transactionApi =
      TransactionApi();

  final RxList<TransactionModel> transactions =
      <TransactionModel>[].obs;

  final RxBool isLoading =
      false.obs;

  final RxString errorMessage =
      ''.obs;

  @override
  void onInit() {
    super.onInit();

    getTransactions();
  }

  Future<void> getTransactions() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response =
          await transactionApi
              .getHistory();

      final dynamic rawData =
          response['data'];

      // No data
      if (rawData == null) {
        transactions.clear();
        return;
      }

      // Must be list
      if (rawData is! List) {
        throw Exception(
          'Transaction data is invalid',
        );
      }

      final List<TransactionModel>
          result =
          rawData.map(
        (item) {
          return TransactionModel.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          );
        },
      ).toList();

      transactions.assignAll(
        result,
      );
    } catch (e) {
      errorMessage.value =
          e.toString();

      print(
        'Transaction history error: $e',
      );
    } finally {
      isLoading.value =
          false;
    }
  }

  Future<void> refreshData() async {
    await getTransactions();
  }
}
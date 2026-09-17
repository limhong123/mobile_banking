import 'package:get/get.dart';

import 'package:mobile_banking_app/core/api/transaction_api.dart';

import 'package:mobile_banking_app/core/model/transaction_model.dart';

class TransactionDetailController
    extends GetxController {
  final String transactionId;

  TransactionDetailController({
    required this.transactionId,
  });

  final TransactionApi transactionApi =
      TransactionApi();

  final Rxn<TransactionModel>
      transaction =
      Rxn<TransactionModel>();

  final RxBool isLoading =
      false.obs;

  final RxString errorMessage =
      ''.obs;

  @override
  void onInit() {
    super.onInit();

    getTransactionDetail();
  }

  Future<void>
      getTransactionDetail() async {
    try {
      isLoading.value =
          true;

      errorMessage.value =
          '';

      final response =
          await transactionApi
              .getDetail(
        transactionId:
            transactionId,
      );

      final dynamic data =
          response['data'];

      if (data is! Map) {
        throw Exception(
          'Invalid transaction detail',
        );
      }

      transaction.value =
          TransactionModel.fromJson(
        Map<String, dynamic>.from(
          data,
        ),
      );
    } catch (e) {
      errorMessage.value =
          e.toString();
    } finally {
      isLoading.value =
          false;
    }
  }
}
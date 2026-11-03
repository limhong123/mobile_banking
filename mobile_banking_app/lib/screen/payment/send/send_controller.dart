import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mobile_banking_app/core/api/payment/payment_api.dart';


class SendController
    extends GetxController {
  final PaymentApi paymentApi =
      PaymentApi();

  final accountNumber =
      ''.obs;

  final receiverName =
      ''.obs;

  final receiverAccountNumber =
      ''.obs;

  final amount =
      ''.obs;

  final isSearching =
      false.obs;

  final isSending =
      false.obs;

  final receiverFound =
      false.obs;

  final TextEditingController amountController =
      TextEditingController();

  @override
  void onInit() {
    super.onInit();
    if (amount.value.isNotEmpty) {
      amountController.text = amount.value;
    }
  }

  void selectAmount(String val) {
    if (amount.value == val) {
      amount.value = '';
      amountController.clear();
    } else {
      amount.value = val;
      amountController.text = val;
      amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: val.length),
      );
    }
  }


  // =====================================================
  // FIND RECEIVER
  // =====================================================

  Future<void> findReceiver()
      async {
    final String account =
        accountNumber.value
            .trim();

    if (account.isEmpty) {
      Get.snackbar(
        'Account Number',
        'Please enter account number',
      );

      return;
    }

    try {
      isSearching.value =
          true;

      final response =
          await paymentApi
              .resolveAccount(
        accountNumber:
            account,
      );

      final dynamic data =
          response['data'];

      if (data is! Map) {
        throw Exception(
          'Receiver not found',
        );
      }

      receiverName.value =
          data['receiver_name']
                  ?.toString() ??
              '';

      receiverAccountNumber
          .value =
          data[
                      'receiver_account_number']
                  ?.toString() ??
              '';

      receiverFound.value =
          true;

    } catch (error) {
      Get.snackbar(
        'Error',
        cleanError(
          error,
        ),
      );

    } finally {
      isSearching.value =
          false;
    }
  }


  // =====================================================
  // SEND
  // =====================================================

  Future<void> sendMoney()
      async {
    final double? value =
        double.tryParse(
      amount.value,
    );

    if (
        value == null ||
        value <= 0
    ) {
      Get.snackbar(
        'Amount',
        'Please enter valid amount',
      );

      return;
    }

    final bool confirmed =
        await Get.dialog<bool>(
              AlertDialog(
                title:
                    const Text(
                  'Confirm Transfer',
                ),

                content:
                    Text(
                  'Send \$${value.toStringAsFixed(2)} to ${receiverName.value}?',
                ),

                actions: [
                  TextButton(
                    onPressed: () =>
                        Get.back(
                      result:
                          false,
                    ),
                    child:
                        const Text(
                      'Cancel',
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () =>
                        Get.back(
                      result:
                          true,
                    ),
                    child:
                        const Text(
                      'Confirm',
                    ),
                  ),
                ],
              ),
            ) ??
            false;

    if (!confirmed) {
      return;
    }

    try {
      isSending.value =
          true;

      final response =
          await paymentApi
              .transferByAccount(
        accountNumber:
            receiverAccountNumber
                .value,

        amount:
            value,

        description:
            'Account transfer',
      );

      final dynamic data =
          response['data'];

      Get.dialog(
        AlertDialog(
          icon:
              const Icon(
            Icons.check_circle,
            size:
                60,
            color:
                Colors.green,
          ),

          title:
              const Text(
            'Transfer Successful',
          ),

          content:
              Text(
            'Sent \$${value.toStringAsFixed(2)} to ${receiverName.value}\n\nTransaction: ${data?['transaction_id'] ?? '-'}',
          ),

          actions: [
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.back();
              },
              child:
                  const Text(
                'Done',
              ),
            ),
          ],
        ),

        barrierDismissible:
            false,
      );

    } catch (error) {
      Get.snackbar(
        'Transfer Failed',
        cleanError(
          error,
        ),
      );

    } finally {
      isSending.value =
          false;
    }
  }


  void resetReceiver() {
    receiverFound.value =
        false;

    receiverName.value =
        '';

    receiverAccountNumber
        .value =
        '';

    amount.value =
        '';

    amountController.clear();
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }


  String cleanError(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }
}
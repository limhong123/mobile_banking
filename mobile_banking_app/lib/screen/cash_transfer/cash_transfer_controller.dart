import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mobile_banking_app/core/api/cash_transfer_api.dart';


class CashReceiveController
    extends GetxController {
  final CashTransferApi api =
      CashTransferApi();


  final TextEditingController
      codeController =
      TextEditingController();


  final isLoading =
      false.obs;

  final transferFound =
      false.obs;

  final code =
      ''.obs;

  final senderName =
      ''.obs;

  final amount =
      0.0.obs;


  // =====================================================
  // CODE INPUT
  // =====================================================

  void onCodeChanged(
    String value,
  ) {
    final digits =
        value.replaceAll(
      RegExp(
        r'[^0-9]',
      ),
      '',
    );

    if (
        digits !=
        value) {
      codeController.value =
          TextEditingValue(
        text:
            digits,
        selection:
            TextSelection.collapsed(
          offset:
              digits.length,
        ),
      );
    }
  }


  // =====================================================
  // CHECK
  // =====================================================

  Future<void> checkCode()
      async {
    final value =
        codeController.text
            .trim();


    if (
        !RegExp(
          r'^\d{12}$',
        ).hasMatch(
          value,
        )) {
      Get.snackbar(
        'Invalid Code',
        'សូមបញ្ចូលលេខ Code 12 ខ្ទង់',
        snackPosition:
            SnackPosition.BOTTOM,
      );

      return;
    }


    try {
      isLoading.value =
          true;


      final response =
          await api.checkCode(
        code:
            value,
      );


      final dynamic data =
          response['data'];


      if (data is! Map) {
        throw Exception(
          'Transfer not found',
        );
      }


      code.value =
          data['code']
                  ?.toString() ??
              '';


      senderName.value =
          data['sender_name']
                  ?.toString() ??
              '';


      amount.value =
          double.tryParse(
            data['amount']
                    ?.toString() ??
                '0',
          ) ??
          0;


      transferFound.value =
          true;

    } catch (error) {
      transferFound.value =
          false;

      Get.snackbar(
        'មិនអាចទទួលបាន',
        _cleanError(
          error,
        ),
        snackPosition:
            SnackPosition.BOTTOM,
      );

    } finally {
      isLoading.value =
          false;
    }
  }


  // =====================================================
  // CLAIM
  // =====================================================

  Future<void> receiveMoney()
      async {
    if (
        !transferFound.value) {
      return;
    }


    try {
      isLoading.value =
          true;


      final response =
          await api.claimToAccount(
        code:
            code.value,
      );


      final dynamic data =
          response['data'];


      final double balanceAfter =
          double.tryParse(
            data?['balance_after']
                    ?.toString() ??
                '0',
          ) ??
          0;


      await Get.dialog(
        AlertDialog(
          icon:
              const Icon(
            Icons
                .check_circle_rounded,
            size:
                64,
            color:
                Colors.green,
          ),

          title:
              const Text(
            'ទទួលប្រាក់ជោគជ័យ',
          ),

          content:
              Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Text(
                '\$${amount.value.toStringAsFixed(2)}',
                style:
                    const TextStyle(
                  fontSize:
                      32,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height:
                    12,
              ),

              Text(
                'Balance: \$${balanceAfter.toStringAsFixed(2)}',
              ),
            ],
          ),

          actions: [
            ElevatedButton(
              onPressed: () {
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


      Get.back(
        result:
            true,
      );

    } catch (error) {
      Get.snackbar(
        'Receive Failed',
        _cleanError(
          error,
        ),
        snackPosition:
            SnackPosition.BOTTOM,
      );

    } finally {
      isLoading.value =
          false;
    }
  }


  String _cleanError(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }


  @override
  void onClose() {
    codeController.dispose();

    super.onClose();
  }
}
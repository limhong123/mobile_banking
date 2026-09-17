import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:mobile_banking_app/core/api/payment/payment_api.dart';

class ScanQrController extends GetxController {
  final PaymentApi paymentApi = PaymentApi();

  final MobileScannerController scannerController =
      MobileScannerController();

  // Amount TextField controller
  final TextEditingController amountController =
      TextEditingController();

  final isProcessing = false.obs;
  final receiverFound = false.obs;

  final receiverName = ''.obs;
  final receiverQrId = ''.obs;
  final receiverAccountNumber = ''.obs;

  final amount = ''.obs;

  // Was amount provided by receiver QR?
  final hasQrAmount = false.obs;

  // =====================================================
  // SCAN QR
  // =====================================================

  Future<void> onDetect(
    BarcodeCapture capture,
  ) async {
    if (isProcessing.value ||
        receiverFound.value) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    final String qrValue =
        capture.barcodes.first.rawValue?.trim() ?? '';

    if (qrValue.isEmpty) {
      return;
    }

    // ===================================================
    // CHECK KHEMPAY QR
    // ===================================================

    if (!qrValue.startsWith(
      'KHPAY:PAY:',
    )) {
      Get.snackbar(
        'Invalid QR',
        'This is not a KhemPay QR code',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    try {
      isProcessing.value = true;

      // =================================================
      // RESOLVE QR FROM BACKEND
      // =================================================

      final response =
          await paymentApi.resolveQr(
        qrPayload: qrValue,
      );

      if (response['success'] != true) {
        throw Exception(
          response['detail'] ??
              response['message'] ??
              'Unable to resolve QR',
        );
      }

      final dynamic rawData =
          response['data'];

      if (rawData is! Map) {
        throw Exception(
          'Receiver data invalid',
        );
      }

      final data =
          Map<String, dynamic>.from(
        rawData,
      );

      // =================================================
      // RECEIVER
      // =================================================

      receiverName.value =
          data['receiver_name']
                  ?.toString() ??
              '';

      receiverQrId.value =
          data['receiver_qr_id']
                  ?.toString() ??
              '';

      receiverAccountNumber.value =
          data['receiver_account_number']
                  ?.toString() ??
              '';

      if (receiverQrId.value.isEmpty) {
        throw Exception(
          'Receiver QR ID not found',
        );
      }

      // =================================================
      // GET AMOUNT FROM QR
      // =================================================

      final dynamic qrAmount =
          data['amount'];

      if (qrAmount != null) {
        final double? parsedAmount =
            double.tryParse(
          qrAmount.toString(),
        );

        if (parsedAmount != null &&
            parsedAmount > 0) {
          final formatted =
              parsedAmount.toStringAsFixed(2);

          amount.value = formatted;

          amountController.text =
              formatted;

          hasQrAmount.value = true;
        } else {
          _clearAmount();
        }
      } else {
        // Normal QR without amount
        _clearAmount();
      }

      // =================================================
      // SHOW PAYMENT VIEW
      // =================================================

      receiverFound.value = true;

      await scannerController.stop();
    } catch (error) {
      Get.snackbar(
        'QR Error',
        _cleanError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  // =====================================================
  // UPDATE AMOUNT
  // =====================================================

  void updateAmount(
    String value,
  ) {
    amount.value = value;
  }

  // =====================================================
  // SEND MONEY
  // =====================================================

  Future<void> sendMoney() async {
    if (isProcessing.value) {
      return;
    }

    if (!receiverFound.value ||
        receiverQrId.value.isEmpty) {
      Get.snackbar(
        'Receiver',
        'Please scan receiver QR first',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    final double? transferAmount =
        double.tryParse(
      amount.value.trim(),
    );

    if (transferAmount == null ||
        transferAmount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Please enter a valid amount',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    // ===================================================
    // CONFIRM TRANSFER
    // ===================================================

    final bool confirmed =
        await Get.dialog<bool>(
              AlertDialog(
                title: const Text(
                  'Confirm Transfer',
                ),
                content: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You are sending',
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      '\$${transferAmount.toStringAsFixed(2)}',
                      style:
                          const TextStyle(
                        fontSize: 26,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    const Text('To'),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      receiverName.value,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    if (receiverAccountNumber
                        .value
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        receiverAccountNumber
                            .value,
                        style: TextStyle(
                          color: Colors
                              .grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Get.back(
                        result: false,
                      );
                    },
                    child: const Text(
                      'Cancel',
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Get.back(
                        result: true,
                      );
                    },
                    child: const Text(
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

    // ===================================================
    // TRANSFER
    // ===================================================

    try {
      isProcessing.value = true;

      final response =
          await paymentApi.transferByQr(
        receiverQrId:
            receiverQrId.value,
        amount:
            transferAmount,
        description:
            'QR transfer',
      );

      final dynamic rawData =
          response['data'];

      if (rawData is! Map) {
        throw Exception(
          'Transfer response invalid',
        );
      }

      final data =
          Map<String, dynamic>.from(
        rawData,
      );

      final String transactionId =
          data['transaction_id']
                  ?.toString() ??
              '-';

      final double balanceAfter =
          double.tryParse(
            data['balance_after']
                    ?.toString() ??
                '0',
          ) ??
          0;

      // =================================================
      // SUCCESS
      // =================================================

      await Get.dialog(
        AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: Colors.green,
          ),

          title: const Text(
            'Transfer Successful',
            textAlign:
                TextAlign.center,
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Text(
                '\$${transferAmount.toStringAsFixed(2)}',
                style:
                    const TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                'Sent to ${receiverName.value}',
                textAlign:
                    TextAlign.center,
              ),

              if (receiverAccountNumber
                  .value
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 4,
                ),

                Text(
                  receiverAccountNumber
                      .value,
                  style: TextStyle(
                    color: Colors
                        .grey.shade600,
                  ),
                ),
              ],

              const SizedBox(
                height: 18,
              ),

              _infoRow(
                'Transaction',
                transactionId,
              ),

              const SizedBox(
                height: 8,
              ),

              _infoRow(
                'Balance',
                '\$${balanceAfter.toStringAsFixed(2)}',
              ),
            ],
          ),

          actions: [
            ElevatedButton(
              onPressed: () {
                Get.back();
              },
              child: const Text(
                'Done',
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      Get.back(
        result: {
          'success': true,
          'balance_after':
              balanceAfter,
        },
      );
    } catch (error) {
      Get.snackbar(
        'Transfer Failed',
        _cleanError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  // =====================================================
  // CLEAR AMOUNT
  // =====================================================

  void _clearAmount() {
    amount.value = '';

    amountController.clear();

    hasQrAmount.value = false;
  }

  // =====================================================
  // SCAN AGAIN
  // =====================================================

  Future<void> scanAgain() async {
    receiverFound.value = false;

    receiverName.value = '';
    receiverQrId.value = '';
    receiverAccountNumber.value = '';

    _clearAmount();

    await scannerController.start();
  }

  // =====================================================
  // INFO ROW
  // =====================================================

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color:
                Colors.grey.shade600,
          ),
        ),

        const SizedBox(
          width: 20,
        ),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // CLEAN ERROR
  // =====================================================

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

  // =====================================================
  // CLOSE
  // =====================================================

  @override
  void onClose() {
    amountController.dispose();

    scannerController.dispose();

    super.onClose();
  }
}
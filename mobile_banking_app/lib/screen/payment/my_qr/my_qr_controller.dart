import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/core/api/payment/payment_api.dart';

class MyQrController extends GetxController {
  final PaymentApi paymentApi =
      PaymentApi();

  // =====================================================
  // STATE
  // =====================================================

  final RxBool isLoading =
      false.obs;

  final RxString errorMessage =
      ''.obs;

  final RxString customerName =
      ''.obs;

  final RxString accountNumber =
      ''.obs;

  final RxString qrId =
      ''.obs;

  final RxString qrPayload =
      ''.obs;

  final RxDouble selectedAmount =
      0.0.obs;

  final TextEditingController
      amountController =
      TextEditingController();

  // =====================================================
  // INIT
  // =====================================================

  @override
  void onInit() {
    super.onInit();

    loadQr();
  }

  // =====================================================
  // LOAD MY QR
  // =====================================================

  Future<void> loadQr() async {
    try {
      isLoading.value = true;

      errorMessage.value = '';

      final response =
          await paymentApi.getMyQr();

      if (response['success'] != true) {
        throw Exception(
          response['detail'] ??
              response['message'] ??
              'Unable to load QR',
        );
      }

      final dynamic rawData =
          response['data'];

      if (rawData is! Map) {
        throw Exception(
          'QR data invalid',
        );
      }

      final data =
          Map<String, dynamic>.from(
        rawData,
      );

      customerName.value =
          data['customer_name']?.toString() ??
              data['name']?.toString() ??
              '';

      accountNumber.value =
          data['account_number']
                  ?.toString() ??
              '';

      qrId.value =
          data['qr_id']
                  ?.toString() ??
              '';

      // Backend may already return qr_payload.
      final backendPayload =
          data['qr_payload']
                  ?.toString() ??
              '';

      if (backendPayload.isNotEmpty) {
        qrPayload.value =
            backendPayload;
      } else {
        generateNormalQr();
      }
    } catch (error) {
      errorMessage.value = error
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================
  // NORMAL QR
  // No amount
  // =====================================================

  void generateNormalQr() {
    selectedAmount.value = 0;

    amountController.clear();

    if (qrId.value.isEmpty) {
      return;
    }

    qrPayload.value =
        'KHPAY:PAY:${qrId.value}';
  }

  // =====================================================
  // QR WITH AMOUNT
  // =====================================================

  bool generateQrWithAmount() {
    final text =
        amountController.text
            .trim();

    final amount =
        double.tryParse(text);

    if (amount == null ||
        amount <= 0) {
      Get.snackbar(
        'ចំនួនទឹកប្រាក់មិនត្រឹមត្រូវ',
        'សូមបញ្ចូលចំនួនទឹកប្រាក់ឲ្យបានត្រឹមត្រូវ',
        snackPosition:
            SnackPosition.BOTTOM,
        backgroundColor:
            Colors.red.shade50,
        colorText: Colors.red,
        margin:
            const EdgeInsets.all(16),
      );

      return false;
    }

    if (qrId.value.isEmpty) {
      Get.snackbar(
        'QR Error',
        'QR ID មិនទាន់មាន',
        snackPosition:
            SnackPosition.BOTTOM,
      );

      return false;
    }

    selectedAmount.value =
        amount;

    qrPayload.value =
        'KHPAY:PAY:${qrId.value}:${amount.toStringAsFixed(2)}';

    return true;
  }

  // =====================================================
  // CLEAR AMOUNT
  // =====================================================

  void clearAmount() {
    generateNormalQr();
  }

  // =====================================================
  // CLOSE
  // =====================================================

  @override
  void onClose() {
    amountController.dispose();

    super.onClose();
  }
}
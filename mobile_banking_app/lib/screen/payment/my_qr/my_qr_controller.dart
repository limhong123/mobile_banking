import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';
import 'package:mobile_banking_app/core/api/payment/payment_api.dart';

class MyQrController extends GetxController {
  final PaymentApi paymentApi =
      PaymentApi();

  // =====================================================
  // STATE
  // =====================================================

  final GlobalKey qrCardKey = GlobalKey();

  final RxBool isLoading =
      false.obs;

  final RxBool isSaving =
      false.obs;

  final RxBool isSharing =
      false.obs;

  final RxBool isTelegramSharing =
      false.obs;

  final RxBool isCapturing =
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
  // CAPTURE QR CARD AS IMAGE
  // =====================================================

  Future<Uint8List?> captureQrCard() async {
    try {
      final boundary = qrCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 30));
        return captureQrCard();
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR card: $e');
      return null;
    }
  }

  Future<Uint8List?> _captureWithCleanState() async {
    isCapturing.value = true;
    await Future.delayed(const Duration(milliseconds: 50));
    final bytes = await captureQrCard();
    isCapturing.value = false;
    return bytes;
  }

  Future<File?> _saveToTempFile(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'khempay_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('Error writing temporary QR image: $e');
      return null;
    }
  }

  // =====================================================
  // 1. SAVE QR TO GALLERY
  // =====================================================

  Future<void> saveQrImage() async {
    if (isSaving.value || isSharing.value || isTelegramSharing.value) return;

    if (qrPayload.value.isEmpty) {
      Get.snackbar(
        'QR Code',
        'QR Code មិនទាន់មានទិន្នន័យ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade900,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      isSaving.value = true;

      final bytes = await _captureWithCleanState();
      if (bytes == null) {
        throw Exception('មិនអាចបង្កើតរូបភាព QR បានទេ');
      }

      final tempFile = await _saveToTempFile(bytes);
      if (tempFile == null) {
        throw Exception('មិនអាចរៀបចំឯកសាររូបភាពបានទេ');
      }

      await Gal.putImage(tempFile.path);

      Get.snackbar(
        'ជោគជ័យ',
        'បានរក្សាទុក QR Code ក្នុង Gallery ដោយជោគជ័យ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade900,
        icon: const Icon(Icons.check_circle, color: Colors.green),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
    } on GalException catch (e) {
      String msg = 'មិនអាចរក្សាទុក QR code បានទេ';
      if (e.type == GalExceptionType.accessDenied) {
        msg = 'សូមអនុញ្ញាតសិទ្ធិចូលប្រើ Photo Gallery នៅក្នុងការកំណត់ (Settings)';
      }
      Get.snackbar(
        'បរាជ័យ',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
        icon: const Icon(Icons.error_outline, color: Colors.red),
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'បរាជ័យ',
        'កំហុសក្នុងការរក្សាទុក: ${e.toString().replaceFirst('Exception: ', '')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSaving.value = false;
    }
  }

  // =====================================================
  // 2. SHARE QR IMAGE (NATIVE SHARE SHEET)
  // =====================================================

  Future<void> shareQrImage() async {
    if (isSaving.value || isSharing.value || isTelegramSharing.value) return;

    if (qrPayload.value.isEmpty) {
      Get.snackbar(
        'QR Code',
        'QR Code មិនទាន់មានទិន្នន័យ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade900,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      isSharing.value = true;

      final bytes = await _captureWithCleanState();
      if (bytes == null) {
        throw Exception('មិនអាចបង្កើតរូបភាព QR បានទេ');
      }

      final tempFile = await _saveToTempFile(bytes);
      if (tempFile == null) {
        throw Exception('មិនអាចរៀបចំឯកសាររូបភាពបានទេ');
      }

      final String amountText = selectedAmount.value > 0
          ? ' - \$${selectedAmount.value.toStringAsFixed(2)}'
          : '';
      final String caption =
          'KhemPay QR: ${customerName.value}$amountText';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path, mimeType: 'image/png')],
          text: caption,
          subject: 'KhemPay QR Payment',
        ),
      );
    } catch (e) {
      Get.snackbar(
        'បរាជ័យ',
        'កំហុសក្នុងការចែករំលែក: ${e.toString().replaceFirst('Exception: ', '')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSharing.value = false;
    }
  }

  // =====================================================
  // 3. SHARE DIRECTLY TO TELEGRAM
  // =====================================================

  Future<void> shareToTelegram() async {
    if (isSaving.value || isSharing.value || isTelegramSharing.value) return;

    if (qrPayload.value.isEmpty) {
      Get.snackbar(
        'QR Code',
        'QR Code មិនទាន់មានទិន្នន័យ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade900,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    try {
      isTelegramSharing.value = true;

      final bytes = await _captureWithCleanState();
      if (bytes == null) {
        throw Exception('មិនអាចបង្កើតរូបភាព QR បានទេ');
      }

      final tempFile = await _saveToTempFile(bytes);
      if (tempFile == null) {
        throw Exception('មិនអាចរៀបចំឯកសាររូបភាពបានទេ');
      }

      final String amountText = selectedAmount.value > 0
          ? ' - \$${selectedAmount.value.toStringAsFixed(2)}'
          : '';
      final String caption =
          'KhemPay QR: ${customerName.value}$amountText';

      try {
        await SocialSharingPlus.shareToSocialMedia(
          SocialPlatform.telegram,
          caption,
          media: tempFile.path,
          isOpenBrowser: false,
          onAppNotInstalled: () async {
            Get.snackbar(
              'Telegram',
              'មិនបានរកឃើញកម្មវិធី Telegram ទេ។ កំពុងបើកផ្ទាំងចែករំលែក...',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange.shade50,
              colorText: Colors.orange.shade900,
              margin: const EdgeInsets.all(16),
            );
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(tempFile.path, mimeType: 'image/png')],
                text: caption,
                subject: 'KhemPay QR Payment',
              ),
            );
          },
        );
      } catch (e) {
        debugPrint('Direct telegram share error: $e. Falling back to Share.');
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(tempFile.path, mimeType: 'image/png')],
            text: caption,
            subject: 'KhemPay QR Payment',
          ),
        );
      }
    } catch (e) {
      Get.snackbar(
        'បរាជ័យ',
        'កំហុសក្នុងការចែករំលែកទៅ Telegram: ${e.toString().replaceFirst('Exception: ', '')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isTelegramSharing.value = false;
    }
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
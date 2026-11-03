import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/core/widget/item_button.dart';
import 'package:mobile_banking_app/screen/payment/my_qr/my_qr_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyQrView extends GetView<MyQrController> {
  const MyQrView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,

      // ===================================================
      // APP BAR
      // ===================================================
      appBar: AppBar(
        automaticallyImplyLeading: false,

        backgroundColor: AppColor.white,

        surfaceTintColor: AppColor.white,

        elevation: 0,

        centerTitle: true,

        title: Text('KhemPay QR', style: AppText.h4.copyWith(color: AppColor.textPrimary)),

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 24),

            width: 42,

            height: 42,

            decoration: BoxDecoration(
              color: AppColor.background,

              shape: BoxShape.circle,
            ),

            child: IconButton(
              onPressed: Get.back,

              icon: const Icon(Icons.close, color: AppColor.textPrimary),
            ),
          ),
        ],
      ),

      // ===================================================
      // BODY
      // ===================================================
      body: Obx(() {
        // =================================================
        // LOADING
        // =================================================

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColor.secondaryColor));
        }

        // =================================================
        // ERROR
        // =================================================

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  const Icon(Icons.error_outline, size: 60, color: AppColor.red),

                  const SizedBox(height: 16),

                  Text(
                    controller.errorMessage.value,

                    textAlign: TextAlign.center,
                    style: AppText.bodyMedium.copyWith(color: AppColor.textPrimary),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: controller.loadQr,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.secondaryColor,
                      foregroundColor: AppColor.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // =================================================
        // QR PAGE
        // =================================================

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 30),

          child: Center(
            child: Column(
              children: [
                // ===========================================
                // QR CARD
                // ===========================================
                RepaintBoundary(
                  key: controller.qrCardKey,
                  child: Container(
                    width: double.infinity,

                    constraints: const BoxConstraints(maxWidth: 300),

                    padding: const EdgeInsets.only(bottom: 24),

                    decoration: BoxDecoration(
                      color: AppColor.white,

                      borderRadius: BorderRadius.circular(28),

                      boxShadow: [
                        BoxShadow(
                          color: AppColor.shadow,

                          blurRadius: 24,

                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // =====================================
                        // HEADER
                        // =====================================
                        Container(
                          width: double.infinity,

                          height: 58,

                          decoration: BoxDecoration(
                            color: AppColor.secondaryColor,

                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),

                              topRight: Radius.circular(28),
                            ),
                          ),

                          child: Center(
                            child: Text(
                              'KHEMPAY QR',

                              style: AppText.h4.copyWith(
                                color: AppColor.white,

                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        // =====================================
                        // NAME + AMOUNT
                        // =====================================
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,

                            vertical: 10,
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                controller.customerName.value,

                                maxLines: 1,

                                overflow: TextOverflow.ellipsis,

                                style: AppText.h4.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: AppColor.textPrimary,
                                ),
                              ),

                              const SizedBox(height: 4),

                              // =================================
                              // SHOW AMOUNT
                              // =================================
                              if (controller.selectedAmount.value > 0)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '\$${controller.selectedAmount.value.toStringAsFixed(2)}',

                                        maxLines: 1,

                                        overflow: TextOverflow.ellipsis,

                                        style: AppText.h3.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColor.textPrimary,
                                        ),
                                      ),
                                    ),

                                    if (!controller.isCapturing.value) ...[
                                      const SizedBox(width: 8),

                                      GestureDetector(
                                        onTap: controller.clearAmount,

                                        child: const Icon(
                                          Icons.close,
                                          size: 20,
                                          color: AppColor.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              else
                                Text(
                                  '0',

                                  style: AppText.h3.copyWith(
                                    fontSize: 22,

                                    fontWeight: FontWeight.w500,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // =====================================
                        // QR
                        // =====================================
                        Center(
                          child: QrImageView(
                            data: controller.qrPayload.value,

                            version: QrVersions.auto,

                            size: 250,

                            backgroundColor: AppColor.white,

                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===========================================
                // ENTER AMOUNT BUTTON
                // ===========================================
                InkWell(
                  onTap: () {
                    _showAmountInput(context);
                  },

                  borderRadius: BorderRadius.circular(10),

                  child: Container(
                    width: 300,

                    height: 44,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),

                      color: AppColor.transparent,

                      border: Border.all(
                        color: AppColor.secondaryColor,

                        width: 1.5,
                      ),
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Icon(
                          Icons.add_circle_outline,

                          color: AppColor.secondaryColor,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          controller.selectedAmount.value > 0
                              ? 'កែប្រែទឹកប្រាក់'
                              : 'បញ្ចូលទឹកប្រាក់',

                          style: AppText.bodySmall.copyWith(
                            color: AppColor.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===========================================
                // ACCOUNT NUMBER
                // ===========================================
                if (controller.accountNumber.value.isNotEmpty)
                  Text(
                    'Account: ${controller.accountNumber.value}',

                    style: AppText.labelSmall.copyWith(
                      color: AppColor.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),

      // ===================================================
      // BOTTOM ACTION
      // ===================================================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColor.white,

          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),

          boxShadow: [
            BoxShadow(
              color: AppColor.shadow,

              blurRadius: 15,

              offset: const Offset(0, -2),
            ),
          ],
        ),

        child: SafeArea(
          top: false,

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                children: [
                  ItemButton(
                    text: 'Save',
                    icon: Icons.save_alt,
                    isLoading: controller.isSaving.value,
                    onTap: controller.saveQrImage,
                  ),

                  ItemButton(
                    text: 'Share',
                    icon: Icons.share,
                    isLoading: controller.isSharing.value,
                    onTap: controller.shareQrImage,
                  ),

                  ItemButton(
                    text: 'Telegram',
                    icon: Icons.telegram_outlined,
                    isLoading: controller.isTelegramSharing.value,
                    onTap: controller.shareToTelegram,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // SHOW AMOUNT INPUT
  // =====================================================

  void _showAmountInput(BuildContext context) {
    if (controller.selectedAmount.value > 0) {
      controller.amountController.text = controller.selectedAmount.value
          .toStringAsFixed(2);

      controller.amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.amountController.text.length),
      );
    } else {
      controller.amountController.clear();
    }

    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),

          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),

            decoration: const BoxDecoration(
              color: AppColor.white,

              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                // =========================================
                // DRAG HANDLE
                // =========================================
                Container(
                  width: 45,

                  height: 5,

                  decoration: BoxDecoration(
                    color: AppColor.textHint,

                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================================
                // TITLE
                // =========================================
                Text(
                  'បញ្ចូលចំនួនទឹកប្រាក់',

                  style: AppText.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'បញ្ចូលទឹកប្រាក់ដែលអ្នកចង់ទទួល',

                  style: AppText.bodySmall.copyWith(
                    fontSize: 13,
                    color: AppColor.textSecondary,
                  ),
                ),

                const SizedBox(height: 22),

                // =========================================
                // AMOUNT TEXT FIELD
                // =========================================
                TextField(
                  controller: controller.amountController,

                  autofocus: true,

                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),

                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],

                  textAlign: TextAlign.center,

                  style: AppText.bodyLarge.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),

                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: AppText.bodyLarge.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),

                    hintText: '0.00',
                    hintStyle: AppText.bodyLarge.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textHint,
                    ),

                    filled: true,

                    fillColor: AppColor.background,

                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,

                      horizontal: 15,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),

                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),

                      borderSide: BorderSide.none,
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),

                      borderSide: const BorderSide(
                        color: AppColor.secondaryColor,

                        width: 1.5,
                      ),
                    ),
                  ),

                  onSubmitted: (_) {
                    _generateAmountQr();
                  },
                ),

                const SizedBox(height: 20),

                // =========================================
                // GENERATE BUTTON
                // =========================================
                SizedBox(
                  width: double.infinity,

                  height: 50,

                  child: ElevatedButton(
                    onPressed: _generateAmountQr,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.secondaryColor,

                      foregroundColor: AppColor.white,

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    child: Text(
                      'បង្កើត QR',

                      style: AppText.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColor.white,
                      ),
                    ),
                  ),
                ),

                // =========================================
                // REMOVE AMOUNT
                // =========================================
                if (controller.selectedAmount.value > 0) ...[
                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: () {
                      controller.clearAmount();

                      Get.back();
                    },

                    child: Text(
                      'ដកចំនួនទឹកប្រាក់ចេញ',
                      style: AppText.bodySmall.copyWith(color: AppColor.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

      isScrollControlled: true,

      backgroundColor: AppColor.transparent,
    );
  }

  // =====================================================
  // GENERATE AMOUNT QR
  // =====================================================

  void _generateAmountQr() {
    final success = controller.generateQrWithAmount();

    if (success) {
      Get.back();
    }
  }
}

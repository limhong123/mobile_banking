import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/screen/scan_qr/scan_qr_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrView extends GetView<ScanQrController> {
  const ScanQrView({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'ស្កេន QR',
          style: AppText.h4.copyWith(color: AppColor.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: AppColor.white,
        surfaceTintColor: AppColor.white,
      ),
      body: Obx(
        () {
          if (controller.receiverFound.value) {
            return _paymentView();
          }

          return _scannerView();
        },
      ),
    );
  }

  // =====================================================
  // SCANNER
  // =====================================================

  Widget _scannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: controller.scannerController,
          onDetect: controller.onDetect,
        ),

        // Scanner box
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColor.white,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(
                28,
              ),
            ),
          ),
        ),

        // Loading while resolving QR
        Obx(
          () => controller.isProcessing.value
              ? Container(
                  color: AppColor.shadowDark,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColor.white,
                    ),
                  ),
                )
              : const SizedBox(),
        ),

        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: Container(
            padding: const EdgeInsets.all(
              16,
            ),
            decoration: BoxDecoration(
              color: AppColor.shadowDark,
              borderRadius: BorderRadius.circular(
                16,
              ),
            ),
            child: Text(
              'ស្កេន KhemPay QR Code',
              textAlign: TextAlign.center,
              style: AppText.bodySmall.copyWith(
                color: AppColor.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // PAYMENT VIEW
  // =====================================================

  Widget _paymentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 18,
          ),

          Text(
            'ផ្ទេរប្រាក់',
            style: AppText.h2.copyWith(color: AppColor.textPrimary),
          ),

          const SizedBox(
            height: 24,
          ),

          // =================================================
          // RECEIVER
          // =================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
              18,
            ),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(
                20,
              ),
              border: Border.all(
                color: AppColor.background,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColor.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColor.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColor.white,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.receiverName.value,
                        style: AppText.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      if (controller.receiverAccountNumber.value.isNotEmpty)
                        Text(
                          controller.receiverAccountNumber.value,
                          style: AppText.bodySmall.copyWith(
                            color: AppColor.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          Text(
            'ចំនួនទឹកប្រាក់',
            style: AppText.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // =================================================
          // AMOUNT
          // =================================================

          Obx(
            () => TextField(
              controller: controller.amountController,
              readOnly: controller.hasQrAmount.value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: controller.updateAmount,
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: AppText.h2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
                hintText: '0.00',
                hintStyle: AppText.h2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColor.textHint,
                ),
                filled: controller.hasQrAmount.value,
                fillColor: controller.hasQrAmount.value
                    ? AppColor.background
                    : AppColor.white,
                helperText: controller.hasQrAmount.value
                    ? 'ចំនួនទឹកប្រាក់កំណត់ដោយអ្នកទទួល'
                    : 'បញ្ចូលចំនួនទឹកប្រាក់',
                helperStyle: AppText.labelSmall.copyWith(
                  color: AppColor.textSecondary,
                ),
                suffixIcon: controller.hasQrAmount.value
                    ? const Icon(
                        Icons.lock_outline,
                        color: AppColor.secondaryColor,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                  borderSide: const BorderSide(
                    color: AppColor.secondaryColor,
                    width: 1.5,
                  ),
                ),
              ),
              style: AppText.h2.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          // =================================================
          // CONTINUE
          // =================================================

          Obx(
            () => ElevatedButton(
              onPressed: controller.isProcessing.value
                  ? null
                  : controller.sendMoney,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  54,
                ),
                backgroundColor: AppColor.secondaryColor,
                foregroundColor: AppColor.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              child: controller.isProcessing.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColor.white,
                      ),
                    )
                  : Text(
                      'បន្ត',
                      style: AppText.bodyLarge.copyWith(
                        color: AppColor.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          OutlinedButton(
            onPressed: controller.scanAgain,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                52,
              ),
              foregroundColor: AppColor.secondaryColor,
              side: const BorderSide(
                color: AppColor.secondaryColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
            ),
            child: Text(
              'ស្កេន QR ផ្សេងទៀត',
              style: AppText.bodyLarge.copyWith(
                color: AppColor.secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

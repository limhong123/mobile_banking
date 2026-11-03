import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/screen/cash_transfer/cash_transfer_controller.dart';

class CashReceiveView extends GetView<CashReceiveController> {
  const CashReceiveView({
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
          'Receive Money',
          style: AppText.h4.copyWith(color: AppColor.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: AppColor.white,
        surfaceTintColor: AppColor.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textPrimary),
      ),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.all(
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cash Transfer Code',
                style: AppText.h2.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                'បញ្ចូលលេខ Code 12 ខ្ទង់ ដែល Agent ផ្តល់ឲ្យអ្នក។',
                style: AppText.bodyMedium.copyWith(
                  color: AppColor.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(
                height: 28,
              ),
              TextField(
                controller: controller.codeController,
                keyboardType: TextInputType.number,
                maxLength: 12,
                onChanged: controller.onCodeChanged,
                style: AppText.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: AppColor.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: '12-Digit Code',
                  labelStyle: AppText.bodyMedium.copyWith(color: AppColor.textSecondary),
                  hintText: '583104927611',
                  hintStyle: AppText.bodyLarge.copyWith(color: AppColor.textHint),
                  prefixIcon: const Icon(
                    Icons.confirmation_number_outlined,
                    color: AppColor.secondaryColor,
                  ),
                  filled: true,
                  fillColor: AppColor.white,
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
              ),
              const SizedBox(
                height: 12,
              ),
              ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.checkCode,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(
                    double.infinity,
                    54,
                  ),
                  backgroundColor: AppColor.secondaryColor,
                  foregroundColor: AppColor.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColor.white,
                        ),
                      )
                    : Text(
                        'Check Code',
                        style: AppText.bodyLarge.copyWith(
                          color: AppColor.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              if (controller.transferFound.value) ...[
                const SizedBox(
                  height: 28,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(
                    22,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(
                      22,
                    ),
                    border: Border.all(
                      color: AppColor.primaryColor.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.shadow,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.payments_rounded,
                        size: 52,
                        color: AppColor.primaryColor,
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      Text(
                        '\$${controller.amount.value.toStringAsFixed(2)}',
                        style: AppText.h1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        'From ${controller.senderName.value}',
                        style: AppText.bodyMedium.copyWith(
                          color: AppColor.textSecondary,
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.receiveMoney,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(
                            double.infinity,
                            54,
                          ),
                          backgroundColor: AppColor.primaryColor,
                          foregroundColor: AppColor.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Receive to My Account',
                          style: AppText.bodyLarge.copyWith(
                            color: AppColor.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

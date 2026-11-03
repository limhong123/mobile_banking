import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/screen/payment/send/send_controller.dart';

class SendView extends GetView<SendController> {
  const SendView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColor.textPrimary,
        ),
        title: Text(
          'Send Money',
          style: AppText.h3.copyWith(color: AppColor.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: AppColor.scaffoldBackground,
        foregroundColor: AppColor.textPrimary,
        elevation: 0,
        surfaceTintColor: AppColor.transparent,
      ),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColor.secondaryColor,
                      AppColor.secondaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.secondaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer',
                      style: AppText.labelSmall.copyWith(
                        color: AppColor.white.withValues(alpha: 0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fast, secure, and simple.',
                      style: AppText.h2.copyWith(
                        color: AppColor.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.security_rounded,
                          color: AppColor.white.withValues(alpha: 0.7),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Protected by bank-grade security',
                          style: AppText.labelSmall.copyWith(
                            color: AppColor.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (!controller.receiverFound.value) ...[
                Text(
                  'Receiver Details',
                  style: AppText.h4.copyWith(color: AppColor.textPrimary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: controller.accountNumber.value,
                        onChanged: (value) =>
                            controller.accountNumber.value = value,
                        textCapitalization: TextCapitalization.characters,
                        style: AppText.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColor.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Account Number',
                          labelStyle: AppText.bodyMedium.copyWith(color: AppColor.textSecondary),
                          hintText: 'KHP123456789',
                          hintStyle: AppText.bodyLarge.copyWith(color: AppColor.textHint),
                          filled: true,
                          fillColor: AppColor.background,
                          prefixIcon: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColor.secondaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: controller.isSearching.value
                              ? null
                              : controller.findReceiver,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.secondaryColor,
                            foregroundColor: AppColor.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: controller.isSearching.value
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColor.white,
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: AppText.h4.copyWith(color: AppColor.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Recipient',
                  style: AppText.h4.copyWith(color: AppColor.textPrimary),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColor.secondaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColor.secondaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.receiverName.value,
                              style: AppText.h4.copyWith(color: AppColor.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.receiverAccountNumber.value,
                              style: AppText.bodyMedium.copyWith(
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Amount',
                  style: AppText.h4.copyWith(color: AppColor.textPrimary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.shadow,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: controller.amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: (value) => controller.amount.value = value,
                        style: AppText.h1.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColor.textPrimary,
                        ),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          prefixStyle: AppText.h1.copyWith(
                            color: AppColor.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          hintText: '0.00',
                          hintStyle: AppText.h1.copyWith(
                            color: AppColor.textHint,
                            fontWeight: FontWeight.w800,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: AppColor.background),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ['25', '50', '100', '250']
                            .map(
                              (amount) {
                                final isSelected =
                                    controller.amount.value.trim() == amount;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () =>
                                      controller.selectAmount(amount),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColor.secondaryColor
                                          : AppColor.secondaryColor
                                              .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColor.secondaryColor
                                            : AppColor.secondaryColor
                                                .withValues(alpha: 0.2),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColor.secondaryColor
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      '\$$amount',
                                      style: AppText.bodyMedium.copyWith(
                                        color: isSelected
                                            ? AppColor.white
                                            : AppColor.secondaryColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.isSending.value
                        ? null
                        : controller.sendMoney,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.secondaryColor,
                      foregroundColor: AppColor.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: controller.isSending.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColor.white,
                            ),
                          )
                        : Text(
                            'Send Money',
                            style: AppText.h4.copyWith(color: AppColor.white),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: controller.resetReceiver,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.textPrimary,
                      side: const BorderSide(color: AppColor.textHint),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Change Receiver',
                      style: AppText.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      ),
                    ),
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

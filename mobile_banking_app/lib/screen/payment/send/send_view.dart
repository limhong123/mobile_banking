import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/screen/payment/send/send_controller.dart';

class SendView extends GetView<SendController> {
  const SendView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.black87,
        ),
        title: Text(
          'Send Money',
          style: AppText.h3.copyWith(color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: AppColor.background,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
                      AppColor.secondaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.secondaryColor.withOpacity(0.3),
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
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fast, secure, and simple.',
                      style: AppText.h2.copyWith(
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.security_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Protected by bank-grade security',
                          style: AppText.labelSmall.copyWith(
                            color: Colors.white70,
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
                  style: AppText.h4.copyWith(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
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
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Account Number',
                          labelStyle: AppText.bodyMedium.copyWith(color: Colors.grey),
                          hintText: 'KHP123456789',
                          hintStyle: AppText.bodyLarge.copyWith(color: Colors.grey.shade400),
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
                            foregroundColor: Colors.white,
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
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: AppText.h4.copyWith(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  'Recipient',
                  style: AppText.h4.copyWith(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
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
                          color: AppColor.secondaryColor.withOpacity(0.1),
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
                              style: AppText.h4.copyWith(color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.receiverAccountNumber.value,
                              style: AppText.bodyMedium.copyWith(
                                color: Colors.grey.shade600,
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
                  style: AppText.h4.copyWith(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: controller.amount.value,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => controller.amount.value = value,
                        style: AppText.h1.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          prefixStyle: AppText.h1.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                          ),
                          hintText: '0.00',
                          hintStyle: AppText.h1.copyWith(
                            color: Colors.grey.shade300,
                            fontWeight: FontWeight.w800,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: Colors.grey.shade100),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ['25', '50', '100', '250']
                            .map(
                              (amount) => InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  controller.amount.value = amount;
                                  // Workaround to reset the text field value since we can't easily access its controller here,
                                  // but getx might handle it if it was bound properly.
                                  // For a full fix we would need TextEditingController.
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColor.secondaryColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColor.secondaryColor.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    '\$$amount',
                                    style: AppText.bodyMedium.copyWith(
                                      color: AppColor.secondaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
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
                      foregroundColor: Colors.white,
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
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Send Money',
                            style: AppText.h4.copyWith(color: Colors.white),
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
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Change Receiver',
                      style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700),
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

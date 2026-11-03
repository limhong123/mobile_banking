import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/screen/auth/verify_otp/verify_otp_controller.dart';

class VerifyOtpView extends GetView<VerifyOtpViewController> {
  const VerifyOtpView({
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
          'ផ្ទៀងផ្ទាត់ OTP',
          style: AppText.h4.copyWith(color: AppColor.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: AppColor.white,
        surfaceTintColor: AppColor.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.textPrimary),
      ),
      body: SafeArea(
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              24,
            ),
            child: Column(
              children: [
                const SizedBox(
                  height: 32,
                ),

                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColor.secondaryColor.withValues(
                      alpha: 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 48,
                    color: AppColor.secondaryColor,
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                Text(
                  'បញ្ចូលលេខកូដ OTP',
                  textAlign: TextAlign.center,
                  style: AppText.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  'យើងបានផ្ញើលេខកូដ OTP ទៅលេខទូរស័ព្ទ',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMedium.copyWith(
                    color: AppColor.textSecondary,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Obx(
                  () => Text(
                    controller.maskedPhoneNumber,
                    style: AppText.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 32,
                ),

                TextFormField(
                  controller: controller.otpController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      6,
                    ),
                  ],
                  style: AppText.h2.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                    color: AppColor.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: AppText.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 12,
                      color: AppColor.textHint,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: AppColor.white,
                    prefixIcon: const Icon(
                      Icons.password_outlined,
                      color: AppColor.secondaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      borderSide: const BorderSide(
                        color: AppColor.background,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      borderSide: const BorderSide(
                        color: AppColor.secondaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: controller.validateOtp,
                  onFieldSubmitted: (_) {
                    if (!controller.isLoading.value) {
                      controller.verifyOtp();
                    }
                  },
                ),

                const SizedBox(
                  height: 28,
                ),

                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.secondaryColor,
                        foregroundColor: AppColor.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColor.white,
                              ),
                            )
                          : Text(
                              'ផ្ទៀងផ្ទាត់',
                              style: AppText.bodyLarge.copyWith(
                                color: AppColor.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 22,
                ),

                Obx(
                  () {
                    if (controller.secondsRemaining.value > 0) {
                      return Text(
                        'ផ្ញើ OTP ម្ដងទៀតក្នុង ${controller.secondsRemaining.value} វិនាទី',
                        style: AppText.bodySmall.copyWith(
                          color: AppColor.textSecondary,
                        ),
                      );
                    }

                    return TextButton.icon(
                      onPressed: controller.isResending.value
                          ? null
                          : controller.resendOtp,
                      icon: controller.isResending.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColor.secondaryColor,
                              ),
                            )
                          : const Icon(
                              Icons.refresh,
                              color: AppColor.secondaryColor,
                            ),
                      label: Text(
                        'ផ្ញើ OTP ម្ដងទៀត',
                        style: AppText.bodySmall.copyWith(
                          color: AppColor.secondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(
                  height: 12,
                ),

                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: Text(
                    'កែលេខទូរស័ព្ទ',
                    style: AppText.bodySmall.copyWith(
                      color: AppColor.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

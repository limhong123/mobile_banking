import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/screen/auth/login/login_controller.dart';

class LoginView extends GetView<LoginViewController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  Image.asset(
                    'lib/app/assets/images/logo.png',
                    width: 200,
                    height: 200,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Sign in to continue to your mobile banking account.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyMedium.copyWith(
                      color: AppColor.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  TextFormField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: AppText.bodyMedium.copyWith(color: AppColor.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: AppText.bodyMedium.copyWith(color: AppColor.textSecondary),
                      hintText: 'Enter your phone number',
                      hintStyle: AppText.bodyMedium.copyWith(color: AppColor.textHint),
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColor.secondaryColor),
                      filled: true,
                      fillColor: AppColor.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColor.background),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColor.secondaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: controller.validatePhone,
                  ),

                  const SizedBox(height: 18),

                  Obx(
                    () => TextFormField(
                      controller: controller.pinController,
                      obscureText: controller.isPinHidden.value,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(6),
                      ],
                      textInputAction: TextInputAction.done,
                      style: AppText.bodyMedium.copyWith(color: AppColor.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        labelStyle: AppText.bodyMedium.copyWith(color: AppColor.textSecondary),
                        hintText: 'Enter your PIN',
                        hintStyle: AppText.bodyMedium.copyWith(color: AppColor.textHint),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColor.secondaryColor),
                        suffixIcon: IconButton(
                          onPressed: controller.togglePinVisibility,
                          icon: Icon(
                            controller.isPinHidden.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColor.textSecondary,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColor.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColor.background),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColor.secondaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: controller.validatePin,
                      onFieldSubmitted: (_) {
                        if (!controller.isLoading.value) {
                          controller.login();
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.secondaryColor,
                          foregroundColor: AppColor.white,
                          disabledBackgroundColor: AppColor.secondaryColor.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColor.white,
                                ),
                              )
                            : Text(
                                'Sign In',
                                style: AppText.bodyLarge.copyWith(
                                  color: AppColor.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppText.bodyMedium.copyWith(color: AppColor.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.offNamed(AppRoutes.register);
                        },
                        child: Text(
                          'Create Account',
                          style: AppText.bodyMedium.copyWith(
                            color: AppColor.secondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

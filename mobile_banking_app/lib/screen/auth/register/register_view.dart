import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/screen/auth/register/register_controller.dart';

class RegisterView extends GetView<RegisterViewController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/app/assets/images/logo.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Create your account to start using mobile banking.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyMedium.copyWith(
                      color: AppColor.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildField(
                    controller: controller.firstNameController,
                    label: 'First Name',
                    hint: 'Enter your first name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      return controller.validateRequired(
                        value,
                        'First name',
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildField(
                    controller: controller.lastNameController,
                    label: 'Last Name',
                    hint: 'Enter your last name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      return controller.validateRequired(
                        value,
                        'Last name',
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  _buildField(
                    controller: controller.phoneController,
                    label: 'Phone Number',
                    hint: 'Example: 012345678',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: controller.validatePhone,
                  ),

                  const SizedBox(height: 18),

                  Obx(
                    () => TextFormField(
                      controller: controller.pinController,
                      obscureText: controller.isPinHidden.value,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      style: AppText.bodyMedium.copyWith(color: AppColor.textPrimary),
                      decoration: _inputDecoration(
                        label: 'PIN',
                        hint: 'Create your PIN',
                        icon: Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: controller.togglePinVisibility,
                          icon: Icon(
                            controller.isPinHidden.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ),
                      validator: controller.validatePin,
                      onFieldSubmitted: (_) {
                        if (!controller.isLoading.value) {
                          controller.register();
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
                            : controller.register,
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
                                'Create Account',
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
                        'Already have an account?',
                        style: AppText.bodyMedium.copyWith(color: AppColor.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.offNamed(
                            AppRoutes.login,
                          );
                        },
                        child: Text(
                          'Sign In',
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      style: AppText.bodyMedium.copyWith(color: AppColor.textPrimary),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppText.bodyMedium.copyWith(color: AppColor.textSecondary),
      hintText: hint,
      hintStyle: AppText.bodyMedium.copyWith(color: AppColor.textHint),
      prefixIcon: Icon(icon, color: AppColor.secondaryColor),
      filled: true,
      fillColor: AppColor.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColor.background,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColor.secondaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColor.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColor.red,
          width: 1.5,
        ),
      ),
    );
  }
}

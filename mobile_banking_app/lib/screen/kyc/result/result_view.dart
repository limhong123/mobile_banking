import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/screen/kyc/result/result_controller.dart';

class ResultView extends GetView<ResultController> {
  const ResultView({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,
      body: SafeArea(
        child: Obx(
          () => Padding(
            padding: const EdgeInsets.all(
              24,
            ),
            child: Column(
              children: [
                const Spacer(),

                _statusIcon(),

                const SizedBox(
                  height: 28,
                ),

                Text(
                  controller.title,
                  textAlign: TextAlign.center,
                  style: AppText.h2.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.textPrimary,
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                Text(
                  controller.description,
                  textAlign: TextAlign.center,
                  style: AppText.bodyMedium.copyWith(
                    height: 1.6,
                    color: AppColor.textSecondary,
                  ),
                ),

                if (controller.matchScore.value > 0) ...[
                  const SizedBox(
                    height: 22,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(
                        16,
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
                    child: Column(
                      children: [
                        Text(
                          'Face Match Score',
                          style: AppText.labelSmall.copyWith(
                            color: AppColor.textHint,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          controller.matchScore.value.toStringAsFixed(
                            2,
                          ),
                          style: AppText.h3.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (controller.isApproved &&
                    (controller.nidNumber.value.isNotEmpty ||
                        controller.fullName.value.isNotEmpty)) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColor.background),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined,
                                size: 18, color: AppColor.secondaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Identity Information',
                              style: AppText.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColor.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (controller.nidNumber.value.isNotEmpty)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('NID Number',
                                  style: AppText.bodySmall.copyWith(
                                      color: AppColor.textSecondary)),
                              Text(controller.nidNumber.value,
                                  style: AppText.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.textPrimary)),
                            ],
                          ),
                        if (controller.nidNumber.value.isNotEmpty &&
                            controller.fullName.value.isNotEmpty)
                          const Divider(height: 16, color: AppColor.background),
                        if (controller.fullName.value.isNotEmpty)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Name on NID',
                                  style: AppText.bodySmall.copyWith(
                                      color: AppColor.textSecondary)),
                              Text(controller.fullName.value,
                                  style: AppText.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.textPrimary)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // =================================================
                // APPROVED
                // =================================================

                if (controller.isApproved)
                  ElevatedButton.icon(
                    onPressed: controller.goToLogin,
                    icon: const Icon(
                      Icons.login_rounded,
                    ),
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
                    label: Text(
                      'ទៅកាន់ Login',
                      style: AppText.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColor.white,
                      ),
                    ),
                  )

                // =================================================
                // REJECTED
                // =================================================

                else
                  ElevatedButton.icon(
                    onPressed: controller.retryVerification,
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
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
                    label: Text(
                      'ធ្វើ KYC ម្តងទៀត',
                      style: AppText.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColor.white,
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

  Widget _statusIcon() {
    if (controller.isApproved) {
      return _circleIcon(
        icon: Icons.check_rounded,
        background: AppColor.primaryColor.withValues(
          alpha: 0.14,
        ),
        foreground: AppColor.primaryColor,
      );
    }

    return _circleIcon(
      icon: Icons.close_rounded,
      background: AppColor.red.withValues(
        alpha: 0.12,
      ),
      foreground: AppColor.red,
    );
  }

  Widget _circleIcon({
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 62,
        color: foreground,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/app/routes/app_route.dart';

part 'scan_khqr_binding.dart';
part 'scan_khqr_controller.dart';

class ScanKhqrView extends GetView<ScanKhqrViewController> {
  const ScanKhqrView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'KHQR Payment',
          style: AppText.h3.copyWith(
            color: AppColor.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColor.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColor.textPrimary, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColor.secondaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 64,
                    color: AppColor.secondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Scan any KHQR Code',
                style: AppText.h2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pay seamlessly at merchants across Cambodia or transfer money instantly via Bakong KHQR.',
                textAlign: TextAlign.center,
                style: AppText.bodyMedium.copyWith(
                  color: AppColor.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(20),
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
                    _buildFeatureRow(
                      icon: Icons.flash_on_rounded,
                      title: 'Instant Settlement',
                      desc: 'Real-time transfers with zero delay',
                    ),
                    const Divider(height: 24, color: AppColor.background),
                    _buildFeatureRow(
                      icon: Icons.security_rounded,
                      title: 'Bank-Grade Security',
                      desc: 'Protected by national KHQR encryption',
                    ),
                    const Divider(height: 24, color: AppColor.background),
                    _buildFeatureRow(
                      icon: Icons.storefront_rounded,
                      title: 'Supported Everywhere',
                      desc: 'Accepted at thousands of shops & restaurants',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: controller.goToScanner,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text('Open QR Scanner', style: AppText.bodyLarge.copyWith(color: AppColor.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.secondaryColor,
                    foregroundColor: AppColor.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: controller.goToMyQr,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: Text('Show My KHQR', style: AppText.bodyLarge.copyWith(color: AppColor.secondaryColor, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.secondaryColor,
                    side: const BorderSide(color: AppColor.secondaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String title, required String desc}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColor.primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColor.primaryColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppText.labelSmall.copyWith(
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

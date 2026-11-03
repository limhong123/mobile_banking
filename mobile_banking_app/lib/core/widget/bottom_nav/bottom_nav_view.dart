import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/core/widget/bottom_nav/bottom_nav_controller.dart';
import 'package:mobile_banking_app/screen/analyst/analys_date/analys_date_controller.dart';
import 'package:mobile_banking_app/screen/home/home_controller.dart';
import 'package:mobile_banking_app/screen/profile/profile_controller.dart';
import 'package:mobile_banking_app/screen/saving/saving_controller.dart';

part 'bottom_nav_binding.dart';

class BottomNavView extends GetView<BottomNavViewController> {
  const BottomNavView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BottomNavViewController>(
      builder: (controller) {
        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: controller.currentIndex,
            children: controller.screens,
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(left: 18, right: 18, bottom: 16),
              height: 65,
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    currentIndex: controller.currentIndex,
                    onTap: controller.onMenuTap,
                  ),
                  _buildNavItem(
                    icon: Icons.savings_rounded,
                    label: 'Savings',
                    index: 1,
                    currentIndex: controller.currentIndex,
                    onTap: controller.onMenuTap,
                  ),
                  _buildNavItem(
                    icon: Icons.analytics_rounded,
                    label: 'Analytics',
                    index: 2,
                    currentIndex: controller.currentIndex,
                    onTap: controller.onMenuTap,
                  ),
                  _buildNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    index: 3,
                    currentIndex: controller.currentIndex,
                    onTap: controller.onMenuTap,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required Function(int) onTap,
  }) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.secondaryColor.withValues(alpha: 0.1)
              : AppColor.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColor.secondaryColor : AppColor.textHint,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.bodySmall.copyWith(
                  color: AppColor.secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

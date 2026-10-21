import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/screen/home/home_controller.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class HomeView extends GetView<HomeViewController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderAccount(),
                const SizedBox(height: 24),
                _CardBill(),
                const SizedBox(height: 32),
                Text(
                  'Services',
                  style: AppText.h3.copyWith(fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                ),
                const SizedBox(height: 16),
                _GridMenu(),
                const SizedBox(height: 32),
                Text(
                  'Promotions',
                  style: AppText.h3.copyWith(fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                ),
                const SizedBox(height: 16),
                _Slider(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _Slider() {
    return Stack(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
           color: AppColor.primaryColor
          ),
          child: CarouselSlider(
            options: CarouselOptions(
              autoPlay: true,
              viewportFraction: 1.0,
              autoPlayInterval: const Duration(seconds: 4),
              onPageChanged: (index, reason) {
                controller.onPageChanged(index);
              },
            ),
            items: controller.images.map((path) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  path,
                  
                  width: double.infinity,
                ),
              );
            }).toList(),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 0,
          left: 0,
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: controller.images.asMap().entries.map((entry) {
                bool isActive = controller.current.value == entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 24 : 8,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    color: isActive ? AppColor.secondaryColor : AppColor.white.withOpacity(0.6),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _HeaderAccount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColor.primaryColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 24, 
                backgroundColor: AppColor.white,
                child: Icon(Icons.person, size: 28, color: AppColor.primaryColor),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning,',
                  style: AppText.bodySmall.copyWith(color: AppColor.textSecondary),
                ),
                const SizedBox(height: 2),
                Obx(
                  () => Text(
                    controller.user.value?.fullName ?? 'Welcome!',
                    style: AppText.h4.copyWith(
                      color: AppColor.primaryColor, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _actionButton(
              icon: Icons.qr_code_scanner_rounded,
              onTap: () => Get.toNamed(AppRoutes.myQr),
            ),
            const SizedBox(width: 12),
            _actionButton(
              icon: Icons.notifications_none_rounded,
              onTap: () => Get.toNamed(AppRoutes.transactionHistory),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColor.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 24, color: AppColor.primaryColor),
      ),
    );
  }

  Widget _GridMenu() {
    return Obx(() => ReorderableGridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: controller.menuItems.length,
      onReorder: controller.onReorder,
      dragStartBehavior: DragStartBehavior.start,
      itemBuilder: (context, index) {
        final item = controller.menuItems[index];
        return Container(
          key: ValueKey(item['route']),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColor.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: AppColor.transparent,
            child: InkWell(
              onTap: () => controller.onLockedMenuTap(item['route']),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColor.primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item['icon'], color: AppColor.primaryColor, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['label'], 
                    style: AppText.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ));
  }

  Widget _CardBill() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColor.primaryColor,
            AppColor.primaryColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background abstract shapes
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: AppColor.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -30,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColor.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppColor.white.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Balance',
                      style: AppText.bodyMedium.copyWith(color: AppColor.white.withOpacity(0.85)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColor.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColor.white),
                          const SizedBox(width: 6),
                          Text(
                            controller.currentDate,
                            style: AppText.bodySmall.copyWith(color: AppColor.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Text(
                    '\$ ${controller.balance.value.toStringAsFixed(2)}',
                    style: AppText.h1.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColor.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expense',
                          style: AppText.bodySmall.copyWith(color: AppColor.white.withOpacity(0.85)),
                        ),
                        const SizedBox(height: 6),
                        Obx(
                          () => Text(
                            '- \$ ${controller.expense.value.toStringAsFixed(2)}',
                            style: AppText.h4.copyWith(
                              color: AppColor.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColor.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.trending_down_rounded, color: AppColor.white, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

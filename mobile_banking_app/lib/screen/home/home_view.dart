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
      appBar: AppBar(
        actions: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.transactionHistory);
                },
                icon: Icon(Icons.notifications, size: 28),
              ),
              IconButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.myQr);
                },
                icon: Icon(Icons.qr_code_2_rounded, size: 28),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _HeaderAccount(),
              SizedBox(height: 16),
              _CardBill(),
              SizedBox(height: 30),
              _GridMenu(),
              SizedBox(height: 20),
              _Slider(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _Slider() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColor.secondaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: CarouselSlider(
            options: CarouselOptions(
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 1),
              onPageChanged: (index, reason) {
                controller.onPageChanged(index);
              },
            ),
            items: controller.images.map((path) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(path, fit: BoxFit.cover),
              );
            }).toList(),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          left: 0,
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: controller.images.asMap().entries.map((entry) {
                return Container(
                  width: controller.current == entry.key ? 12 : 8,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 4.0,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.current == entry.key
                        ? Colors.white
                        : Colors.white54,
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
      children: [
        CircleAvatar(radius: 26, child: Icon(Icons.person, size: 30)),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => Text(
                controller.user.value?.fullName ?? '',
                style: AppText.h4.copyWith(color: AppColor.secondaryColor),
              ),
            ),
            Text(
              'Good Morning',
              style: AppText.bodySmall.copyWith(color: AppColor.secondaryColor),
            ),
          ],
        ),
      ],
    );
  }

  // home_view.dart
Widget _GridMenu() {
  return Obx(() => ReorderableGridView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1,
    ),
    itemCount: controller.menuItems.length,
    onReorder: controller.onReorder,
    dragStartBehavior: DragStartBehavior.start, // ចាប់ផ្តើមអូសពេលចុចជាប់ (long press)
    itemBuilder: (context, index) {
  final item = controller.menuItems[index];
  return ClipRRect(
    key: ValueKey(item['route']), // key moves to the outermost widget
    borderRadius: BorderRadius.circular(12),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.onLockedMenuTap(item['route']),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColor.secondaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColor.secondaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'], color: AppColor.secondaryColor, size: 22),
              ),
              SizedBox(height: 8),
              Text(item['label'], style: AppText.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    ),
  );
},
  ));
}

  Widget _CardBill() {
    return Container(
      padding: EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.secondaryColor,
            AppColor.secondaryColor.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.secondaryColor.withOpacity(0.35),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today Bill',
                style: AppText.h3.copyWith(color: Colors.white),
              ),
              Text(
                controller.currentDate,
                style: AppText.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              children: [
                // Balance
                Expanded(
                  child: Obx(
                    () => _AmountBlock(
                      icon: Icons.account_balance_rounded,
                      iconBg: Colors.white.withOpacity(0.2),
                      iconColor: Colors.white,
                      label: 'Balance',
                      amount:
                          '\$ ${controller.balance.value.toStringAsFixed(2)}',
                    ),
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withOpacity(0.3),
                ),
                // Transaction
                Expanded(
                  child: Obx(
                    () => _AmountBlock(
                      icon: Icons.trending_down_rounded,
                      iconBg: Colors.white.withOpacity(0.2),
                      iconColor: Colors.redAccent.shade100,
                      label: 'Expense',
                      amount:
                          '- \$ ${controller.expense.value.toStringAsFixed(2)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _AmountBlock({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String amount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: AppText.bodySmall.copyWith(color: Colors.white70),
            ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          amount,
          style: AppText.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

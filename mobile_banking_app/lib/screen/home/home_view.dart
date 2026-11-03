import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/app/routes/app_route.dart';
import 'package:mobile_banking_app/core/api/config.dart';
import 'package:mobile_banking_app/screen/home/home_controller.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class HomeView extends GetView<HomeViewController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.onRefresh,
          color: AppColor.secondaryColor,
          backgroundColor: AppColor.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderAccount(),
                const SizedBox(height: 20),
                _buildCardBill(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 28),
                _buildServicesHeader(),
                const SizedBox(height: 14),
                _buildGridMenu(),
                const SizedBox(height: 28),
                Text(
                  'Special Offers',
                  style: AppText.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _buildSlider(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // HEADER ACCOUNT
  // =====================================================

  Widget _buildHeaderAccount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // User Avatar & Name
        Expanded(
          child: GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.profile),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Obx(() {
                  final photo = controller.user.value?.profilePhoto;
                  final hasPhoto = photo != null && photo.isNotEmpty;

                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColor.secondaryColor.withValues(alpha: 0.15),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? Image.network(
                              '${Config.instance.baseUrl}/$photo',
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => _fallbackAvatar(),
                            )
                          : _fallbackAvatar(),
                    ),
                  );
                }),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.greetingText,
                        style: AppText.bodySmall.copyWith(
                          color: AppColor.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(
                        () => Text(
                          controller.user.value?.fullName ?? 'Welcome!',
                          style: AppText.h3.copyWith(
                            color: AppColor.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Icons (My QR & Notifications)
        Row(
          children: [
            _buildIconButton(
              icon: Icons.qr_code_2_rounded,
              tooltip: 'My QR',
              onTap: () => Get.toNamed(AppRoutes.myQr),
            ),
            const SizedBox(width: 10),
            _buildIconButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              hasBadge: true,
              onTap: () => Get.toNamed(AppRoutes.transactionHistory),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: AppColor.secondaryColor.withValues(alpha: 0.08),
      child: const Icon(
        Icons.person_rounded,
        size: 26,
        color: AppColor.secondaryColor,
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return Material(
      color: AppColor.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColor.shadow.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColor.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: AppColor.secondaryColor),
              if (hasBadge)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColor.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColor.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // BALANCE CARD
  // =====================================================

  Widget _buildCardBill() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            AppColor.secondaryColor,
            Color(0xFF07243B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.secondaryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Background abstract geometric glows
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.primaryColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -35,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Account label + Date pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColor.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Main Account',
                          style: AppText.bodySmall.copyWith(
                            color: AppColor.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColor.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColor.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            controller.currentDate,
                            style: AppText.labelSmall.copyWith(
                              color: AppColor.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Balance Label + Eye Toggle
                Row(
                  children: [
                    Text(
                      'Available Balance',
                      style: AppText.labelSmall.copyWith(
                        color: AppColor.white.withValues(alpha: 0.7),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () => GestureDetector(
                        onTap: controller.toggleBalanceVisibility,
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          controller.isBalanceHidden.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColor.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Balance Value Display
                Obx(
                  () => controller.isLoadingBalance.value
                      ? const SizedBox(
                          height: 38,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColor.white,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          controller.formattedBalance,
                          style: AppText.h1.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColor.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Divider line with subtle glow
                Container(
                  height: 1,
                  color: AppColor.white.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 14),

                // Bottom Row: Today Expense + Card Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today Expense',
                          style: AppText.labelSmall.copyWith(
                            color: AppColor.white.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            controller.formattedExpense,
                            style: AppText.bodyMedium.copyWith(
                              color: const Color(0xFFFF8A80),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColor.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.contactless_rounded,
                            size: 18,
                            color: AppColor.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'USD',
                            style: AppText.labelSmall.copyWith(
                              color: AppColor.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
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

  // =====================================================
  // QUICK ACTIONS BAR
  // =====================================================

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'Send',
        'icon': Icons.arrow_upward_rounded,
        'route': AppRoutes.send,
      },
      {
        'title': 'Receive',
        'icon': Icons.arrow_downward_rounded,
        'route': AppRoutes.cashReceive,
      },
      {
        'title': 'Scan QR',
        'icon': Icons.qr_code_scanner_rounded,
        'route': AppRoutes.scanQr,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: actions.map((act) {
          return Expanded(
            child: InkWell(
              onTap: () => controller.onLockedMenuTap(act['route'] as String),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColor.secondaryColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        act['icon'] as IconData,
                        color: AppColor.secondaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      act['title'] as String,
                      style: AppText.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =====================================================
  // SERVICES HEADER & GRID MENU
  // =====================================================

  Widget _buildServicesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Services',
          style: AppText.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.drag_indicator_rounded,
              size: 16,
              color: AppColor.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Hold to reorder',
              style: AppText.labelSmall.copyWith(
                color: AppColor.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridMenu() {
    return Obx(
      () => ReorderableGridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.98,
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
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColor.shadow.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColor.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: AppColor.transparent,
              child: InkWell(
                onTap: () => controller.onLockedMenuTap(item['route'] as String),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: AppColor.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          item['label'] as String,
                          style: AppText.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // PROMOTIONS SLIDER
  // =====================================================

  Widget _buildSlider() {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 160,
            autoPlay: true,
            viewportFraction: 1.0,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 700),
            onPageChanged: (index, reason) {
              controller.onPageChanged(index);
            },
          ),
          items: controller.promoBanners.map((promo) {
            final List<Color> gradientColors =
                promo['gradient'] as List<Color>;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.antiAlias,
                children: [
                  Positioned(
                    right: -15,
                    bottom: -20,
                    child: Icon(
                      promo['icon'] as IconData,
                      size: 110,
                      color: AppColor.white.withValues(alpha: 0.12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            promo['tag'] as String,
                            style: AppText.labelSmall.copyWith(
                              color: AppColor.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          promo['title'] as String,
                          style: AppText.h3.copyWith(
                            color: AppColor.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(right: 50),
                          child: Text(
                            promo['subtitle'] as String,
                            style: AppText.bodySmall.copyWith(
                              color: AppColor.white.withValues(alpha: 0.85),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: controller.promoBanners.asMap().entries.map((entry) {
              final bool isActive = controller.current.value == entry.key;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 22 : 7,
                height: 6.0,
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: isActive
                      ? AppColor.secondaryColor
                      : AppColor.secondaryColor.withValues(alpha: 0.2),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

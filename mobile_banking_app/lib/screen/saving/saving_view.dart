import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/core/model/saving_model.dart';
import 'package:mobile_banking_app/screen/saving/saving_controller.dart';
import 'package:mobile_banking_app/screen/saving/widgets/create_saving_sheet.dart';

class SavingView extends GetView<SavingController> {
  const SavingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColor.scaffoldBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Saving Account',
          style: AppText.h3.copyWith(
            color: AppColor.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: controller.onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: AppColor.secondaryColor),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColor.secondaryColor),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.onRefresh,
          color: AppColor.secondaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSavingsOverviewCard(context),
                const SizedBox(height: 18),
                _buildRateBanner(),
                const SizedBox(height: 24),
                _buildTabs(),
                const SizedBox(height: 16),
                Obx(() {
                  if (controller.selectedTab.value == 0) {
                    return _buildActiveSavingsList();
                  } else {
                    return _buildCompletedSavingsList();
                  }
                }),
              ],
            ),
          ),
        );
      }),
    );
  }

  // =====================================================
  // SAVINGS OVERVIEW CARD
  // =====================================================

  Widget _buildSavingsOverviewCard(BuildContext context) {
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
          // Background circle accents
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Label + Piggy icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.savings_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Locked Savings',
                          style: AppText.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 14,
                            color: Color(0xFF34D399),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Earn Interest',
                            style: AppText.labelSmall.copyWith(
                              color: const Color(0xFF34D399),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Large Total Balance
                Obx(
                  () => Text(
                    '\$ ${NumberFormat('#,##0.00').format(controller.totalSavings.value)}',
                    style: AppText.h1.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Divider line
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 14),

                // Bottom row: Earned Interest & Start Saving Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guaranteed Interest',
                          style: AppText.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            '+ \$ ${NumberFormat('#,##0.00').format(controller.totalEarnedInterest.value)}',
                            style: AppText.bodyMedium.copyWith(
                              color: const Color(0xFF34D399),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Deposit Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        controller.depositAmountController.clear();
                        controller.recalculatePreview();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => const CreateSavingSheet(),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Start Saving',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
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
  // RATE ANNOUNCEMENT BANNER
  // =====================================================

  Widget _buildRateBanner() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColor.secondaryColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColor.shadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.percent_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'High-Yield Fixed Savings',
                    style: AppText.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Obx(() {
                    if (controller.terms.isEmpty) {
                      return Text(
                        'Guaranteed return on deposits',
                        style: AppText.labelSmall.copyWith(
                          color: const Color(0xFF047857),
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    final bestRate = (controller.bestRateAnnual * 100).toStringAsFixed(2);
                    return Text(
                      'Earn up to $bestRate% p.a. • ${controller.terms.length} terms available',
                      style: AppText.labelSmall.copyWith(
                        color: const Color(0xFF047857),
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Min \$${controller.minDeposit.value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // TABS
  // =====================================================

  Widget _buildTabs() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => controller.selectedTab.value = 0,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: controller.selectedTab.value == 0
                        ? AppColor.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: controller.selectedTab.value == 0
                        ? [
                            BoxShadow(
                              color: AppColor.shadow,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 15,
                        color: controller.selectedTab.value == 0
                            ? AppColor.secondaryColor
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active & Locked (${controller.activeSavings.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: controller.selectedTab.value == 0
                              ? AppColor.secondaryColor
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => controller.selectedTab.value = 1,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: controller.selectedTab.value == 1
                        ? AppColor.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: controller.selectedTab.value == 1
                        ? [
                            BoxShadow(
                              color: AppColor.shadow,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 15,
                        color: controller.selectedTab.value == 1
                            ? AppColor.secondaryColor
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Completed (${controller.completedSavings.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: controller.selectedTab.value == 1
                              ? AppColor.secondaryColor
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // ACTIVE SAVINGS LIST
  // =====================================================

  Widget _buildActiveSavingsList() {
    if (controller.activeSavings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.secondaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.savings_outlined,
                size: 40,
                color: AppColor.secondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Savings Deposit',
              style: AppText.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Deposit money into your saving account to lock funds and start earning high interest return.',
              textAlign: TextAlign.center,
              style: AppText.bodySmall.copyWith(
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.activeSavings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = controller.activeSavings[index];
        return _buildSavingItemCard(item);
      },
    );
  }

  // =====================================================
  // SAVING ITEM CARD
  // =====================================================

  Widget _buildSavingItemCard(SavingItemModel item) {
    final isLocked = !item.isMatured;
    final maturityDateStr = item.maturityDate != null
        ? DateFormat('MMM d, yyyy').format(item.maturityDate!)
        : 'Maturity';

    final planTitle = item.label.isNotEmpty
        ? item.label
        : (item.durationMonths >= 12 && item.durationMonths % 12 == 0
            ? '${item.durationMonths ~/ 12} Year${item.durationMonths ~/ 12 > 1 ? 's' : ''}'
            : '${item.durationMonths} Months');

    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked
              ? const Color(0xFFFDE68A)
              : const Color(0xFFA7F3D0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isLocked
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                            size: 18,
                            color: isLocked ? const Color(0xFFD97706) : const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B3B60),
                              ),
                            ),
                            Text(
                              item.savingId,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLocked
                            ? const Color(0xFFFFFBEB)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLocked
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLocked ? Icons.lock_rounded : Icons.check_circle_rounded,
                            size: 12,
                            color: isLocked ? const Color(0xFFB45309) : const Color(0xFF047857),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLocked ? 'LOCKED' : 'MATURED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isLocked ? const Color(0xFFB45309) : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Financial Numbers Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Principal Saved',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${NumberFormat('#,##0.00').format(item.principalAmount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.formattedRate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B3B60),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Earned Return',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+\$${NumberFormat('#,##0.00').format(item.expectedInterest)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lock Info & Maturity Date
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Matures: $maturityDateStr',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isLocked
                            ? '${item.daysRemaining} days left'
                            : 'Ready for payout',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? const Color(0xFFD97706) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action: Withdraw Button (Disabled/Locked if currently saving!)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isLocked ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isLocked
                        ? '🔒 User cannot withdraw money while currently saving'
                        : '🎉 Savings matured! Total: \$${item.totalPayout.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isLocked ? const Color(0xFF92400E) : const Color(0xFF166534),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => controller.handleWithdraw(item),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey.shade200 : const Color(0xFF0B3B60),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLocked ? Icons.lock_outline_rounded : Icons.arrow_downward_rounded,
                          size: 14,
                          color: isLocked ? Colors.grey.shade600 : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLocked ? 'Locked' : 'Withdraw',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isLocked ? Colors.grey.shade600 : Colors.white,
                          ),
                        ),
                      ],
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

  // =====================================================
  // COMPLETED SAVINGS LIST
  // =====================================================

  Widget _buildCompletedSavingsList() {
    if (controller.completedSavings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 40,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              'No Completed Savings Yet',
              style: AppText.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Completed savings and payout history will appear here once matured deposits are withdrawn.',
              textAlign: TextAlign.center,
              style: AppText.bodySmall.copyWith(
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.completedSavings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = controller.completedSavings[index];
        final payoutStr = '\$${NumberFormat('#,##0.00').format(item.totalPayout)}';
        final earnedStr = '+\$${NumberFormat('#,##0.00').format(item.expectedInterest)}';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: AppColor.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label.isNotEmpty
                          ? item.label
                          : '${item.durationMonths} Months Plan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Interest: $earnedStr (${item.formattedRate})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    payoutStr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B3B60),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Withdrawn',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

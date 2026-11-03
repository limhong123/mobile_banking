import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/core/model/saving_model.dart';
import 'package:mobile_banking_app/screen/saving/saving_controller.dart';

class CreateSavingSheet extends StatelessWidget {
  const CreateSavingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SavingController>();

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Earning Interest',
                        style: AppText.h3.copyWith(
                          color: AppColor.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a term to lock money and earn guaranteed return',
                        style: AppText.labelSmall.copyWith(
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey.shade500,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dynamic Term Selector (Admin Controlled)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Term',
                  style: AppText.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                Obx(() {
                  final sel = controller.selectedTerm.value;
                  if (sel == null) return const SizedBox.shrink();
                  return Text(
                    'Min: \$${sel.minAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),

            // Dynamic Terms - Horizontal Scrollable Chips/Cards
            Obx(() {
              if (controller.terms.isEmpty) {
                return Container(
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    'Loading terms...',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                );
              }

              final bestId = controller.bestRateTermId;
              final selectedId = controller.selectedTerm.value?.id;

              return SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.terms.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final term = controller.terms[index];
                    final isSelected = term.id == selectedId;
                    final isBest = term.id == bestId;

                    return _buildDynamicTermCard(
                      term: term,
                      isSelected: isSelected,
                      isBestRate: isBest,
                      onTap: () => controller.selectTerm(term),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 20),

            // Amount Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deposit Amount',
                  style: AppText.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
                Obx(
                  () => Text(
                    'Balance: \$${NumberFormat('#,##0.00').format(controller.walletBalance.value)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            TextField(
              controller: controller.depositAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B3B60),
              ),
              onChanged: (_) => controller.recalculatePreview(),
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '\$',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B3B60),
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                hintText: '0.00',
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColor.secondaryColor, width: 2),
                ),
              ),
            ),
            Obx(() {
              if (controller.amountError.value.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          controller.amountError.value,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 10),

            // Quick Preset Amount Chips (+50, +100, +500, Max)
            Row(
              children: [
                ...[50, 100, 500].map((amt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('+\$$amt'),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => controller.addAmount(amt.toDouble()),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: const Text('Max'),
                    backgroundColor: AppColor.secondaryColor.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColor.secondaryColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColor.secondaryColor),
                    ),
                    onPressed: () => controller.setMaxAmount(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Result Summary Card (Live Guaranteed Interest & Total)
            Obx(
              () {
                final term = controller.selectedTerm.value;
                final rateLabel = term != null
                    ? '${term.ratePercent.toStringAsFixed(2)}${term.unitLabel}'
                    : '${controller.currentAppliedRate.value}% p.a.';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B3B60), Color(0xFF0F4A75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.secondaryColor.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Applied Rate:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              rateLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Guaranteed Interest:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            '+\$${controller.calculatedInterest.value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Maturity Date:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            'Unlocks on: ${DateFormat('d MMM yyyy').format(controller.calculatedMaturityDate)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Colors.white24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total You Receive:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '\$${controller.calculatedTotalReturn.value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Friendly Lock Notice
            Row(
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 15,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Money cannot be withdrawn while saving. Unlocks on maturity.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Big Action Button
            Obx(
              () {
                final isEnabled = controller.isValidAmount.value &&
                    controller.selectedTerm.value != null &&
                    !controller.isSubmitting.value;

                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnabled ? const Color(0xFF10B981) : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isEnabled ? 2 : 0,
                    ),
                    onPressed: isEnabled ? () => controller.confirmAndSubmit() : null,
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Now & Earn Interest',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicTermCard({
    required SavingTermModel term,
    required bool isSelected,
    required bool isBestRate,
    required VoidCallback onTap,
  }) {
    final rateText = '${term.ratePercent.toStringAsFixed(2)}${term.unitLabel}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: const BoxConstraints(minWidth: 104),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.secondaryColor
              : (isBestRate ? const Color(0xFFECFDF5) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColor.secondaryColor
                : (isBestRate ? const Color(0xFFA7F3D0) : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColor.secondaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBestRate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'BEST RATE',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : const Color(0xFF15803D),
                  ),
                ),
              )
            else
              const SizedBox(height: 12),
            Text(
              term.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rateText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF34D399) : const Color(0xFF047857),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

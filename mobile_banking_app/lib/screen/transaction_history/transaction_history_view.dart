import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/core/model/transaction_model.dart';
import 'package:mobile_banking_app/screen/transaction_detail/transaction_detail_view.dart';
import 'package:mobile_banking_app/screen/transaction_history/transaction_history_controller.dart';

class TransactionHistoryView extends GetView<TransactionHistoryController> {
  const TransactionHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColor.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColor.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Transaction History',
          style: AppText.h3.copyWith(color: AppColor.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColor.secondaryColor),
          );
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColor.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: AppText.bodyMedium.copyWith(color: AppColor.textPrimary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: controller.getTransactions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.secondaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Try Again', style: AppText.bodyMedium.copyWith(color: AppColor.white)),
                ),
              ],
            ),
          );
        }

        if (controller.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppColor.textHint, size: 64),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: AppText.h4.copyWith(color: AppColor.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          color: AppColor.secondaryColor,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: controller.transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final transaction = controller.transactions[index];
              return _TransactionItem(transaction: transaction);
            },
          ),
        );
      }),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool incoming = transaction.isIncoming;
    final String date = transaction.createdAt == null
        ? ''
        : DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt!.toLocal());

    String title = transaction.counterpartyName;
    if (transaction.isDeposit) {
      title = 'Cash Deposit';
    }
    if (title.isEmpty) {
      title = transaction.type;
    }

    return Container(
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
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Get.to(() => TransactionDetailView(transactionId: transaction.transactionId));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: incoming ? AppColor.primaryColor.withValues(alpha: 0.1) : AppColor.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    incoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: incoming ? AppColor.primaryColor : AppColor.red,
                  ),
                ),
                const SizedBox(width: 16),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: AppText.labelSmall.copyWith(color: AppColor.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${incoming ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                      style: AppText.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: incoming ? AppColor.primaryColor : AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.status.toUpperCase(),
                      style: AppText.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: transaction.isSuccess ? AppColor.primaryColor : AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

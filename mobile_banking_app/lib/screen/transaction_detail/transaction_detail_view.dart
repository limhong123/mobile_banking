import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/core/model/transaction_model.dart';
import 'transaction_detail_controller.dart';

class TransactionDetailView extends StatefulWidget {
  final String transactionId;

  const TransactionDetailView({
    super.key,
    required this.transactionId,
  });

  @override
  State<TransactionDetailView> createState() =>
      _TransactionDetailViewState();
}

class _TransactionDetailViewState
    extends State<TransactionDetailView> {
  late final TransactionDetailController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.put(
      TransactionDetailController(
        transactionId: widget.transactionId,
      ),
      tag: widget.transactionId,
    );
  }

  @override
  void dispose() {
    Get.delete<TransactionDetailController>(
      tag: widget.transactionId,
    );

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: AppColor.textPrimary,
        ),
        title: Text(
          'Transaction Details',
          style: AppText.h4.copyWith(
            color: AppColor.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(
        () {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColor.secondaryColor),
            );
          }

          if (controller.errorMessage.value.isNotEmpty) {
            return _ErrorView(
              message: controller.errorMessage.value,
              onRetry: controller.getTransactionDetail,
            );
          }

          final TransactionModel? transaction =
              controller.transaction.value;

          if (transaction == null) {
            return Center(
              child: Text(
                'Transaction not found',
                style: AppText.bodyMedium.copyWith(color: AppColor.textSecondary),
              ),
            );
          }

          return _DetailBody(
            transaction: transaction,
          );
        },
      ),
    );
  }
}

// =========================================================
// DETAIL BODY
// =========================================================

class _DetailBody extends StatelessWidget {
  final TransactionModel transaction;

  const _DetailBody({
    required this.transaction,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool incoming =
        transaction.isIncoming;

    final String amountSign =
        incoming ? '+' : '-';

    final String formattedDate =
        _formatDate(
      transaction.createdAt,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(
        20,
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),

          // =================================================
          // TRANSACTION ICON
          // =================================================

          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: incoming
                  ? AppColor.primaryColor.withValues(
                      alpha: 0.10,
                    )
                  : AppColor.red.withValues(
                      alpha: 0.10,
                    ),
            ),
            child: Icon(
              _getIcon(),
              size: 36,
              color: incoming
                  ? AppColor.primaryColor
                  : AppColor.red,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // =================================================
          // TITLE
          // =================================================

          Text(
            _getTitle(),
            textAlign: TextAlign.center,
            style: AppText.h4.copyWith(
              color: AppColor.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // =================================================
          // AMOUNT
          // =================================================

          Text(
            '$amountSign'
            '${_currencySymbol()}'
            '${transaction.amount.toStringAsFixed(2)}',
            style: AppText.h1.copyWith(
              fontWeight: FontWeight.bold,
              color: incoming
                  ? AppColor.primaryColor
                  : AppColor.red,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // =================================================
          // STATUS
          // =================================================

          _StatusBadge(
            status: transaction.status,
          ),

          const SizedBox(
            height: 30,
          ),

          // =================================================
          // TRANSACTION INFORMATION
          // =================================================

          _SectionCard(
            title: 'Transaction Information',
            children: [
              _DetailRow(
                title: 'Transaction ID',
                value: transaction.transactionId,
              ),

              _divider(),

              _DetailRow(
                title: 'Type',
                value: _formatText(
                  transaction.type,
                ),
              ),

              _divider(),

              _DetailRow(
                title: 'Direction',
                value: transaction.isIncoming
                    ? 'Money In'
                    : 'Money Out',
              ),

              _divider(),

              _DetailRow(
                title: 'Date & Time',
                value: formattedDate,
              ),

              if (transaction.description.isNotEmpty) ...[
                _divider(),

                _DetailRow(
                  title: 'Description',
                  value: transaction.description,
                ),
              ],
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          // =================================================
          // SENDER INFORMATION
          // =================================================

          if (transaction.senderName.isNotEmpty ||
              transaction.senderAccountNumber.isNotEmpty) ...[
            _SectionCard(
              title: 'Sender Details',
              children: [
                if (transaction.senderName.isNotEmpty)
                  _DetailRow(
                    title: 'Sender Name',
                    value: transaction.senderName,
                  ),

                if (transaction.senderAccountNumber.isNotEmpty) ...[
                  _divider(),

                  _DetailRow(
                    title: 'Sender Account',
                    value: transaction.senderAccountNumber,
                  ),
                ],
              ],
            ),

            const SizedBox(
              height: 20,
            ),
          ],

          // =================================================
          // RECEIVER INFORMATION
          // =================================================

          if (transaction.receiverName.isNotEmpty ||
              transaction.receiverAccountNumber.isNotEmpty) ...[
            _SectionCard(
              title: 'Receiver Details',
              children: [
                if (transaction.receiverName.isNotEmpty)
                  _DetailRow(
                    title: 'Receiver Name',
                    value: transaction.receiverName,
                  ),

                if (transaction.receiverAccountNumber.isNotEmpty) ...[
                  _divider(),

                  _DetailRow(
                    title: 'Receiver Account',
                    value: transaction.receiverAccountNumber,
                  ),
                ],
              ],
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(
    DateTime? dateTime,
  ) {
    if (dateTime == null) {
      return '-';
    }

    try {
      final local = dateTime.toLocal();

      return DateFormat('yyyy-MM-dd • hh:mm a').format(local);
    } catch (_) {
      return dateTime.toString();
    }
  }

  IconData _getIcon() {
    if (transaction.isDeposit) {
      return Icons.account_balance_wallet_rounded;
    }

    if (transaction.type.toLowerCase().contains('qr')) {
      return Icons.qr_code_rounded;
    }

    return transaction.isIncoming
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
  }

  String _getTitle() {
    if (transaction.isDeposit) {
      return 'Cash Deposit';
    }

    final counterparty = transaction.counterpartyName;

    if (counterparty.trim().isNotEmpty) {
      return counterparty;
    }

    return _formatText(
      transaction.type,
    );
  }

  String _currencySymbol() {
    final currency = transaction.currency.toUpperCase();

    if (currency == 'USD') return '\$';

    if (currency == 'KHR') return '៛';

    return '$currency ';
  }

  String _formatText(
    String raw,
  ) {
    if (raw.isEmpty) {
      return '-';
    }

    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  Widget _divider() {
    return const Divider(
      height: 28,
      thickness: 1,
      color: AppColor.background,
    );
  }
}

// =========================================================
// SECTION CARD
// =========================================================

class _SectionCard extends StatelessWidget {
  final String title;

  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColor.shadow,
            blurRadius: 15,
            offset: const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColor.textPrimary,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          ...children,
        ],
      ),
    );
  }
}

// =========================================================
// DETAIL ROW
// =========================================================

class _DetailRow
    extends StatelessWidget {
  final String title;

  final String value;

  const _DetailRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: AppText.bodySmall.copyWith(
              color: AppColor.textSecondary,
            ),
          ),
        ),

        const SizedBox(
          width: 15,
        ),

        Expanded(
          flex: 6,
          child: Text(
            value.isEmpty
                ? '-'
                : value,
            textAlign: TextAlign.right,
            style: AppText.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================
// STATUS BADGE
// =========================================================

class _StatusBadge
    extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final String value =
        status.toLowerCase();

    Color color;

    IconData icon;

    String text;

    if (
      value == 'success' ||
      value == 'completed' ||
      value == 'approved'
    ) {
      color = AppColor.primaryColor;

      icon = Icons.check_circle_rounded;

      text = 'SUCCESS';
    } else if (
      value == 'failed' ||
      value == 'rejected'
    ) {
      color = AppColor.red;

      icon = Icons.cancel_rounded;

      text = 'FAILED';
    } else if (
      value == 'pending'
    ) {
      color = AppColor.secondaryColor;

      icon = Icons.access_time_rounded;

      text = 'PENDING';
    } else {
      color = AppColor.textSecondary;

      icon = Icons.info_outline_rounded;

      text = status.isEmpty
          ? 'UNKNOWN'
          : status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            text,
            style: AppText.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// ERROR VIEW
// =========================================================

class _ErrorView
    extends StatelessWidget {
  final String message;

  final Future<void> Function()
      onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: AppColor.red,
            ),

            const SizedBox(
              height: 15,
            ),

            Text(
              'Unable to load transaction',
              style: AppText.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColor.textPrimary,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.bodyMedium.copyWith(
                color: AppColor.textSecondary,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(
              onPressed: () {
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.secondaryColor,
                foregroundColor: AppColor.white,
              ),
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

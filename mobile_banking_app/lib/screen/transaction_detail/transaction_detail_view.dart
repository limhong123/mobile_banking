import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: const Color(
        0xffF7F8FA,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(
        () {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
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
            return const Center(
              child: Text(
                'Transaction not found',
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
                  ? Colors.green.withValues(
                      alpha: 0.10,
                    )
                  : Colors.red.withValues(
                      alpha: 0.10,
                    ),
            ),
            child: Icon(
              _getIcon(),
              size: 36,
              color: incoming
                  ? Colors.green
                  : Colors.red,
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
            style: const TextStyle(
              fontSize: 19,
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
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: incoming
                  ? Colors.green
                  : Colors.red,
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
                title: 'Amount',
                value:
                    '${_currencySymbol()}'
                    '${transaction.amount.toStringAsFixed(2)}',
              ),

              _divider(),

              _DetailRow(
                title: 'Currency',
                value: transaction.currency,
              ),

              _divider(),

              _DetailRow(
                title: 'Status',
                value: _formatText(
                  transaction.status,
                ),
              ),

              _divider(),

              _DetailRow(
                title: 'Date & Time',
                value: formattedDate,
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          // =================================================
          // TRANSFER DETAIL
          // =================================================

          if (transaction.isTransfer)
            _SectionCard(
              title: 'Transfer Detail',
              children: [
                if (
                  transaction
                      .counterpartyName
                      .isNotEmpty
                ) ...[
                  _DetailRow(
                    title:
                        transaction.isIncoming
                            ? 'From'
                            : 'To',
                    value:
                        transaction
                            .counterpartyName,
                  ),

                  _divider(),
                ],

                if (
                  transaction
                      .counterpartyAccount
                      .isNotEmpty
                ) ...[
                  _DetailRow(
                    title: 'Account Number',
                    value:
                        transaction
                            .counterpartyAccount,
                  ),

                  _divider(),
                ],

                if (
                  transaction
                      .senderName
                      .isNotEmpty
                ) ...[
                  _DetailRow(
                    title: 'Sender',
                    value:
                        transaction.senderName,
                  ),

                  _divider(),
                ],

                if (
                  transaction
                      .senderAccountNumber
                      .isNotEmpty
                ) ...[
                  _DetailRow(
                    title: 'Sender Account',
                    value:
                        transaction
                            .senderAccountNumber,
                  ),

                  _divider(),
                ],

                if (
                  transaction
                      .receiverName
                      .isNotEmpty
                ) ...[
                  _DetailRow(
                    title: 'Receiver',
                    value:
                        transaction.receiverName,
                  ),

                  _divider(),
                ],

                if (
                  transaction
                      .receiverAccountNumber
                      .isNotEmpty
                )
                  _DetailRow(
                    title: 'Receiver Account',
                    value:
                        transaction
                            .receiverAccountNumber,
                  ),
              ],
            ),

          // =================================================
          // DEPOSIT DETAIL
          // =================================================

          if (transaction.isDeposit) ...[
            _SectionCard(
              title: 'Deposit Detail',
              children: [
                _DetailRow(
                  title: 'Deposit Type',
                  value: 'Cash Deposit',
                ),

                if (
                  transaction
                      .agentName
                      .isNotEmpty
                ) ...[
                  _divider(),

                  _DetailRow(
                    title: 'Agent',
                    value:
                        transaction.agentName,
                  ),
                ],
              ],
            ),

            const SizedBox(
              height: 16,
            ),
          ],

          // =================================================
          // PAYMENT DETAIL
          // =================================================

          if (transaction.isPayment) ...[
            _SectionCard(
              title: 'Payment Detail',
              children: [
                _DetailRow(
                  title: 'Payment',
                  value:
                      transaction
                              .counterpartyName
                              .isEmpty
                          ? 'Payment'
                          : transaction
                              .counterpartyName,
                ),

                if (
                  transaction
                      .counterpartyAccount
                      .isNotEmpty
                ) ...[
                  _divider(),

                  _DetailRow(
                    title: 'Account',
                    value:
                        transaction
                            .counterpartyAccount,
                  ),
                ],
              ],
            ),

            const SizedBox(
              height: 16,
            ),
          ],

          if (transaction.isTransfer)
            const SizedBox(
              height: 16,
            ),

         

            
        ],
      ),
    );
  }

  // =======================================================
  // TITLE
  // =======================================================

  String _getTitle() {
    if (transaction.isDeposit) {
      if (
        transaction
            .agentName
            .isNotEmpty
      ) {
        return transaction.agentName;
      }

      return 'Cash Deposit';
    }

    if (transaction.isPayment) {
      if (
        transaction
            .counterpartyName
            .isNotEmpty
      ) {
        return transaction.counterpartyName;
      }

      return 'Payment';
    }

    if (
      transaction
          .counterpartyName
          .isNotEmpty
    ) {
      return transaction.counterpartyName;
    }

    if (
      transaction.isIncoming
    ) {
      return 'Money Received';
    }

    if (
      transaction.isOutgoing
    ) {
      return 'Money Sent';
    }

    return 'Transaction';
  }

  // =======================================================
  // ICON
  // =======================================================

  IconData _getIcon() {
    if (transaction.isDeposit) {
      return Icons
          .account_balance_wallet_outlined;
    }

    if (transaction.isPayment) {
      return Icons
          .payments_outlined;
    }

    if (transaction.isIncoming) {
      return Icons
          .south_west_rounded;
    }

    return Icons
        .north_east_rounded;
  }

  // =======================================================
  // CURRENCY
  // =======================================================

  String _currencySymbol() {
    final String currency =
        transaction.currency
            .toUpperCase();

    if (currency == 'USD') {
      return '\$';
    }

    if (currency == 'KHR') {
      return '៛';
    }

    return '$currency ';
  }

  // =======================================================
  // FORMAT DATE
  // =======================================================

  String _formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return '-';
    }

    return DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(
      date.toLocal(),
    );
  }

  // =======================================================
  // FORMAT TEXT
  // =======================================================

  String _formatText(
    String value,
  ) {
    if (value.isEmpty) {
      return '-';
    }

    final String cleanValue =
        value
            .replaceAll(
              '_',
              ' ',
            )
            .trim();

    if (cleanValue.isEmpty) {
      return '-';
    }

    return cleanValue
        .split(' ')
        .map(
          (word) {
            if (word.isEmpty) {
              return '';
            }

            return word[0]
                    .toUpperCase() +
                word
                    .substring(1)
                    .toLowerCase();
          },
        )
        .join(' ');
  }

  Widget _divider() {
    return Divider(
      height: 28,
      thickness: 1,
      color: Colors.grey.shade200,
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
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 15,
            offset: const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color:
                  Colors.grey.shade600,
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
            textAlign:
                TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
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
      color = Colors.green;

      icon =
          Icons.check_circle_rounded;

      text = 'SUCCESS';
    } else if (
      value == 'failed' ||
      value == 'rejected'
    ) {
      color = Colors.red;

      icon =
          Icons.cancel_rounded;

      text = 'FAILED';
    } else if (
      value == 'pending'
    ) {
      color = Colors.orange;

      icon =
          Icons.access_time_rounded;

      text = 'PENDING';
    } else {
      color = Colors.grey;

      icon =
          Icons.info_outline_rounded;

      text = status.isEmpty
          ? 'UNKNOWN'
          : status.toUpperCase();
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
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
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
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
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .error_outline_rounded,
              size: 60,
              color:
                  Colors.red.shade400,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'Unable to load transaction',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(
              onPressed: () {
                onRetry();
              },
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
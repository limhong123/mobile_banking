import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:mobile_banking_app/core/model/transaction_model.dart';
import 'package:mobile_banking_app/screen/transaction_detail/transaction_detail_view.dart';
import 'package:mobile_banking_app/screen/transaction_history/transaction_history_controller.dart';



class TransactionHistoryView
    extends GetView<
        TransactionHistoryController> {

  const TransactionHistoryView({
    super.key,
  });


  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Transaction History',
        ),
        centerTitle: true,
      ),


      body: Obx(
        () {

          if (
            controller
                .isLoading
                .value
          ) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }


          if (
            controller
                .errorMessage
                .isNotEmpty
          ) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [

                  Text(
                    controller
                        .errorMessage
                        .value,
                    textAlign:
                        TextAlign.center,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  ElevatedButton(
                    onPressed:
                        controller
                            .getTransactions,
                    child:
                        const Text(
                      'Try Again',
                    ),
                  ),
                ],
              ),
            );
          }


          if (
            controller
                .transactions
                .isEmpty
          ) {

            return const Center(
              child: Text(
                'No transactions yet',
              ),
            );
          }


          return RefreshIndicator(

            onRefresh:
                controller
                    .refreshData,

            child: ListView.separated(

              padding:
                  const EdgeInsets.all(
                16,
              ),

              itemCount:
                  controller
                      .transactions
                      .length,

              separatorBuilder:
                  (_, __) =>
                      const SizedBox(
                height: 10,
              ),

              itemBuilder:
                  (
                context,
                index,
              ) {

                final transaction =
                    controller
                        .transactions[
                            index];

                return _TransactionItem(
                  transaction:
                      transaction,
                );
              },
            ),
          );
        },
      ),
    );
  }
}


class _TransactionItem
    extends StatelessWidget {

  final TransactionModel
      transaction;


  const _TransactionItem({
    required this.transaction,
  });


  @override
  Widget build(
    BuildContext context,
  ) {

    final bool incoming =
        transaction.isIncoming;


    final String date =
        transaction.createdAt ==
                null
            ? ''
            : DateFormat(
                'dd MMM yyyy • hh:mm a',
              ).format(
                transaction
                    .createdAt!
                    .toLocal(),
              );


    String title =
        transaction
            .counterpartyName;


    if (transaction.isDeposit) {
      title = 'Cash Deposit';
    }


    if (title.isEmpty) {
      title =
          transaction.type;
    }


    return InkWell(

      borderRadius:
          BorderRadius.circular(
        16,
      ),

      onTap: () {

        Get.to(
          () =>
              TransactionDetailView(
            transactionId:
                transaction
                    .transactionId,
          ),
        );
      },

      child: Container(

        padding:
            const EdgeInsets.all(
          16,
        ),

        decoration:
            BoxDecoration(

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border:
              Border.all(
            color:
                Colors.grey.shade300,
          ),
        ),

        child: Row(
          children: [

            CircleAvatar(
              radius: 24,

              child: Icon(
                incoming
                    ? Icons
                        .south_west_rounded
                    : Icons
                        .north_east_rounded,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [

                  Text(
                    title,

                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    transaction
                        .type
                        .toUpperCase(),

                    style:
                        TextStyle(
                      color:
                          Colors
                              .grey
                              .shade600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    date,

                    style:
                        TextStyle(
                      color:
                          Colors
                              .grey
                              .shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [

                Text(
                  '${incoming ? '+' : '-'}'
                  '\$${transaction.amount.toStringAsFixed(2)}',

                  style:
                      TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,

                    color:
                        incoming
                            ? Colors.green
                            : Colors.red,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  transaction.status,

                  style:
                      TextStyle(
                    fontSize: 12,

                    color:
                        transaction
                                .isSuccess
                            ? Colors.green
                            : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class TransactionModel {
  final String id;
  final String transactionId;
  final String type;
  final String direction;

  final double amount;
  final String currency;

  final String status;
  final String description;

  final String counterpartyName;
  final String counterpartyAccount;

  final String senderName;
  final String senderAccountNumber;

  final String receiverName;
  final String receiverAccountNumber;

  final String agentName;

  final double balanceBefore;
  final double balanceAfter;

  final DateTime? createdAt;

  const TransactionModel({
    required this.id,
    required this.transactionId,
    required this.type,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    required this.counterpartyName,
    required this.counterpartyAccount,
    required this.senderName,
    required this.senderAccountNumber,
    required this.receiverName,
    required this.receiverAccountNumber,
    required this.agentName,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',

      transactionId:
          json['transaction_id']?.toString() ?? '',

      type:
          json['type']?.toString() ?? '',

      direction:
          json['direction']?.toString() ?? '',

      amount:
          double.tryParse(
            json['amount']?.toString() ?? '0',
          ) ??
          0,

      currency:
          json['currency']?.toString() ?? 'USD',

      status:
          json['status']?.toString() ?? '',

      description:
          json['description']?.toString() ?? '',

      counterpartyName:
          json['counterparty_name']?.toString() ?? '',

      counterpartyAccount:
          json['counterparty_account']?.toString() ?? '',

      senderName:
          json['sender_name']?.toString() ?? '',

      senderAccountNumber:
          json['sender_account_number']?.toString() ?? '',

      receiverName:
          json['receiver_name']?.toString() ?? '',

      receiverAccountNumber:
          json['receiver_account_number']?.toString() ?? '',

      agentName:
          json['agent_name']?.toString() ?? '',

      balanceBefore:
          double.tryParse(
            json['balance_before']?.toString() ?? '0',
          ) ??
          0,

      balanceAfter:
          double.tryParse(
            json['balance_after']?.toString() ?? '0',
          ) ??
          0,

      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.tryParse(
                  json['created_at'].toString(),
                ),
    );
  }

  bool get isIncoming =>
      direction.toLowerCase() == 'incoming';

  bool get isOutgoing =>
      direction.toLowerCase() == 'outgoing';

  bool get isDeposit =>
      type.toLowerCase() == 'deposit';

  bool get isTransfer =>
      type.toLowerCase() == 'transfer';

  bool get isPayment =>
      type.toLowerCase() == 'payment';

  bool get isSuccess {
    final value = status.toLowerCase();

    return value == 'success' ||
        value == 'completed' ||
        value == 'approved';
  }
}
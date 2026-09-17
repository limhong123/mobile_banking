import 'package:get/get.dart';
import 'package:mobile_banking_app/screen/transaction_history/transaction_history_controller.dart';

class TransactionHistoryViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionHistoryController>(
      () => TransactionHistoryController(),
    );
  }
}
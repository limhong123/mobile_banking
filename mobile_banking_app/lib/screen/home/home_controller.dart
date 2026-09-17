import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_banking_app/core/api/auth/auth_api.dart';
import 'package:mobile_banking_app/core/api/deposit_api.dart';
import 'package:mobile_banking_app/core/api/payment/payment_api.dart';
import 'package:mobile_banking_app/core/model/user_model.dart';
import 'package:mobile_banking_app/screen/security/pin/pin_controller.dart';
import 'package:mobile_banking_app/screen/security/pin/pin_view.dart';

class HomeViewController extends GetxController with WidgetsBindingObserver {
  final AuthApi authApi = AuthApi();

  final DepositApi depositApi = DepositApi();

  final PaymentApi paymentApi = PaymentApi();

  final isLoading = false.obs;

  final isLoadingBalance = false.obs;

  final isLoadingExpense = false.obs;

  final balance = 0.0.obs;

  final expense = 0.0.obs;

  final user = Rxn<UserModel>();

  final RxInt current = 0.obs;
  final List<String> images = [
    'lib/app/assets/images/logo.png',
    'lib/app/assets/images/logo.png',
    'lib/app/assets/images/logo.png',
  ];

  String currentDate = DateFormat('MMM d, yyyy').format(DateTime.now());

  Timer? _refreshTimer;

  // ប្តូរពី List ធម្មតា ទៅ RxList ដើម្បីអោយ UI update ស្វ័យប្រវត្តិពេលប្តូរលំដាប់
  final RxList<Map<String, dynamic>> menuItems = <Map<String, dynamic>>[
    {'icon': Icons.phone_android_rounded, 'label': 'Send', 'route': '/send'},
    {
      'icon': Icons.call_received_rounded,
      'label': 'Receive',
      'route': '/cash-receive',
    },
    {
      'icon': Icons.qr_code_scanner_rounded,
      'label': 'Scan KHQR',
      'route': '/scan-qr',
    },
    {'icon': Icons.add_card_rounded, 'label': 'Deposit', 'route': '/deposit'},
    {'icon': Icons.receipt_long_rounded, 'label': 'Bills', 'route': '/bills'},
    {'icon': Icons.more_horiz_rounded, 'label': 'More', 'route': '/more'},
  ].obs;

  @override
  void onInit() {
    super.onInit();

    // Observe app lifecycle to refresh when user returns to app
    WidgetsBinding.instance.addObserver(this);

    getUser();
    refreshWallet();
    // Start periodic refresh of wallet data (balance and expense)
    _refreshTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) => refreshWallet(),
    );
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      refreshWallet();
    }
  }

  void onPageChanged(int index) {
    current.value = index;
  }

  Future<void> onMenuTap(String route) async {
    await Get.toNamed(route);

    if (route == '/send' || route == '/scan-qr') {
      await refreshWallet();
    }
  }

  // ហៅពេល user អូស item ក្នុង grid
  void onReorder(int oldIndex, int newIndex) {
    final item = menuItems.removeAt(oldIndex);
    menuItems.insert(newIndex, item);
  }

  Future<void> refreshWallet() async {
    await Future.wait([getBalance(), getExpense()]);
  }

  Future<void> getUser() async {
    try {
      isLoading.value = true;

      final response = await authApi.getMe();

      user.value = UserModel.fromMap(
        Map<String, dynamic>.from(response['data']),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user info');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getBalance() async {
    try {
      isLoadingBalance.value = true;

      final response = await depositApi.getBalance();

      balance.value =
          double.tryParse(response['balance']?.toString() ?? '0') ?? 0.0;
    } catch (e) {
      debugPrint('GET BALANCE ERROR: $e');
    } finally {
      isLoadingBalance.value = false;
    }
  }

  Future<void> getExpense() async {
    try {
      isLoadingExpense.value = true;

      final response = await paymentApi.getTransactions();

      final List transactions = response['data'] ?? [];

      double total = 0;

      for (final item in transactions) {
        if (item['direction'] == 'sent' && item['status'] == 'success') {
          total += double.tryParse(item['amount'].toString()) ?? 0;
        }
      }

      expense.value = total;
    } catch (e) {
      debugPrint('GET EXPENSE ERROR: $e');
    } finally {
      isLoadingExpense.value = false;
    }
  }

  //pin
  PinController get pinController => Get.find<PinController>();

  void onLockedMenuTap(String route) {
    // Already entered PIN during
    // current app session.
    if (pinController.isUnlocked.value) {
      Get.toNamed(route);
      return;
    }

    // Need PIN
    Get.to(() => PinView(targetRoute: route));
  }
}

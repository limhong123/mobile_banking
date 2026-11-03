import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:mobile_banking_app/app/app_color.dart';
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

  // =====================================================
  // LOADING
  // =====================================================

  final isLoading = false.obs;
  final isLoadingBalance = false.obs;
  final isLoadingExpense = false.obs;

  // Prevent duplicate refresh
  final isRefreshingWallet = false.obs;

  // =====================================================
  // DATA
  // =====================================================

  final balance = 0.0.obs;
  final expense = 0.0.obs;
  final isBalanceHidden = false.obs;

  final user = Rxn<UserModel>();

  // =====================================================
  // GREETING & FORMATTING
  // =====================================================

  String get greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  String get formattedBalance {
    if (isBalanceHidden.value) {
      return '••••••••';
    }
    return '\$ ${NumberFormat('#,##0.00').format(balance.value)}';
  }

  String get formattedExpense {
    if (isBalanceHidden.value) {
      return '••••';
    }
    return '- \$ ${NumberFormat('#,##0.00').format(expense.value)}';
  }

  void toggleBalanceVisibility() {
    isBalanceHidden.toggle();
  }

  // =====================================================
  // CAROUSEL
  // =====================================================

  final RxInt current = 0.obs;

  final List<String> images = [
    'lib/app/assets/images/logo.png',
    'lib/app/assets/images/logo.png',
    'lib/app/assets/images/logo.png',
  ];

  final List<Map<String, dynamic>> promoBanners = [
    {
      'title': 'Scan & Pay KHQR',
      'subtitle': 'Zero transaction fees on daily Bakong transfers.',
      'tag': 'KHQR',
      'icon': Icons.qr_code_scanner_rounded,
      'gradient': [const Color(0xFF0B3B60), const Color(0xFF135384)],
    },
    {
      'title': 'Instant Transfers',
      'subtitle': 'Send & receive money securely anytime, 24/7.',
      'tag': 'FREE',
      'icon': Icons.send_rounded,
      'gradient': [const Color(0xFF1E5631), const Color(0xFF2E7D32)],
    },
    {
      'title': 'High Return Savings',
      'subtitle': 'Earn up to 6.5% p.a. with Fixed Term Deposits.',
      'tag': 'SPECIAL',
      'icon': Icons.savings_rounded,
      'gradient': [const Color(0xFF311B92), const Color(0xFF512DA8)],
    },
  ];

  // =====================================================
  // DATE
  // =====================================================

  String get currentDate => DateFormat('MMM d, yyyy').format(DateTime.now());

  // =====================================================
  // MENU
  // =====================================================

  final RxList<Map<String, dynamic>> menuItems = <Map<String, dynamic>>[
    {
      'icon': Icons.phone_android_rounded,
      'label': 'Send',
      'route': '/send',
    },
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
    {
      'icon': Icons.savings_rounded,
      'label': 'Savings',
      'route': '/saving',
    },
    {
      'icon': Icons.receipt_long_rounded,
      'label': 'Bills',
      'route': '/bills',
    },
    {
      'icon': Icons.payments_rounded,
      'label': 'Pay Loan',
      'route': '/pay-loan',
    },
  ].obs;

  // =====================================================
  // LIFE CYCLE
  // =====================================================

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadHomeData();
  }

  @override
  void onClose() {
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

  // =====================================================
  // INITIAL LOAD
  // =====================================================

  Future<void> loadHomeData() async {
    await Future.wait([
      getUser(),
      refreshWallet(),
    ]);
  }

  // =====================================================
  // CAROUSEL
  // =====================================================

  void onPageChanged(int index) {
    current.value = index;
  }

  // =====================================================
  // MENU TAP
  // =====================================================

  Future<void> onMenuTap(String route) async {
    await Get.toNamed(route);

    /*
     * Refresh wallet after returning
     * from pages that can change balance.
     */
    if (route == '/send' ||
        route == '/scan-qr' ||
        route == '/pay-loan' ||
        route == '/cash-receive' ||
        route == '/bills') {
      await refreshWallet();
    }
  }

  // =====================================================
  // MENU REORDER
  // =====================================================

  void onReorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= menuItems.length) return;
    if (newIndex < 0 || newIndex >= menuItems.length) return;

    final item = menuItems.removeAt(oldIndex);
    menuItems.insert(newIndex, item);
  }

  // =====================================================
  // REFRESH WALLET
  // =====================================================

  Future<void> refreshWallet() async {
    /*
     * Prevent API from being called
     * multiple times at the same time.
     */
    if (isRefreshingWallet.value) {
      return;
    }

    try {
      isRefreshingWallet.value = true;
      await Future.wait([
        getBalance(),
        getExpense(),
      ]);
    } catch (e) {
      debugPrint('REFRESH WALLET ERROR: $e');
    } finally {
      isRefreshingWallet.value = false;
    }
  }

  // =====================================================
  // GET USER
  // =====================================================

  Future<void> getUser() async {
    try {
      isLoading.value = true;
      final response = await authApi.getMe();

      if (response['data'] != null) {
        user.value = UserModel.fromMap(
          Map<String, dynamic>.from(response['data']),
        );
      }
    } catch (e) {
      debugPrint('GET USER ERROR: $e');
      Get.snackbar(
        'Error',
        'Failed to load user info',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.secondaryColor,
        colorText: AppColor.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =====================================================
  // GET BALANCE
  // =====================================================

  Future<void> getBalance() async {
    try {
      isLoadingBalance.value = true;
      final response = await depositApi.getBalance();

      balance.value = double.tryParse(
            response['balance']?.toString() ?? '0',
          ) ??
          0.0;
    } catch (e) {
      debugPrint('GET BALANCE ERROR: $e');
    } finally {
      isLoadingBalance.value = false;
    }
  }

  // =====================================================
  // GET EXPENSE
  // =====================================================

  Future<void> getExpense() async {
    try {
      isLoadingExpense.value = true;
      final response = await paymentApi.getTodayExpense();

      debugPrint('TODAY EXPENSE RESPONSE: $response');

      expense.value = double.tryParse(
            response['expense']?.toString() ?? '0',
          ) ??
          0.0;

      debugPrint('TODAY EXPENSE: ${expense.value}');
    } catch (e) {
      debugPrint('GET EXPENSE ERROR: $e');
      expense.value = 0.0;
    } finally {
      isLoadingExpense.value = false;
    }
  }

  // =====================================================
  // MANUAL REFRESH
  // =====================================================

  Future<void> onRefresh() async {
    await Future.wait([
      getUser(),
      refreshWallet(),
    ]);
  }

  // =====================================================
  // PIN SECURITY & SAFE NAVIGATION
  // =====================================================

  PinController get pinController => Get.find<PinController>();

  void onLockedMenuTap(String route) {
    if (route == '/bills' || route == '/pay-loan' || route == '/more') {
      Get.snackbar(
        'Coming Soon',
        'This feature will be available in the upcoming update.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColor.secondaryColor,
        colorText: AppColor.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    /*
     * If PIN was already entered
     * during this app session,
     * go directly to the route.
     */
    if (pinController.isUnlocked.value) {
      Get.toNamed(route)?.then((_) => refreshWallet());
      return;
    }

    /*
     * Otherwise ask for PIN.
     */
    Get.to(
      () => PinView(targetRoute: route),
    )?.then((_) => refreshWallet());
  }
}

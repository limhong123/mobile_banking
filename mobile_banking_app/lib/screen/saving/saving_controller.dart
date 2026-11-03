import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobile_banking_app/core/api/deposit_api.dart';
import 'package:mobile_banking_app/core/api/saving_api.dart';
import 'package:mobile_banking_app/core/model/saving_model.dart';
import 'package:mobile_banking_app/screen/home/home_controller.dart';
import 'package:mobile_banking_app/screen/security/pin/pin_controller.dart';
import 'package:mobile_banking_app/screen/security/pin/pin_view.dart';

class SavingController extends GetxController {
  final SavingApi savingApi = SavingApi();
  final DepositApi depositApi = DepositApi();

  // Loading states
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final isWithdrawing = false.obs;

  // Dynamic Savings Terms from Server (ADMIN FULL CONTROL)
  final terms = <SavingTermModel>[].obs;
  final selectedTerm = Rxn<SavingTermModel>();

  // Global settings fallbacks
  final minDeposit = 5.0.obs;
  final currency = 'USD'.obs;

  // Legacy fields for backward compatibility
  final monthlyRate = 0.5.obs;
  final yearlyRate = 1.5.obs;
  final yearlyRate2yr = 2.0.obs;
  final yearlyRate3yr = 2.3.obs;
  final selectedDurationType = 'annual'.obs;
  final selectedDurationMonths = 12.obs;

  // Balances
  final walletBalance = 0.0.obs;
  final totalSavings = 0.0.obs;
  final totalEarnedInterest = 0.0.obs;

  // Lists
  final activeSavings = <SavingItemModel>[].obs;
  final completedSavings = <SavingItemModel>[].obs;

  // Selected tab: 0 = Active & Locked, 1 = Completed
  final selectedTab = 0.obs;

  // New Deposit Form
  final depositAmountController = TextEditingController();
  final currentAppliedRate = 1.5.obs;
  final calculatedInterest = 0.0.obs;
  final calculatedTotalReturn = 0.0.obs;

  // Validation
  final amountError = ''.obs;
  final isValidAmount = false.obs;

  /// Returns the term ID that yields the highest annual equivalent rate
  String? get bestRateTermId {
    if (terms.isEmpty) return null;
    double maxAnnual = -1.0;
    String? bestId;
    for (final t in terms) {
      if (t.annualEquivalent > maxAnnual) {
        maxAnnual = t.annualEquivalent;
        bestId = t.id;
      }
    }
    return bestId ?? terms.first.id;
  }

  /// Returns the highest annual equivalent rate among active terms (e.g. 0.05 = 5.0%)
  double get bestRateAnnual {
    if (terms.isEmpty) return 0.0;
    double maxAnnual = 0.0;
    for (final t in terms) {
      if (t.annualEquivalent > maxAnnual) {
        maxAnnual = t.annualEquivalent;
      }
    }
    return maxAnnual;
  }

  /// Calculates unlock date by adding exact calendar months
  DateTime get calculatedMaturityDate {
    final now = DateTime.now();
    final months = selectedTerm.value?.months ?? 12;
    int newYear = now.year;
    int newMonth = now.month + months;
    while (newMonth > 12) {
      newYear += 1;
      newMonth -= 12;
    }
    final daysInTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = now.day > daysInTargetMonth ? daysInTargetMonth : now.day;
    return DateTime(newYear, newMonth, newDay, now.hour, now.minute);
  }

  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }

  @override
  void onClose() {
    depositAmountController.dispose();
    super.onClose();
  }

  // =====================================================
  // FETCH DATA
  // =====================================================

  Future<void> loadAllData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        fetchTerms(),
        fetchMySavings(),
        fetchWalletBalance(),
      ]);
    } catch (e) {
      debugPrint('Error loading savings data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onRefresh() async {
    await Future.wait([
      fetchTerms(),
      fetchMySavings(),
      fetchWalletBalance(),
    ]);
  }

  /// Fetch dynamic savings terms from GET /savings/terms
  Future<void> fetchTerms() async {
    try {
      final list = await savingApi.getTerms();
      terms.assignAll(list);

      if (terms.isNotEmpty) {
        // Retain selection if still valid, or default to term with highest rate
        if (selectedTerm.value == null || !terms.any((t) => t.id == selectedTerm.value!.id)) {
          final bestId = bestRateTermId;
          final defaultTerm = terms.firstWhere(
            (t) => t.id == bestId,
            orElse: () => terms.first,
          );
          selectTerm(defaultTerm);
        } else {
          // Re-sync selected term reference
          final currentId = selectedTerm.value!.id;
          final updated = terms.firstWhere((t) => t.id == currentId, orElse: () => terms.first);
          selectTerm(updated);
        }
      }
      recalculatePreview();
    } catch (e) {
      debugPrint('Error fetching savings terms: $e');
    }
  }

  Future<void> fetchMySavings() async {
    try {
      final data = await savingApi.getMySavings();
      totalSavings.value = data.totalSavings;
      totalEarnedInterest.value = data.totalEarnedInterest;
      activeSavings.assignAll(data.activeSavings);
      completedSavings.assignAll(data.completedSavings);
    } catch (e) {
      debugPrint('Error fetching my savings: $e');
    }
  }

  Future<void> fetchWalletBalance() async {
    try {
      final res = await depositApi.getBalance();
      walletBalance.value = (res['balance'] as num?)?.toDouble() ?? 0.0;
      recalculatePreview();
    } catch (e) {
      debugPrint('Error fetching wallet balance: $e');
    }
  }

  // =====================================================
  // SELECTION & PREVIEW CALCULATIONS
  // =====================================================

  void selectTerm(SavingTermModel term) {
    selectedTerm.value = term;
    minDeposit.value = term.minAmount;
    selectedDurationType.value = term.rateUnit;
    selectedDurationMonths.value = term.months;
    currentAppliedRate.value = term.ratePercent;
    recalculatePreview();
  }

  /// Sets amount field to user's full balance with 2 decimals (e.g. 490.78)
  void setMaxAmount() {
    depositAmountController.text = walletBalance.value.toStringAsFixed(2);
    recalculatePreview();
  }

  /// Adds to current amount, capped at available wallet balance
  void addAmount(double addVal) {
    final current = double.tryParse(depositAmountController.text.trim()) ?? 0.0;
    double next = current + addVal;
    if (next > walletBalance.value) {
      next = walletBalance.value;
    }
    depositAmountController.text = next.toStringAsFixed(2);
    recalculatePreview();
  }

  /// Real-time live recalculation of guaranteed interest and validation
  void recalculatePreview() {
    final term = selectedTerm.value;
    final amountText = depositAmountController.text.trim();

    if (term == null) {
      amountError.value = '';
      isValidAmount.value = false;
      calculatedInterest.value = 0.0;
      calculatedTotalReturn.value = 0.0;
      return;
    }

    currentAppliedRate.value = term.ratePercent;

    if (amountText.isEmpty) {
      amountError.value = '';
      isValidAmount.value = false;
      calculatedInterest.value = 0.0;
      calculatedTotalReturn.value = 0.0;
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      amountError.value = 'Please enter a valid amount';
      isValidAmount.value = false;
      calculatedInterest.value = 0.0;
      calculatedTotalReturn.value = 0.0;
      return;
    }

    final minAmt = term.minAmount;
    if (amount < minAmt) {
      amountError.value = 'Minimum deposit is \$${NumberFormat('#,##0.00').format(minAmt)}';
      isValidAmount.value = false;
    } else if (amount > walletBalance.value) {
      amountError.value =
          'Amount exceeds available balance (\$${NumberFormat('#,##0.00').format(walletBalance.value)})';
      isValidAmount.value = false;
    } else {
      amountError.value = '';
      isValidAmount.value = true;
    }

    // Formula matches server-side interest calculation:
    // annual:  interest = principal * rate * months / 12
    // monthly: interest = principal * rate * months
    // Round to 2 decimals at the end only
    double interest;
    if (term.rateUnit == 'monthly') {
      interest = amount * term.rate * term.months;
    } else {
      interest = (amount * term.rate * term.months) / 12.0;
    }

    calculatedInterest.value = double.parse(interest.toStringAsFixed(2));
    calculatedTotalReturn.value =
        double.parse((amount + calculatedInterest.value).toStringAsFixed(2));
  }

  // =====================================================
  // CONFIRM & SUBMIT
  // =====================================================

  Future<void> confirmAndSubmit() async {
    final term = selectedTerm.value;
    final amountText = depositAmountController.text.trim();
    final amount = double.tryParse(amountText);

    if (term == null || amount == null || !isValidAmount.value || isSubmitting.value) {
      return;
    }

    // Confirmation dialog before submitting
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: const [
            Icon(Icons.lock_clock_rounded, color: Color(0xFFD97706), size: 24),
            SizedBox(width: 10),
            Text(
              'Confirm Savings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please review your deposit details. Funds will be safely locked in bank custody until maturity.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _dialogRow('Term Selected:', term.label),
                  const SizedBox(height: 6),
                  _dialogRow(
                    'Applied Rate:',
                    '${term.ratePercent.toStringAsFixed(2)}${term.unitLabel}',
                    valueColor: const Color(0xFF047857),
                    isBold: true,
                  ),
                  const SizedBox(height: 6),
                  _dialogRow(
                    'Deposit Amount:',
                    '\$${NumberFormat('#,##0.00').format(amount)}',
                    isBold: true,
                  ),
                  const SizedBox(height: 6),
                  _dialogRow(
                    'Guaranteed Interest:',
                    '+\$${NumberFormat('#,##0.00').format(calculatedInterest.value)}',
                    valueColor: const Color(0xFF10B981),
                    isBold: true,
                  ),
                  const Divider(height: 16),
                  _dialogRow(
                    'Total at Maturity:',
                    '\$${NumberFormat('#,##0.00').format(calculatedTotalReturn.value)}',
                    valueColor: const Color(0xFF0B3B60),
                    isBold: true,
                  ),
                  const SizedBox(height: 6),
                  _dialogRow(
                    'Unlocks On:',
                    DateFormat('MMM d, yyyy').format(calculatedMaturityDate),
                    valueColor: const Color(0xFFD97706),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Confirm & Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // PIN Verification if PIN is registered
    final pinController = Get.isRegistered<PinController>()
        ? Get.find<PinController>()
        : Get.put(PinController());

    if (pinController.hasPin && !pinController.isUnlocked.value) {
      await Get.to(() => const PinView());
      if (!pinController.isUnlocked.value) {
        return; // PIN was not unlocked
      }
    }

    final success = await openSavingDeposit();
    if (success) {
      Get.back(); // Close bottom sheet
    }
  }

  Widget _dialogRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Opens the savings deposit via POST /savings/open
  Future<bool> openSavingDeposit() async {
    final term = selectedTerm.value;
    final amountText = depositAmountController.text.trim();
    final amount = double.tryParse(amountText);

    if (term == null || amount == null || amount <= 0 || !isValidAmount.value) {
      return false;
    }

    try {
      isSubmitting.value = true;
      final res = await savingApi.openSaving(
        termId: term.id,
        amount: amount,
      );

      depositAmountController.clear();
      recalculatePreview();

      // Refresh home wallet if registered
      if (Get.isRegistered<HomeViewController>()) {
        Get.find<HomeViewController>().refreshWallet();
      }

      await Future.wait([
        fetchMySavings(),
        fetchWalletBalance(),
        fetchTerms(),
      ]);

      Get.snackbar(
        'Savings Opened!',
        res['message']?.toString() ??
            'Successfully deposited \$${amount.toStringAsFixed(2)} into ${term.label}.',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Deposit Failed',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // =====================================================
  // WITHDRAW SAVINGS
  // =====================================================

  Future<void> handleWithdraw(SavingItemModel item) async {
    if (!item.isMatured) {
      final days = item.daysRemaining;
      final maturityStr = item.maturityDate != null
          ? DateFormat('MMMM d, yyyy').format(item.maturityDate!)
          : 'maturity';

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 28),
              SizedBox(width: 10),
              Text('Savings Currently Locked'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You cannot withdraw money while it is currently in an active savings deposit.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• Locked Until: $maturityStr',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Days Remaining: $days days',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Guaranteed Interest: +\$${item.expectedInterest.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Funds will automatically become available for withdrawal on $maturityStr along with your accumulated interest return.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

    // IF MATURED: Prompt confirmation to withdraw
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Text('Withdraw Matured Savings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your savings deposit has matured! You can now withdraw the total payout to your main wallet balance.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Principal Saved:'),
                      Text(
                        '\$${item.principalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Interest Earned:'),
                      Text(
                        '+\$${item.expectedInterest.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payout:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${item.totalPayout.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B3B60),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B3B60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Withdraw to Wallet'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      isWithdrawing.value = true;
      final res = await savingApi.withdraw(savingId: item.savingId);

      // Refresh home wallet
      if (Get.isRegistered<HomeViewController>()) {
        Get.find<HomeViewController>().refreshWallet();
      }

      await Future.wait([
        fetchMySavings(),
        fetchWalletBalance(),
      ]);

      Get.snackbar(
        'Payout Successful!',
        res['message']?.toString() ??
            'Successfully credited \$${item.totalPayout.toStringAsFixed(2)} back to your wallet.',
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Withdrawal Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isWithdrawing.value = false;
    }
  }
}

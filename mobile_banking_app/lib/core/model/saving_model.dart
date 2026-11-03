class SavingTermModel {
  final String id;
  final String label;
  final int months;
  final double rate; // e.g. 0.015 for 1.5% p.a., 0.002 for 0.2% /mo
  final String rateUnit; // 'annual' | 'monthly'
  final double annualEquivalent;
  final double monthlyEquivalent;
  final double minAmount;

  SavingTermModel({
    required this.id,
    required this.label,
    required this.months,
    required this.rate,
    required this.rateUnit,
    required this.annualEquivalent,
    required this.monthlyEquivalent,
    required this.minAmount,
  });

  double get ratePercent => rate * 100.0;
  String get unitLabel => rateUnit == 'annual' ? '% p.a.' : '% /mo';
  String get formattedRate => '${ratePercent.toStringAsFixed(2)}$unitLabel';

  factory SavingTermModel.fromJson(Map<String, dynamic> json) {
    return SavingTermModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      months: (json['months'] as num?)?.toInt() ?? 1,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      rateUnit: json['rate_unit']?.toString() ?? 'annual',
      annualEquivalent: (json['annual_equivalent'] as num?)?.toDouble() ?? 0.0,
      monthlyEquivalent: (json['monthly_equivalent'] as num?)?.toDouble() ?? 0.0,
      minAmount: (json['min_amount'] as num?)?.toDouble() ?? 5.0,
    );
  }
}

class SavingSettingsModel {
  final double monthlyRate;
  final double yearlyRate;
  final double yearlyRate2yr;
  final double yearlyRate3yr;
  final double minDeposit;
  final String currency;
  final Map<int, double> tenureRatesMonthly;
  final Map<int, double> tenureRatesYearly;

  SavingSettingsModel({
    required this.monthlyRate,
    required this.yearlyRate,
    required this.yearlyRate2yr,
    required this.yearlyRate3yr,
    required this.minDeposit,
    required this.currency,
    required this.tenureRatesMonthly,
    required this.tenureRatesYearly,
  });

  factory SavingSettingsModel.fromJson(Map<String, dynamic> json) {
    final mRate = (json['monthly_rate'] as num?)?.toDouble() ?? 0.5;
    final yRate = (json['yearly_rate'] as num?)?.toDouble() ?? 1.5;

    // Auto higher if not set: e.g. 1.5% -> 2.0%
    final yRate2 = (json['yearly_rate_2yr'] as num?)?.toDouble() ??
        (yRate <= 2.5 ? yRate + 0.5 : double.parse((yRate * 1.25).toStringAsFixed(2)));

    final yRate3 = (json['yearly_rate_3yr'] as num?)?.toDouble() ??
        (yRate <= 2.5 ? yRate + 0.8 : double.parse((yRate * 1.45).toStringAsFixed(2)));

    // Parse tenure rates map
    final Map<int, double> monthlyMap = {
      1: mRate,
      3: double.parse((mRate * 1.10).toStringAsFixed(2)),
      6: double.parse((mRate * 1.25).toStringAsFixed(2)),
    };

    final Map<int, double> yearlyMap = {
      12: yRate,
      24: yRate2,
      36: yRate3,
    };

    final rawTenure = json['tenure_rates'];
    if (rawTenure is Map) {
      final rawM = rawTenure['monthly'];
      if (rawM is Map) {
        rawM.forEach((k, v) {
          final intKey = int.tryParse(k.toString());
          final dVal = (v as num?)?.toDouble();
          if (intKey != null && dVal != null) {
            monthlyMap[intKey] = dVal;
          }
        });
      }

      final rawY = rawTenure['yearly'];
      if (rawY is Map) {
        rawY.forEach((k, v) {
          final intKey = int.tryParse(k.toString());
          final dVal = (v as num?)?.toDouble();
          if (intKey != null && dVal != null) {
            yearlyMap[intKey] = dVal;
          }
        });
      }
    }

    return SavingSettingsModel(
      monthlyRate: mRate,
      yearlyRate: yRate,
      yearlyRate2yr: yRate2,
      yearlyRate3yr: yRate3,
      minDeposit: (json['min_deposit'] as num?)?.toDouble() ?? 5.0,
      currency: json['currency']?.toString() ?? 'USD',
      tenureRatesMonthly: monthlyMap,
      tenureRatesYearly: yearlyMap,
    );
  }
}

class SavingItemModel {
  final String id;
  final String savingId;
  final String label;
  final double principalAmount;
  final String durationType;
  final int durationMonths;
  final double interestRate;
  final String rateUnit;
  final double expectedInterest;
  final double totalPayout;
  final DateTime? startDate;
  final DateTime? maturityDate;
  final int daysRemaining;
  final bool isMatured;
  final bool canWithdraw;
  final String status;
  final String notes;

  double get displayRatePercent {
    if (interestRate <= 0.35 && interestRate > 0) {
      return interestRate * 100.0;
    }
    return interestRate;
  }

  String get rateUnitLabel =>
      (rateUnit == 'monthly' || durationType == 'monthly') ? '% /mo' : '% p.a.';

  String get formattedRate => '${displayRatePercent.toStringAsFixed(2)}$rateUnitLabel';

  SavingItemModel({
    required this.id,
    required this.savingId,
    required this.label,
    required this.principalAmount,
    required this.durationType,
    required this.durationMonths,
    required this.interestRate,
    required this.rateUnit,
    required this.expectedInterest,
    required this.totalPayout,
    this.startDate,
    this.maturityDate,
    required this.daysRemaining,
    required this.isMatured,
    required this.canWithdraw,
    required this.status,
    required this.notes,
  });

  factory SavingItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr.toString());
      } catch (_) {
        return null;
      }
    }

    return SavingItemModel(
      id: json['id']?.toString() ?? '',
      savingId: json['saving_id']?.toString() ?? '',
      label: json['label']?.toString() ?? (json['term']?.toString() ?? ''),
      principalAmount: (json['principal_amount'] as num?)?.toDouble() ??
          (json['principal'] as num?)?.toDouble() ??
          0.0,
      durationType: json['duration_type']?.toString() ?? 'monthly',
      durationMonths: (json['duration_months'] as num?)?.toInt() ??
          (json['months'] as num?)?.toInt() ??
          1,
      interestRate: (json['interest_rate'] as num?)?.toDouble() ??
          (json['rate'] as num?)?.toDouble() ??
          0.0,
      rateUnit: json['rate_unit']?.toString() ??
          (json['duration_type']?.toString() ?? 'annual'),
      expectedInterest: (json['expected_interest'] as num?)?.toDouble() ??
          (json['interest_amount'] as num?)?.toDouble() ??
          0.0,
      totalPayout: (json['total_payout'] as num?)?.toDouble() ?? 0.0,
      startDate: parseDate(json['start_date']),
      maturityDate: parseDate(json['maturity_date']),
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 0,
      isMatured: json['is_matured'] == true,
      canWithdraw: json['can_withdraw'] == true,
      status: json['status']?.toString() ?? 'active',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class MySavingsData {
  final double totalSavings;
  final double totalEarnedInterest;
  final int activeCount;
  final int completedCount;
  final List<SavingItemModel> activeSavings;
  final List<SavingItemModel> completedSavings;

  MySavingsData({
    required this.totalSavings,
    required this.totalEarnedInterest,
    required this.activeCount,
    required this.completedCount,
    required this.activeSavings,
    required this.completedSavings,
  });

  factory MySavingsData.fromJson(Map<String, dynamic> json) {
    final activeList = (json['active_savings'] as List<dynamic>?)
            ?.map((e) => SavingItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final completedList = (json['completed_savings'] as List<dynamic>?)
            ?.map((e) => SavingItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return MySavingsData(
      totalSavings: (json['total_savings'] as num?)?.toDouble() ?? 0.0,
      totalEarnedInterest:
          (json['total_earned_interest'] as num?)?.toDouble() ?? 0.0,
      activeCount: (json['active_count'] as num?)?.toInt() ?? activeList.length,
      completedCount:
          (json['completed_count'] as num?)?.toInt() ?? completedList.length,
      activeSavings: activeList,
      completedSavings: completedList,
    );
  }
}

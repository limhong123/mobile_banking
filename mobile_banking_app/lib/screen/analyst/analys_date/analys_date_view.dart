import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'analys_date_controller.dart';

class AnalysDateView extends GetView<AnalysDateController> {
  const AnalysDateView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ចំណូល និង ចំណាយ',
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
        child:
            CircularProgressIndicator(),
      );
    }

    if (controller
        .errorMessage
        .value
        .isNotEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.redAccent,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                controller
                    .errorMessage
                    .value,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 16,
              ),

              ElevatedButton(
                onPressed: () {
                  controller
                      .refreshData();
                },
                child:
                    const Text(
                  'ព្យាយាមម្តងទៀត',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          controller.refreshData,
      child:
          SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          children: [
            _filterSection(),

            const SizedBox(
              height: 20,
            ),

            _chartCard(),

            const SizedBox(
              height: 16,
            ),

            _summarySection(),
          ],
        ),
      ),
    );
  },
),
    );
  }

  Widget _filterSection() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _filterButton(
            value: 'day',
            label: 'ថ្ងៃ',
          ),
          _filterButton(
            value: 'week',
            label: 'សប្ដាហ៍',
          ),
          _filterButton(
            value: 'month',
            label: 'ខែ',
          ),
          _filterButton(
            value: 'year',
            label: 'ឆ្នាំ',
          ),
        ],
      ),
    );
  }

  Widget _filterButton({
    required String value,
    required String label,
  }) {
    final isSelected =
        controller.selectedFilter.value == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.changeFilter(value);
        },
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 200,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.amber
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'សង្ខេបប្រតិបត្តិការ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                _currentFilterName(),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 65,
                    sectionsSpace: 4,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value:
                            controller.income.value,
                        color: Colors.green,
                        radius: 38,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value:
                            controller.expense.value,
                        color: Colors.redAccent,
                        radius: 38,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'សរុប',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '\$${controller.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              _legend(
                color: Colors.green,
                text: 'ចំណូល',
              ),

              const SizedBox(width: 30),

              _legend(
                color: Colors.redAccent,
                text: 'ចំណាយ',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend({
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 7),

        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _summarySection() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.arrow_downward,
            title: 'ចំណូល',
            amount: controller.income.value,
            percent: controller.incomePercent,
            iconColor: Colors.green,
            iconBackground:
                Colors.green.shade50,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _summaryCard(
            icon: Icons.arrow_upward,
            title: 'ចំណាយ',
            amount: controller.expense.value,
            percent: controller.expensePercent,
            iconColor: Colors.redAccent,
            iconBackground:
                Colors.red.shade50,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required double amount,
    required double percent,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            '${percent.toStringAsFixed(1)}%',
            style: TextStyle(
              color: iconColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _currentFilterName() {
    switch (controller.selectedFilter.value) {
      case 'day':
        return 'ថ្ងៃ';

      case 'week':
        return 'សប្ដាហ៍';

      case 'month':
        return 'ខែ';

      case 'year':
        return 'ឆ្នាំ';

      default:
        return '';
    }
  }
}
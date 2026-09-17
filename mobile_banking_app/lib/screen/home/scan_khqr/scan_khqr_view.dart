import 'package:flutter/material.dart';
import 'package:get/get.dart';

part 'scan_khqr_binding.dart';
part 'scan_khqr_controller.dart';

class ScanKhqrView extends GetView<ScanKhqrViewController> {
  const ScanKhqrView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('ScanKhqrView'),
      ),
    );
  }
}
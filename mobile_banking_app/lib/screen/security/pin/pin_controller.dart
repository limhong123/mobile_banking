import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class PinController extends GetxController {
  final GetStorage box = GetStorage();

  // PIN currently typed by user
  final RxString pin = ''.obs;

  // Is app unlocked during this session?
  // IMPORTANT: Don't save this in GetStorage.
  // After app restart it becomes false again.
  final RxBool isUnlocked = false.obs;

  // Route that user wanted to open
  String? targetRoute;

  // =========================
  // CHECK IF PIN EXISTS
  // =========================

  bool get hasPin {
    final savedPin = box.read<String>('app_pin');

    return savedPin != null &&
        savedPin.isNotEmpty;
  }

  // =========================
  // ADD NUMBER
  // =========================

  void addNumber(String number) {
    if (pin.value.length >= 6) {
      return;
    }

    pin.value += number;

    // Automatically submit after 6 digits
    if (pin.value.length == 6) {
      Future.delayed(
        const Duration(milliseconds: 150),
        submitPin,
      );
    }
  }

  // =========================
  // DELETE NUMBER
  // =========================

  void deleteNumber() {
    if (pin.value.isEmpty) {
      return;
    }

    pin.value = pin.value.substring(
      0,
      pin.value.length - 1,
    );
  }

  // =========================
  // CLEAR PIN
  // =========================

  void clearPin() {
    pin.value = '';
  }

  // =========================
  // SUBMIT
  // =========================

  void submitPin() {
    if (pin.value.length != 6) {
      return;
    }

    if (!hasPin) {
      _createPin();
    } else {
      _verifyPin();
    }
  }

  // =========================
  // CREATE PIN FIRST TIME
  // =========================

  void _createPin() {
    box.write(
      'app_pin',
      pin.value,
    );

    isUnlocked.value = true;

    clearPin();

    _openTargetRoute();
  }

  // =========================
  // VERIFY PIN
  // =========================

  void _verifyPin() {
    final savedPin =
        box.read<String>('app_pin');

    if (savedPin == pin.value) {
      isUnlocked.value = true;

      clearPin();

      _openTargetRoute();
    } else {
      clearPin();

      Get.snackbar(
        'PIN មិនត្រឹមត្រូវ',
        'សូមបញ្ចូលលេខសម្ងាត់ម្តងទៀត',
        snackPosition:
            SnackPosition.BOTTOM,
        backgroundColor:
            Colors.red.shade50,
        colorText: Colors.red,
        margin:
            const EdgeInsets.all(16),
      );
    }
  }

  // =========================
  // OPEN REQUESTED MENU
  // =========================

  void _openTargetRoute() {
    final route = targetRoute;

    targetRoute = null;

    if (route != null &&
        route.isNotEmpty) {
      Get.offNamed(route);
    } else {
      Get.back();
    }
  }

  // =========================
  // LOCK APP
  // =========================

  void lock() {
    isUnlocked.value = false;
    clearPin();
  }

  // =========================
  // REMOVE PIN
  // =========================

  void removePin() {
    box.remove('app_pin');

    isUnlocked.value = false;

    clearPin();
  }

  @override
  void onClose() {
    clearPin();
    super.onClose();
  }
}
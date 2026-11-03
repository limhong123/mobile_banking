import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/app/app_text.dart';
import 'package:mobile_banking_app/screen/security/pin/pin_controller.dart';

class PinView extends GetView<PinController> {
  const PinView({
    super.key,
    this.targetRoute,
  });

  final String? targetRoute;

  @override
  Widget build(BuildContext context) {
    if (targetRoute != null) {
      controller.targetRoute = targetRoute;
    }

    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              child: Column(
                children: [
                  // CLOSE BUTTON
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 10,
                      right: 16,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColor.background,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            controller.clearPin();
                            Get.back();
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 30,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // TITLE
                  Text(
                    controller.hasPin
                        ? 'បញ្ចូលលេខសម្ងាត់'
                        : 'បង្កើតលេខសម្ងាត់',
                    style: AppText.h1.copyWith(
                      color: AppColor.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // LOCK ICON
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      color: AppColor.background,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppColor.secondaryColor,
                      size: 46,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // PIN DOTS
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.scaffoldBackground,
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Obx(
                      () => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          6,
                          (index) {
                            final selected =
                                index < controller.pin.value.length;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? AppColor.secondaryColor
                                    : AppColor.textHint,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (controller.hasPin)
                    TextButton(
                      onPressed: () {
                        Get.snackbar(
                          'Forgot PIN',
                          'Forgot PIN can connect to OTP/backend later.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: Text(
                        'ភ្លេចលេខសម្ងាត់?',
                        style: AppText.bodySmall.copyWith(
                          color: AppColor.secondaryColor,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // KEYPAD
                  _numberPad(),

                  const SizedBox(height: 5),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _numberPad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _numberButton('1'),
            _numberButton('2'),
            _numberButton('3'),
          ],
        ),
        Row(
          children: [
            _numberButton('4'),
            _numberButton('5'),
            _numberButton('6'),
          ],
        ),
        Row(
          children: [
            _numberButton('7'),
            _numberButton('8'),
            _numberButton('9'),
          ],
        ),
        Row(
          children: [
            const Expanded(
              child: SizedBox(
                height: 72,
              ),
            ),
            _numberButton('0'),
            Expanded(
              child: InkWell(
                onTap: controller.deleteNumber,
                child: const SizedBox(
                  height: 72,
                  child: Center(
                    child: Icon(
                      Icons.backspace_outlined,
                      size: 26,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberButton(String number) {
    return Expanded(
      child: InkWell(
        onTap: () {
          controller.addNumber(number);
        },
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColor.background,
              ),
              right: BorderSide(
                color: AppColor.background,
              ),
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: AppText.h1.copyWith(
                fontWeight: FontWeight.w400,
                color: AppColor.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

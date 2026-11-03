import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/screen/auth/splash_screen/splash_screen_controller.dart';

class SplashScreenView
    extends GetView<SplashViewController> {
  const SplashScreenView({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: Center(
        child: Image.asset(
          'lib/app/assets/images/logo.png',
          width: 220,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

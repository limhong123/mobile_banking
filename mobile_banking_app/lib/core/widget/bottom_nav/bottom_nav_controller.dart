import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:mobile_banking_app/screen/analyst/analys_date/analys_date_view.dart';
import 'package:mobile_banking_app/screen/home/home_view.dart';
import 'package:mobile_banking_app/screen/profile/profile_view.dart';
import 'package:mobile_banking_app/screen/saving/saving_view.dart';

class BottomNavViewController extends GetxController {
  int currentIndex = 0;
  final List<Widget> screens = const [
    HomeView(),
    SavingView(),
    AnalysDateView(),
    ProfileView(),
  ];

  void onMenuTap(int index) {
    currentIndex = index;
    update();
  }
}

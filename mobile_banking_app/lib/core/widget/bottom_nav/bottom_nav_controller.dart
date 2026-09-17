

import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:mobile_banking_app/screen/analyst/analys_date/analys_date_view.dart';
import 'package:mobile_banking_app/screen/home/home_view.dart';
import 'package:mobile_banking_app/screen/profile/profile_view.dart';

class BottomNavViewController extends GetxController {

  @override
  void onInit() {
    super.onInit();
  }
  int currentIndex = 0;
  final List<Widget> screens = [
     HomeView(),
     AnalysDateView(),
     ProfileView(),
  ];

  void onMenuTap(int index) {
    currentIndex = index;
    update();
  }
}
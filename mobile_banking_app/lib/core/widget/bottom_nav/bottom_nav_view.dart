import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_banking_app/app/app_color.dart';
import 'package:mobile_banking_app/core/widget/bottom_nav/bottom_nav_controller.dart';
import 'package:mobile_banking_app/screen/analyst/analys_date/analys_date_controller.dart';
import 'package:mobile_banking_app/screen/analyst/analys_date/analys_date_view.dart';
import 'package:mobile_banking_app/screen/home/home_controller.dart';
import 'package:mobile_banking_app/screen/home/home_view.dart';
import 'package:mobile_banking_app/screen/profile/profile_view.dart';

part 'bottom_nav_binding.dart';

class BottomNavView extends GetView<BottomNavViewController> {
  const BottomNavView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BottomNavViewController>(
      builder: (controller) {
        return Scaffold(
          body: IndexedStack(
            index: controller.currentIndex,
            children: controller.screens,
            
          ),
          bottomNavigationBar: BottomNavigationBar(
            selectedItemColor: 
            AppColor.secondaryColor,
            currentIndex: controller.currentIndex,
            onTap: controller.onMenuTap,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Analyst',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
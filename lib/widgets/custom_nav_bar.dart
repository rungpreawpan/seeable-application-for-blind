import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/bottom_nav_controller.dart';
import 'package:seeable/views/home/home_page.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/views/settings/settings_page.dart';

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<BottomNavController>();
    final settingsController = Get.find<SettingsController>();
    final theme = Theme.of(context);
    final screens = [const HomePage(), const SettingsPage()];

    return Obx(() {
      final index = navController.currentIndex.value;
      return Scaffold(
        extendBody: true,
        body: screens[index],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.bottomNavigationBarTheme.backgroundColor,
            boxShadow: settingsController.themeMode.value == ThemeMode.light
                ? customBoxShadow
                : null,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(25.0),
              topLeft: Radius.circular(25.0),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 80.0,
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                selectedFontSize: fontSizeS,
                unselectedFontSize: fontSizeS,
                currentIndex: index,
                onTap: (i) {
                  navController.currentIndex.value = i;
                  SemanticsService.announce(
                    i == 0 ? 'main page'.tr : 'settings'.tr,
                    TextDirection.ltr,
                  );
                },
                items: [
                  BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      index == 0
                          ? 'assets/icons/home_filled_icon.svg'
                          : 'assets/icons/home_icon.svg',
                      height: 25.0,
                      width: 25.0,
                      fit: BoxFit.fitHeight,
                      color: _iconColor(settingsController, index == 0),
                    ),
                    label: 'main page'.tr,
                    tooltip: '',
                  ),
                  BottomNavigationBarItem(
                    icon: SvgPicture.asset(
                      index == 1
                          ? 'assets/icons/settings_filled_icon.svg'
                          : 'assets/icons/settings_icon.svg',
                      height: 30.0,
                      width: 30.0,
                      fit: BoxFit.fitHeight,
                      color: _iconColor(settingsController, index == 1),
                    ),
                    label: 'settings'.tr,
                    tooltip: '',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Color _iconColor(SettingsController controller, bool isSelected) {
    if (controller.themeMode.value == ThemeMode.dark) return Colors.white;
    return isSelected ? Colors.black : Colors.grey.shade400;
  }
}

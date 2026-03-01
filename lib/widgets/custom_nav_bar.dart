import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/home/home_page.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/views/settings/settings_page.dart';

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({super.key});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  final SettingsController _settingsController = Get.find();

  int currentIndex = 0;

  final List _screen = [
    const HomePage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
          extendBody: true,
          body: _screen[currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: theme.bottomNavigationBarTheme.backgroundColor,
              boxShadow: _settingsController.themeMode.value == ThemeMode.light
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
                  currentIndex: currentIndex,
                  onTap: (index) {
                    currentIndex = index;
                    setState(() {});

                    SemanticsService.announce(
                      index == 0 ? 'main page'.tr : 'settings'.tr,
                      TextDirection.ltr,
                    );
                  },
                  items: [
                    BottomNavigationBarItem(
                      icon: SvgPicture.asset(
                        currentIndex == 0
                            ? 'assets/icons/home_filled_icon.svg'
                            : 'assets/icons/home_icon.svg',
                        height: 25.0,
                        width: 25.0,
                        fit: BoxFit.fitHeight,
                        color: _iconColor(currentIndex == 0),
                      ),
                      label: 'main page'.tr,
                      tooltip: '',
                    ),
                    BottomNavigationBarItem(
                      icon: SvgPicture.asset(
                        currentIndex == 1
                            ? 'assets/icons/settings_filled_icon.svg'
                            : 'assets/icons/settings_icon.svg',
                        height: 30.0,
                        width: 30.0,
                        fit: BoxFit.fitHeight,
                        color: _iconColor(currentIndex == 1),
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
  }

  Color _iconColor(bool isSelected) {
    Color color = Colors.black;

    if (_settingsController.themeMode.value == ThemeMode.light) {
      if (isSelected) {
        color = Colors.black;
      } else {
        color = Colors.grey.shade400;
      }
    } else if (_settingsController.themeMode.value == ThemeMode.dark) {
      color = Colors.white;
    }

    return color;
  }
}

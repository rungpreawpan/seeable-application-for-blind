import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/home/home_page.dart';
import 'package:seeable/views/settings/settings_page.dart';

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({super.key});

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  int currentIndex = 0;

  final List _screen = [
    const HomePage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screen[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: customBoxShadow,
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
              elevation: 0.0,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey.shade400,
              selectedFontSize: fontSizeS,
              unselectedFontSize: fontSizeS,
              selectedLabelStyle: TextStyle(
                fontFamily: GoogleFonts.kanit().fontFamily,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: GoogleFonts.kanit().fontFamily,
              ),
              currentIndex: currentIndex,
              onTap: (index) {
                currentIndex = index;
                setState(() {});
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
                    // ignore: deprecated_member_use
                    color:
                        currentIndex == 0 ? Colors.black : Colors.grey.shade400,
                  ),
                  label: 'หน้าหลัก', //TODO
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
                    // ignore: deprecated_member_use
                    color:
                        currentIndex == 1 ? Colors.black : Colors.grey.shade400,
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
}

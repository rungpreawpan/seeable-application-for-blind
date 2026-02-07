import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';

class CustomBackButton extends StatefulWidget {
  final Function()? onTap;

  const CustomBackButton({
    super.key,
    this.onTap,
  });

  @override
  State<CustomBackButton> createState() => _CustomBackButtonState();
}

class _CustomBackButtonState extends State<CustomBackButton> {
  final SettingsController _settingsController = Get.find();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.back();

        if (widget.onTap != null) {
          widget.onTap;
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: marginX2),
        child: Container(
          height: 40.0,
          width: 40.0,
          margin: const EdgeInsets.symmetric(vertical: 20.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: _settingsController.themeMode.value == ThemeMode.light
                  ? primaryColor
                  : Colors.white,
            ),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              color: _settingsController.themeMode.value == ThemeMode.light
                  ? primaryColor
                  : Colors.white,
              size: 30.0,
            ),
          ),
        ),
      ),
    );
  }
}

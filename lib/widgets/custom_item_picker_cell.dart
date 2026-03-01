import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/widgets/text_font_style.dart';

class CustomItemPickerCell extends StatefulWidget {
  final String title;
  final bool isSelected;

  const CustomItemPickerCell({
    super.key,
    required this.title,
    required this.isSelected,
  });

  @override
  State<CustomItemPickerCell> createState() => _CustomItemPickerCellState();
}

class _CustomItemPickerCellState extends State<CustomItemPickerCell> {
  final SettingsController _settingsController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.title,
      child: Container(
        width: Get.width,
        padding: const EdgeInsets.symmetric(
          horizontal: marginX2,
          vertical: margin,
        ),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? _settingsController.themeMode.value == ThemeMode.light
                  ? primaryColor
                  : Colors.grey.shade600
              : Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFontStyle(
                widget.title,
                size: fontSizeL,
                color: widget.isSelected ? Colors.white : Colors.black,
              ),
            ),
            Visibility(
              visible: widget.isSelected ? true : false,
              child: const Icon(
                Icons.check,
                size: 24.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

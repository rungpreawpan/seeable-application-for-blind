import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/text_font_style.dart';

enum SettingsLabelStyle {
  onOff,
  dialog,
  interact,
  showData,
}

class SettingsLabel extends StatelessWidget {
  final String title;
  final bool isTopic;
  final SettingsLabelStyle settingsLabelStyle;
  final bool switchValue;
  final Function(bool)? onChanged;
  final Function()? onTap;
  final String buttonInitialValue;

  const SettingsLabel({
    super.key,
    required this.title,
    this.isTopic = false,
    required this.settingsLabelStyle,
    this.switchValue = false,
    this.onChanged,
    this.onTap,
    this.buttonInitialValue = '',
  });

  @override
  Widget build(BuildContext context) {
    return getLabelStyle();
  }

  Widget getLabelStyle() {
    Widget labelStyle;
    SettingsLabelStyle label = settingsLabelStyle;

    switch (label) {
      case SettingsLabelStyle.onOff:
        labelStyle = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextFontStyle(
              title,
              size: fontSizeL,
              weight: FontWeight.normal,
            ),
            _switch(
              value: switchValue,
              onChanged: onChanged,
            ),
          ],
        );
        break;

      case SettingsLabelStyle.dialog:
        labelStyle = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextFontStyle(
              title,
              size: fontSizeL,
              weight: FontWeight.normal,
            ),
            _selectButton(
              onTap: onTap,
              buttonInitialValue: buttonInitialValue,
            ),
          ],
        );
        break;

      case SettingsLabelStyle.interact:
        labelStyle = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextFontStyle(
              title,
              size: fontSizeL,
              weight: isTopic ? FontWeight.bold : FontWeight.normal,
            ),
            _selectButton(
              onTap: onTap,
            ),
          ],
        );
        break;

      case SettingsLabelStyle.showData:
        labelStyle = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextFontStyle(
              title,
              size: fontSizeL,
              weight: isTopic ? FontWeight.bold : FontWeight.normal,
            ),
            _selectButton(buttonInitialValue: buttonInitialValue),
          ],
        );
        break;
    }

    return labelStyle;
  }

  _switch({
    required bool value,
    void Function(bool)? onChanged,
  }) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: primaryColor,
    );
  }

  _selectButton({
    Function()? onTap,
    String buttonInitialValue = '',
  }) {
    return InkWell(
      onTap: onTap,
      child: settingsLabelStyle == SettingsLabelStyle.dialog ||
              settingsLabelStyle == SettingsLabelStyle.showData
          ? TextFontStyle(
              buttonInitialValue,
              size: fontSizeL,
              weight: FontWeight.bold,
            )
          : const SizedBox(
              width: 20.0,
              child: const Icon(
                Icons.navigate_next_rounded,
                size: 30.0,
              ),
            ),
    );
  }
}

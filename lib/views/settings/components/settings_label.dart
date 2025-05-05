import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/text_font_style.dart';

enum SettingsLabelStyle {
  onOff,
  interact,
  showData,
  updateInfo,
}

class SettingsLabel extends StatelessWidget {
  final String title;
  final bool isTopic;
  final SettingsLabelStyle settingsLabelStyle;
  final bool switchValue;
  final Function(bool)? onChanged;
  final Function()? onTap;
  final String buttonInitialValue;
  final bool showWarning;

  const SettingsLabel({
    super.key,
    required this.title,
    this.isTopic = false,
    required this.settingsLabelStyle,
    this.switchValue = false,
    this.onChanged,
    this.onTap,
    this.buttonInitialValue = '',
    this.showWarning = false,
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

      case SettingsLabelStyle.interact:
        labelStyle = InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextFontStyle(
                title,
                size: fontSizeL,
                weight: isTopic ? FontWeight.bold : FontWeight.normal,
              ),
              buttonInitialValue != ''
                  ? TextFontStyle(
                      buttonInitialValue,
                      size: fontSizeL,
                      weight: FontWeight.bold,
                    )
                  : const SizedBox(
                      width: 20.0,
                      child: Icon(
                        Icons.navigate_next_rounded,
                        size: 30.0,
                      ),
                    ),
            ],
          ),
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
            TextFontStyle(
              buttonInitialValue,
              size: fontSizeL,
              weight: FontWeight.bold,
            ),
          ],
        );
        break;

      case SettingsLabelStyle.updateInfo:
        labelStyle = InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFontStyle(
                title,
                size: fontSizeM,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TextFontStyle(
                        buttonInitialValue,
                        size: fontSizeL,
                        weight: FontWeight.bold,
                      ),
                      Visibility(
                        visible: showWarning,
                        child: const Row(
                          children: [
                            SizedBox(width: margin),
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 20.0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 20.0,
                    child: Icon(
                      Icons.navigate_next_rounded,
                      size: 28.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
}

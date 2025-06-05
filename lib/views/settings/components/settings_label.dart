import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/widgets/text_font_style.dart';

enum SettingsLabelStyle {
  onOff,
  interact,
  showData,
  updateInfo,
}

class SettingsLabel extends StatefulWidget {
  final String title;
  final SettingsLabelStyle settingsLabelStyle;
  final bool switchValue;
  final Function(bool)? onChanged;
  final Function()? onTap;
  final String buttonInitialValue;
  final bool showWarning;

  const SettingsLabel({
    super.key,
    required this.title,
    required this.settingsLabelStyle,
    this.switchValue = false,
    this.onChanged,
    this.onTap,
    this.buttonInitialValue = '',
    this.showWarning = false,
  });

  @override
  State<SettingsLabel> createState() => _SettingsLabelState();
}

class _SettingsLabelState extends State<SettingsLabel> {
  final SettingsController _settingsController = Get.find();

  @override
  Widget build(BuildContext context) {
    return getLabelStyle(context);
  }

  Widget getLabelStyle(BuildContext context) {
    Widget labelStyle;
    SettingsLabelStyle label = widget.settingsLabelStyle;
    final theme = Theme.of(context);

    switch (label) {
      case SettingsLabelStyle.onOff:
        labelStyle = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextFontStyle(
              widget.title,
              style: theme.textTheme.labelSmall,
            ),
            _switch(
              value: widget.switchValue,
              onChanged: widget.onChanged,
            ),
          ],
        );
        break;

      case SettingsLabelStyle.interact:
        labelStyle = InkWell(
          onTap: widget.onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextFontStyle(
                widget.title,
                style: theme.textTheme.labelSmall,
              ),
              widget.buttonInitialValue != ''
                  ? TextFontStyle(
                      widget.buttonInitialValue,
                      style: theme.textTheme.labelMedium,
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
              widget.title,
              style: theme.textTheme.labelSmall,
            ),
            TextFontStyle(
              widget.buttonInitialValue,
              style: theme.textTheme.labelMedium,
            ),
          ],
        );
        break;

      case SettingsLabelStyle.updateInfo:
        labelStyle = InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFontStyle(
                widget.title,
                size: fontSizeM,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TextFontStyle(
                        widget.buttonInitialValue,
                        style: theme.textTheme.labelMedium,
                      ),
                      Visibility(
                        visible: widget.showWarning,
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
                  SizedBox(
                    width: 20.0,
                    child: Icon(
                      Icons.navigate_next_rounded,
                      size: 28.0,
                      color: theme.iconTheme.color,
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
      activeTrackColor: _settingsController.themeMode.value == ThemeMode.light
          ? primaryColor
          : Colors.grey.shade700,
    );
  }
}

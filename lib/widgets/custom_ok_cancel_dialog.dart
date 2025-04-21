import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/text_font_style.dart';

class CustomOkCancelDialog extends StatelessWidget {
  final Widget? icon;
  final String title;
  final Color? titleColor;
  final String? content;
  final Color? contentColor;
  final String okTestKey;
  final Function()? onOK;
  final String? okText;
  final bool isGradient;
  final Color? gradientColor1;
  final Color? gradientColor2;
  final bool showCancel;
  final String cancelTestKey;
  final Function()? onCancel;
  final String? cancelText;

  const CustomOkCancelDialog({
    super.key,
    this.icon,
    required this.title,
    this.titleColor,
    this.content,
    this.contentColor,
    this.okTestKey = '',
    this.onOK,
    this.okText,
    this.isGradient = false,
    this.gradientColor1,
    this.gradientColor2,
    this.showCancel = true,
    this.cancelTestKey = '',
    this.onCancel,
    this.cancelText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      contentPadding: const EdgeInsets.only(
        left: marginX2,
        right: marginX2,
        top: marginX2,
        bottom: margin,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon != null
                ? Column(
              children: [
                icon!,
                const SizedBox(height: margin),
              ],
            )
                : const SizedBox(),
            TextFontStyle(
              title,
              color: titleColor ?? Colors.black,
              size: fontSizeL,
              weight: FontWeight.bold,
              align: TextAlign.center,
            ),
            Visibility(
              visible: content != null,
              child: Column(
                children: [
                  const SizedBox(height: margin),
                  TextFontStyle(
                    content ?? '',
                    color: contentColor ?? Colors.grey,
                    size: fontSizeM,
                    weight: FontWeight.bold,
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: CustomSubmitButton(
                key: ValueKey(okTestKey),
                onTap: () {
                  Get.back(result: true);

                  if (onOK != null) {
                    onOK!();
                  }
                },
                title: okText ?? 'ยืนยัน',
                borderRadius: 10,
                buttonHeight: 45.0,
                buttonColor: primaryColor,
              ),
            ),
            showCancel ? const SizedBox(width: margin) : const SizedBox(),
            showCancel
                ? Expanded(
              child: CustomSubmitButton(
                key: ValueKey(cancelTestKey),
                onTap: () {
                  Get.back();

                  if (onCancel != null) {
                    onCancel!();
                  }
                },
                title: cancelText ?? 'ยกเลิก',
                borderRadius: 10,
               showBorder: true,
                fontColor: Colors.grey,
                buttonColor: Colors.transparent,
                buttonHeight: 45.0,
              ),
            )
                : Container(),
          ],
        ),
      ],
    );
  }
}
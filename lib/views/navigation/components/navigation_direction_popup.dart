import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/text_font_style.dart';

class NavigationDirectionPopup extends StatelessWidget {
  final String status;
  final String? alertText;

  const NavigationDirectionPopup({
    super.key,
    required this.status,
    required this.alertText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      padding:
          const EdgeInsets.symmetric(horizontal: marginX2, vertical: margin),
      margin:  const EdgeInsets.all(marginX2),
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: customBoxShadow,
      ),
      child: Column(
        children: [
          Visibility(
            visible: status == 'ARRIVED',
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/icons/arrived_icon.svg',
                  height: 50.0,
                ),
                const SizedBox(height: margin),
              ],
            ),
          ),
          alertText != null
              ? TextFontStyle(
                  alertText!,
                  size: fontSizeXL,
                  weight: FontWeight.bold,
                )
              : const SizedBox(),
        ],
      ),
    );
  }
}

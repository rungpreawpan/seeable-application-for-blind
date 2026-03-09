import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/text_font_style.dart';

class ObstacleAlertPopup extends StatelessWidget {
  final String? obstacle;

  const ObstacleAlertPopup({super.key, required this.obstacle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      padding:
          const EdgeInsets.symmetric(horizontal: marginX2, vertical: margin),
      margin:  const EdgeInsets.all(marginX2),
      decoration: BoxDecoration(
        color: Colors.redAccent.shade400.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: customBoxShadow,
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/icons/alert_icon.svg',
            height: 50.0,
          ),
          const SizedBox(height: margin),
          obstacle != null
              ? TextFontStyle(
                  obstacle!,
                  size: fontSizeXL,
                  weight: FontWeight.bold,
                )
              : const SizedBox(),
        ],
      ),
    );
  }
}

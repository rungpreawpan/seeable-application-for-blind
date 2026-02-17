import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/text_font_style.dart';

class ObstacleAlertPopup extends StatelessWidget {
  const ObstacleAlertPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      padding:
          const EdgeInsets.symmetric(horizontal: marginX2, vertical: margin),
      margin: const EdgeInsets.symmetric(horizontal: marginX2),
      decoration: BoxDecoration(
        color: Colors.redAccent.shade400.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: customBoxShadow,
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            // 'assets/icons/arrived_icon.svg',
            'assets/icons/alert_icon.svg',
            height: 50.0,
          ),
          const SizedBox(height: margin),
          TextFontStyle(
            'ตรวจพบบุคคล',
            size: fontSizeXL,
            weight: FontWeight.bold,
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/text_font_style.dart';

class CustomItemPickerCell extends StatelessWidget {
  final String title;
  final bool isSelected;

  const CustomItemPickerCell({
    super.key,
    required this.title,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width,
      padding: const EdgeInsets.symmetric(
        horizontal: marginX2,
        vertical: 10.0,
      ),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: lightBoxShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFontStyle(
              title,
              size: fontSizeL,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
          Visibility(
            visible: isSelected ? true : false,
            child: const Icon(
              Icons.check,
              size: 24.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/text_font_style.dart';

class ListViewButton extends StatelessWidget {
  final Function() onTap;
  final String iconPath;
  final double iconSize;
  final Color iconColor;
  final String title;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showArrow;
  final bool showDistance;
  final String distance;

  const ListViewButton({
    super.key,
    required this.onTap,
    required this.iconPath,
    this.iconSize = 60.0,
    this.iconColor = Colors.black,
    required this.title,
    this.fontSize = fontListViewButton,
    this.fontWeight = FontWeight.bold,
    this.showArrow = true,
    this.showDistance = false,
    this.distance = '0',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 100.0,
          padding: const EdgeInsets.symmetric(horizontal: marginX2),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            children: [
              Visibility(
                visible: iconPath != '',
                child: Row(
                  children: [
                    SvgPicture.asset(
                      iconPath,
                      height: iconSize,
                      color: iconColor,
                    ),
                    const SizedBox(width: 20.0),
                  ],
                ),
              ),
              TextFontStyle(
                title,
                size: fontSize,
                weight: fontWeight,
              ),
              const Spacer(),
              showArrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward_ios_rounded),
                        SizedBox(height: showDistance ? 10.0 : 0),
                        showDistance
                            ? _distanceBox(distance: distance)
                            : const SizedBox(),
                      ],
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  _distanceBox({required String distance}) {
    return Container(
      width: 80.0,
      height: 35.0,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Center(
        child: TextFontStyle(
          '${distance}m',
          size: fontSizeL,
          weight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

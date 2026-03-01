import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/text_font_style.dart';

class CustomLoading extends StatelessWidget {
  const CustomLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      body: Center(
        child: Semantics(
          container: true,
          liveRegion: true,
          label: 'loading'.tr,
          child: Container(
            padding: const EdgeInsets.all(30.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const ExcludeSemantics(
                    child: CircularProgressIndicator(color: primaryColor)),
                const SizedBox(height: marginX2),
                TextFontStyle(
                  'loading'.tr,
                  color: Colors.black,
                  weight: FontWeight.bold,
                  size: fontSizeM,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

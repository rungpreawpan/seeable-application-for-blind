import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/text_font_style.dart';

class IntroTemplate extends StatelessWidget {
  final bool isWelcomePage;
  final String iconPath;
  final String description;
  final Function() next;
  final Function() back;

  const IntroTemplate({
    super.key,
    this.isWelcomePage = false,
    required this.iconPath,
    required this.description,
    required this.next,
    required this.back,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: Get.width,
        child: SafeArea(
          child: Column(
            children: [
              _introContent(),
              isWelcomePage ? _welcomeButton() : _actionButton(),
            ],
          ),
        ),
      ),
    );
  }

  _introContent() {
    return Expanded(
      child: isWelcomePage ? _welcomeTemplate() : _permissionTemplate(),
    );
  }

  _permissionIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: SvgPicture.asset(
        iconPath,
        height: 400.0,
      ),
    );
  }

  _permissionTemplate() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _permissionIcon(),
        const SizedBox(height: 30.0),
        _permissionDescription(),
      ],
    );
  }

  _welcomeTemplate() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/logo/seeable_logo.svg',
          height: 300.0,
        ),
        const SizedBox(height: 30.0),
        TextFontStyle(
          description,
          size: fontSizeXXL,
          align: TextAlign.center,
        ),
      ],
    );
  }

  _permissionDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TextFontStyle(
        description,
        size: fontSizeXXL,
        align: TextAlign.center,
      ),
    );
  }

  _welcomeButton() {
    return CustomSubmitButton(
      onTap: next,
      title: 'start application'.tr,
      buttonWidth: Get.width - 100,
      buttonMargin: const EdgeInsets.symmetric(vertical: 50.0),
      borderRadius: 25.0,
      fontSize: fontSizeXL,
    );
  }

  _actionButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 30.0, right: 30.0, bottom: marginX2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: back,
            child: TextFontStyle(
              'back'.tr,
              size: fontSizeL,
            ),
          ),
          InkWell(
            onTap: next,
            child: Container(
              height: 50.0,
              width: 50.0,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

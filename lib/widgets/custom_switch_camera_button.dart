import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class CustomSwitchCameraButton extends StatelessWidget {
  final bool isFrontCamera;
  final Function() onTap;

  const CustomSwitchCameraButton({
    super.key,
    required this.isFrontCamera,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isFrontCamera ? 'using front camera'.tr : 'using back camera'.tr,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 50.0,
          width: 50.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Center(
            child: SvgPicture.asset('assets/icons/refresh_icon.svg'),
          ),
        ),
      ),
    );
  }
}

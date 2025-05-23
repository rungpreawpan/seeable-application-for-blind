import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSwitchCameraButton extends StatelessWidget {
  final Function() onTap;

  const CustomSwitchCameraButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
    );
  }
}

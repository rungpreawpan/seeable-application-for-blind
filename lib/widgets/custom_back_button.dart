import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';

class CustomBackButton extends StatelessWidget {
  final Function()? onTap;

  const CustomBackButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.back();

        if (onTap != null) {
          onTap;
        }
      },
      child: const Padding(
        padding: EdgeInsets.only(left: marginX2),
        child: CircleAvatar(
          backgroundColor: primaryColor,
          radius: 20,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 19,
            child: Icon(
              Icons.arrow_back_rounded,
              color: primaryColor,
              size: 30.0,
            ),
          ),
        ),
      ),
    );
  }
}

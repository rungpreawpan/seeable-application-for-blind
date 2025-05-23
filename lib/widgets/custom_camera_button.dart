import 'package:flutter/material.dart';

class CustomCameraButton extends StatelessWidget {
  final Function() onTap;

  const CustomCameraButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 70.0,
        width: 70.0,
        margin: const EdgeInsets.all(30.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35.0),
        ),
        child: Center(
          child: Container(
            height: 66.0,
            width: 66.0,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(33.0),
            ),
            child: Center(
              child: Container(
                height: 64.0,
                width: 64.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(33.0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

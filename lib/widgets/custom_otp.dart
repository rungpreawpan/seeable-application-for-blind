import 'package:flutter/material.dart';
import 'package:seeable/constant/value_constant.dart';

class CustomOtp extends StatelessWidget {
  final TextEditingController? textEditingController1;
  final TextEditingController? textEditingController2;
  final TextEditingController? textEditingController3;
  final TextEditingController? textEditingController4;
  final TextEditingController? textEditingController5;
  final TextEditingController? textEditingController6;
  final Color? borderColor;

  const CustomOtp({
    super.key,
    this.textEditingController1,
    this.textEditingController2,
    this.textEditingController3,
    this.textEditingController4,
    this.textEditingController5,
    this.textEditingController6,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OTPBox(
          textEditingController: textEditingController1,
          autoFocus: true,
          borderColor: borderColor,
        ),
        OTPBox(
          textEditingController: textEditingController2,
          borderColor: borderColor,
        ),
        OTPBox(
          textEditingController: textEditingController3,
          borderColor: borderColor,
        ),
        OTPBox(
          textEditingController: textEditingController4,
          borderColor: borderColor,
        ),
        OTPBox(
          textEditingController: textEditingController5,
          borderColor: borderColor,
        ),
        OTPBox(
          textEditingController: textEditingController6,
          borderColor: borderColor,
        ),
      ],
    );
  }
}

class OTPBox extends StatelessWidget {
  final bool autoFocus;
  final TextEditingController? textEditingController;
  final Color? borderColor;

  const OTPBox({
    super.key,
    this.autoFocus = false,
    this.textEditingController,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.0,
      width: 45.0,
      child: TextField(
        controller: textEditingController,
        maxLength: 1,
        autofocus: autoFocus,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          hintStyle: const TextStyle(
            color: Colors.black,
            fontSize: fontSizeXL,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: borderColor ?? Colors.blue,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1) {
            FocusScope.of(context).nextFocus();
          } else {
            if (!autoFocus) {
              FocusScope.of(context).previousFocus();
            }
          }
        },
      ),
    );
  }
}
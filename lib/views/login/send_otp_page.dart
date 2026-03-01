import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/login/controller/forget_password_controller.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_otp.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class SendOtpPage extends StatefulWidget {
  const SendOtpPage({super.key});

  @override
  State<SendOtpPage> createState() => _SendOtpPageState();
}

class _SendOtpPageState extends State<SendOtpPage> {
  final ForgetPasswordController _forgetPasswordController = Get.find();

  final TextEditingController _otp1Controller = TextEditingController();
  final TextEditingController _otp2Controller = TextEditingController();
  final TextEditingController _otp3Controller = TextEditingController();
  final TextEditingController _otp4Controller = TextEditingController();
  final TextEditingController _otp5Controller = TextEditingController();
  final TextEditingController _otp6Controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      showBackButton: true,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(marginX2),
              child: Column(
                children: [
                  _content(),
                  _sendOtpButton(),
                ],
              ),
            ),
          ),
          _loading(),
        ],
      ),
    );
  }

  _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomOtp(
          textEditingController1: _otp1Controller,
          textEditingController2: _otp2Controller,
          textEditingController3: _otp3Controller,
          textEditingController4: _otp4Controller,
          textEditingController5: _otp5Controller,
          textEditingController6: _otp6Controller,
        ),
        const SizedBox(height: marginX2),
        TextFontStyle(
          '${'ref code'.tr}: ${_forgetPasswordController.reference}',
          color: primaryColor,
        ),
        const SizedBox(height: marginX2),
      ],
    );
  }

  _sendOtpButton() {
    return CustomSubmitButton(
      onTap: () async {
        String otp1 = _otp1Controller.text;
        String otp2 = _otp2Controller.text;
        String otp3 = _otp3Controller.text;
        String otp4 = _otp4Controller.text;
        String otp5 = _otp5Controller.text;
        String otp6 = _otp6Controller.text;

        String otp = '$otp1$otp2$otp3$otp4$otp5$otp6';

        await _forgetPasswordController.validateSendOTP(otp: otp);
      },
      title: 'forget password'.tr,
    );
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _forgetPasswordController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

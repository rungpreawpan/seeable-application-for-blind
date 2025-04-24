import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/login/controller/forget_password_controller.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/custom_textfield.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final ForgetPasswordController _forgetPasswordController =
      Get.put(ForgetPasswordController());

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

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
                  _forgetPasswordButton(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFontStyle(
          'forget password'.tr,
          size: fontSizeXXL,
          weight: FontWeight.bold,
          color: primaryColor,
        ),
        const SizedBox(height: marginX2),
        CustomTextField(
          textEditingController: _usernameController,
          labelText: 'username'.tr,
        ),
        const SizedBox(height: marginX2),
        CustomTextField(
          textEditingController: _emailController,
          labelText: 'email'.tr,
        ),
        const SizedBox(height: marginX2),
      ],
    );
  }

  _forgetPasswordButton() {
    return CustomSubmitButton(
      onTap: () async {
        _forgetPasswordController.validateForgetPassword(
          username: _usernameController.text,
          email: _emailController.text,
        );
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/login/controller/forget_password_controller.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/custom_textfield.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final ForgetPasswordController _forgetPasswordController = Get.find();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

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
                  _resetPasswordButton(),
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
          'reset password'.tr,
          size: fontSizeXXL,
          weight: FontWeight.bold,
          color: primaryColor,
        ),
        const SizedBox(height: marginX2),
        CustomTextField(
          textEditingController: _newPasswordController,
          labelText: 'password'.tr,
          obscureText: _obscureNewPassword,
          suffix: Semantics(
            button: true,
            label:
                _obscureNewPassword ? 'hide password'.tr : 'show password'.tr,
            child: InkWell(
              onTap: () {
                _obscureNewPassword = !_obscureNewPassword;
                setState(() {});
              },
              child: Icon(
                _obscureNewPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Colors.grey,
                size: 20.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: marginX2),
        CustomTextField(
          textEditingController: _confirmPasswordController,
          labelText: 'confirm password'.tr,
          obscureText: _obscureConfirmPassword,
          suffix: Semantics(
            button: true,
            label: _obscureConfirmPassword
                ? 'hide password'.tr
                : 'show password'.tr,
            child: InkWell(
              onTap: () {
                _obscureConfirmPassword = !_obscureConfirmPassword;
                setState(() {});
              },
              child: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: Colors.grey,
                size: 20.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: marginX2),
      ],
    );
  }

  _resetPasswordButton() {
    return CustomSubmitButton(
      onTap: () async {
        await _forgetPasswordController.validateResetPassword(
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
      },
      title: 'reset password'.tr,
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

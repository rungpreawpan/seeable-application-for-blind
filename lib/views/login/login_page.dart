import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/login/controller/login_controller.dart';
import 'package:seeable/views/login/forget_password_page.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/custom_textfield.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController _loginController = Get.put(LoginController());

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(marginX2),
              child: Column(
                children: [
                  _content(),
                  _loginButton(),
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
    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFontStyle(
              'login'.tr,
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
              textEditingController: _passwordController,
              labelText: 'password'.tr,
              obscureText: _obscurePassword,
              suffix: InkWell(
                onTap: () {
                  _obscurePassword = !_obscurePassword;
                  setState(() {});
                },
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.grey,
                  size: 20.0,
                ),
              ),
            ),
            const SizedBox(height: marginX2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _redirectToRegister(),
                _forgetPasswordButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _redirectToRegister() {
    return InkWell(
      onTap: () {
        //TODO
      },
      child: TextFontStyle(
        'dont have account'.tr,
        color: primaryColor,
        underline: true,
      ),
    );
  }

  _forgetPasswordButton() {
    return InkWell(
      onTap: () {
        Get.to(() => const ForgetPasswordPage());
      },
      child: TextFontStyle(
        'forget password'.tr,
        color: primaryColor,
        underline: true,
      ),
    );
  }

  _loginButton() {
    return CustomSubmitButton(
      onTap: () async {
        await _loginController.validateLogin(
          username: _usernameController.text,
          password: _passwordController.text,
        );
      },
      title: 'login'.tr,
    );
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _loginController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

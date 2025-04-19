import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/app_info_controller.dart';
import 'package:seeable/views/login/controller/register_controller.dart';
import 'package:seeable/views/login/login_page.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/custom_textfield.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final RegisterController _registerController = Get.put(RegisterController());
  final AppInfoController _appInfoController = Get.find();

  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _uuidController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _getUuid();
  }

  _getUuid() {
    _uuidController.text = _appInfoController.uuid.value;
    setState(() {});
  }

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
                  _registerButton(),
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
              'register'.tr,
              size: fontSizeXXL,
              weight: FontWeight.bold,
              color: primaryColor,
            ),
            const SizedBox(height: marginX2),
            CustomTextField(
              textEditingController: _firstnameController,
              labelText: 'firstname'.tr,
            ),
            const SizedBox(height: marginX2),
            CustomTextField(
              textEditingController: _lastNameController,
              labelText: 'lastname'.tr,
            ),
            const SizedBox(height: marginX2),
            CustomTextField(
              textEditingController: _uuidController,
              labelText: 'uuid'.tr,
              isEnabled: false,
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
            ),
            const SizedBox(height: marginX2),
            CustomTextField(
              textEditingController: _emailController,
              labelText: 'email'.tr,
            ),
            const SizedBox(height: marginX2),
            _redirectToLogin(),
          ],
        ),
      ),
    );
  }

  _redirectToLogin() {
    return InkWell(
      onTap: () {
        Get.offAll(() => const LoginPage());
      },
      child: TextFontStyle(
        'already have account'.tr,
        color: primaryColor,
        underline: true,
      ),
    );
  }

  _registerButton() {
    return CustomSubmitButton(
      onTap: () async {
        await _registerController.validateRegister(
          firstname: _firstnameController.text,
          lastname: _lastNameController.text,
          uuid: _uuidController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          email: _emailController.text,
        );
      },
      title: 'register'.tr,
    );
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _registerController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

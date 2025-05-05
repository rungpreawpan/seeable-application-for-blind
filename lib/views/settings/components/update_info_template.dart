import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/login/controller/login_controller.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/main_template.dart';

class UpdateInfoTemplate extends StatefulWidget {
  final String appBarTitle;
  final Function()? onBack;
  final List<Widget> children;
  final bool isChange;
  final Function() onTap;

  const UpdateInfoTemplate({
    super.key,
    required this.appBarTitle,
    this.onBack,
    required this.children,
    required this.isChange,
    required this.onTap,
  });

  @override
  State<UpdateInfoTemplate> createState() => _UpdateInfoTemplateState();
}

class _UpdateInfoTemplateState extends State<UpdateInfoTemplate> {
  final LoginController _loginController = Get.find();

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: widget.appBarTitle,
      showBackButton: true,
      onBack: widget.onBack,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(marginX2),
              child: Column(
                children: [
                  _content(),
                  _button(),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.children,
        ),
      ),
    );
  }

  _button() {
    return widget.isChange
        ? CustomSubmitButton(
            onTap: widget.onTap,
            title: 'save'.tr,
          )
        : CustomSubmitButton(
            onTap: () {},
            title: 'save'.tr,
            fontColor: Colors.grey,
            showBorder: true,
            buttonColor: Colors.transparent,
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

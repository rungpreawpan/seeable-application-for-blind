import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/custom_textfield.dart';
import 'package:seeable/widgets/main_template.dart';

class ContactDevPage extends StatefulWidget {
  const ContactDevPage({super.key});

  @override
  State<ContactDevPage> createState() => _ContactDevPageState();
}

class _ContactDevPageState extends State<ContactDevPage> {
  final SettingsController _settingsController = Get.find();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'contact developer'.tr,
      showBackButton: true,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            textEditingController: _nameController,
            labelText: 'contact name'.tr,
          ),
          const SizedBox(height: marginX2),
          CustomTextField(
            textEditingController: _emailController,
            labelText: 'email'.tr,
          ),
          const SizedBox(height: marginX2),
          CustomTextField(
            textEditingController: _messageController,
            labelText: 'message'.tr,
            maxLine: 3,
          ),
        ],
      ),
    );
  }

  _button() {
    return CustomSubmitButton(
      onTap: () async {
        await _settingsController.contactDev(
          name: _nameController.text,
          email: _emailController.text,
          message: _messageController.text,
        );
      },
      title: 'send message'.tr,
    );
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _settingsController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

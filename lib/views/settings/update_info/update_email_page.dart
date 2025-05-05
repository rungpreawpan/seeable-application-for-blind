import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/login/controller/login_controller.dart';
import 'package:seeable/views/settings/components/update_info_template.dart';
import 'package:seeable/widgets/custom_textfield.dart';

class UpdateEmailPage extends StatefulWidget {
  final String uuid;
  final String? email;

  const UpdateEmailPage({
    super.key,
    required this.uuid,
    required this.email,
  });

  @override
  State<UpdateEmailPage> createState() => _UpdateEmailPageState();
}

class _UpdateEmailPageState extends State<UpdateEmailPage> {
  final LoginController _loginController = Get.find();

  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() {
    if (widget.email != null) {
      _emailController.text = widget.email ?? '';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return UpdateInfoTemplate(
      appBarTitle: 'email'.tr,
      isChange: _emailController.text != widget.email,
      onTap: () {
        _loginController.updateUser(
          uuid: widget.uuid,
          data: jsonEncode({
            'email': _emailController.text,
          }),
        );
      },
      children: [
        _email(),
      ],
    );
  }

  _email() {
    return CustomTextField(
      textEditingController: _emailController,
      labelText: 'email'.tr,
      onChanged: (value) {
        _emailController.text = value;
        setState(() {});
      },
    );
  }
}

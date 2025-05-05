import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/login/controller/login_controller.dart';
import 'package:seeable/views/settings/components/update_info_template.dart';
import 'package:seeable/widgets/custom_textfield.dart';

class UpdateUsernamePage extends StatefulWidget {
  final String uuid;
  final String? username;

  const UpdateUsernamePage({
    super.key,
    required this.uuid,
    required this.username,
  });

  @override
  State<UpdateUsernamePage> createState() => _UpdateUsernamePageState();
}

class _UpdateUsernamePageState extends State<UpdateUsernamePage> {
  final LoginController _loginController = Get.find();

  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() {
    if (widget.username != null) {
      _usernameController.text = widget.username ?? '';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return UpdateInfoTemplate(
      appBarTitle: 'username'.tr,
      isChange: _usernameController.text != widget.username,
      onTap: () {
        _loginController.updateUser(
          uuid: widget.uuid,
          data: jsonEncode({
            'username': _usernameController.text,
          }),
        );
      },
      children: [
        _username(),
      ],
    );
  }

  _username() {
    return CustomTextField(
      textEditingController: _usernameController,
      labelText: 'username'.tr,
      onChanged: (value) {
        _usernameController.text = value;
        setState(() {});
      },
    );
  }
}

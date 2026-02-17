import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/login/controller/login_controller.dart';
import 'package:seeable/views/settings/components/update_info_template.dart';
import 'package:seeable/widgets/custom_textfield.dart';

class UpdateNamePage extends StatefulWidget {
  final int? id;
  final String? firstname;
  final String? lastname;

  const UpdateNamePage({
    super.key,
    required this.id,
    required this.firstname,
    required this.lastname,
  });

  @override
  State<UpdateNamePage> createState() => _UpdateNamePageState();
}

class _UpdateNamePageState extends State<UpdateNamePage> {
  final LoginController _loginController = Get.find();

  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() {
    if (widget.firstname != null) {
      _firstnameController.text = widget.firstname ?? '';
    }

    if (widget.lastname != null) {
      _lastnameController.text = widget.lastname ?? '';
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return UpdateInfoTemplate(
      appBarTitle: 'name'.tr,
      isChange: _firstnameController.text != widget.firstname ||
          _lastnameController.text != widget.lastname,
      onTap: () {
        _loginController.updateUser(
          id: widget.id,
          data: jsonEncode({
            'firstname': _firstnameController.text,
            'lastname': _lastnameController.text,
          }),
        );
      },
      children: [
        _firstname(),
        const SizedBox(height: marginX2),
        _lastname(),
      ],
    );
  }

  _firstname() {
    return CustomTextField(
      textEditingController: _firstnameController,
      labelText: 'firstname'.tr,
      onChanged: (value) {
        _firstnameController.text = value;
        setState(() {});
      },
    );
  }

  _lastname() {
    return CustomTextField(
      textEditingController: _lastnameController,
      labelText: 'lastname'.tr,
      onChanged: (value) {
        _lastnameController.text = value;
        setState(() {});
      },
    );
  }
}

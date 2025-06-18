import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/app_info_controller.dart';
import 'package:seeable/views/login/controller/login_controller.dart';
import 'package:seeable/views/settings/components/update_info_template.dart';
import 'package:seeable/widgets/custom_textfield.dart';
import 'package:seeable/widgets/text_font_style.dart';

class UpdateUuidPage extends StatefulWidget {
  final String uuid;

  const UpdateUuidPage({
    super.key,
    required this.uuid,
  });

  @override
  State<UpdateUuidPage> createState() => _UpdateUuidPageState();
}

class _UpdateUuidPageState extends State<UpdateUuidPage> {
  final AppInfoController _appInfoController = Get.find();
  final LoginController _loginController = Get.find();

  final TextEditingController _uuidController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() {
    _uuidController.text = widget.uuid;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return UpdateInfoTemplate(
      appBarTitle: 'uuid'.tr,
      isChange: _uuidController.text != widget.uuid,
      onTap: () {
        _loginController.updateUser(
          uuid: widget.uuid,
          data: jsonEncode({
            'newUuid': _uuidController.text,
          }),
        );
      },
      children: [
        _uuid(),
      ],
    );
  }

  _uuid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                isEnabled: false,
                textEditingController: _uuidController,
                labelText: 'registered uuid'.tr,
                onChanged: (value) {
                  _uuidController.text = value;
                  setState(() {});
                },
              ),
            ),
            Visibility(
              visible: widget.uuid != _appInfoController.uuid.value,
              child: Row(
                children: [
                  const SizedBox(width: margin),
                  InkWell(
                    onTap: () {
                      _uuidController.text = _appInfoController.uuid.value;
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Visibility(
          visible: widget.uuid != _appInfoController.uuid.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 20.0,
                  ),
                  const SizedBox(width: margin),
                  TextFontStyle(
                    'uuid not match'.tr,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

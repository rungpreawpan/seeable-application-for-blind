import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/login/controller/login_controller.dart';
import 'package:seeable/views/login/model/user_model.dart';
import 'package:seeable/views/settings/components/settings_label.dart';
import 'package:seeable/views/settings/update_info/update_email_page.dart';
import 'package:seeable/views/settings/update_info/update_name_page.dart';
import 'package:seeable/views/settings/update_info/update_username_page.dart';
import 'package:seeable/widgets/main_template.dart';

class UpdateUserInfoPage extends StatefulWidget {
  const UpdateUserInfoPage({super.key});

  @override
  State<UpdateUserInfoPage> createState() => _UpdateUserInfoPageState();
}

class _UpdateUserInfoPageState extends State<UpdateUserInfoPage> {
  final LoginController _loginController = Get.put(LoginController());

  FlutterSecureStorage storage = const FlutterSecureStorage();

  UserModel? userInfo;

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() async {
    String? userData = await storage.read(key: 'user_data');

    if (userData != null) {
      Map<String, dynamic> userDataMap = json.decode(userData);
      userInfo = UserModel.fromJSON(userDataMap);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'user information'.tr,
      showBackButton: true,
      body: SafeArea(
        child: _content(),
      ),
    );
  }

  _content() {
    return Padding(
      padding: const EdgeInsets.all(marginX2),
      child: Column(
        children: [
          SettingsLabel(
            title: 'name'.tr,
            settingsLabelStyle: SettingsLabelStyle.updateInfo,
            buttonInitialValue:
                userInfo?.firstname != null && userInfo?.lastname != null
                    ? '${userInfo!.firstname} ${userInfo!.lastname}'
                    : '-',
            onTap: () async {
              bool? result = await Get.to(
                () => UpdateNamePage(
                  id: userInfo?.id ?? 0,
                  firstname: userInfo?.firstname,
                  lastname: userInfo?.lastname,
                ),
              );

              if (result != null) {
                _prepareData();
              }
            },
          ),
          _divider(),
          SettingsLabel(
            title: 'email'.tr,
            settingsLabelStyle: SettingsLabelStyle.updateInfo,
            buttonInitialValue:
                userInfo?.email != null ? '${userInfo!.email}' : '-',
            onTap: () async {
              bool? result = await Get.to(
                () => UpdateEmailPage(
                  id: userInfo?.id,
                  email: userInfo?.email,
                ),
              );

              if (result != null) {
                _prepareData();
              }
            },
          ),
          _divider(),
          SettingsLabel(
            title: 'username'.tr,
            settingsLabelStyle: SettingsLabelStyle.updateInfo,
            buttonInitialValue:
                userInfo?.username != null ? '${userInfo!.username}' : '-',
            onTap: () async {
              bool? result = await Get.to(
                () => UpdateUsernamePage(
                  id: userInfo?.id,
                  username: userInfo?.username,
                ),
              );

              if (result != null) {
                _prepareData();
              }
            },
          ),
        ],
      ),
    );
  }

  _divider() {
    return Divider(
      color: Colors.grey.shade300,
      thickness: 1.0,
      height: 40.0,
    );
  }
}

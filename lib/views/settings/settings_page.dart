import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/login/login_page.dart';
import 'package:seeable/widgets/custom_ok_cancel_dialog.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'settings'.tr,
      showBackButton: false,
      body: Column(
        children: [
          _logoutButton(),
        ],
      ),
    );
  }

  _logoutButton() {
    return InkWell(
      onTap: () {
        Get.dialog(
          CustomOkCancelDialog(
            title: 'ต้องการออกจากระบบหรือไม่', //TODO eng
            onOK: () async {
              FlutterSecureStorage storage = const FlutterSecureStorage();
              await storage.delete(key: 'login');

              Get.offAll(() => const LoginPage());
            },
          ),
        );
      },
      child: TextFontStyle(
        'logout'.tr,
        size: fontSizeL,
        weight: FontWeight.bold,
        color: primaryColor,
        underline: true,
      ),
    );
  }
}

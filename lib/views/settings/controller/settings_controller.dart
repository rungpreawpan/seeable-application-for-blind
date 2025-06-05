import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/settings/model/settings_model.dart';
import 'package:seeable/widgets/custom_alert_dialog.dart';

class SettingsController extends GetxController {
  var isLoading = false.obs;

  final storage = const FlutterSecureStorage();
  var themeMode = ThemeMode.light.obs;
  var locale = 'th'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromSettings();
  }

  //TODO: แก้ไขเวลาตั้งค่าว่าsystemแล้วไม่ยอมเปลี่ยนตามsystemจริงๆ
  void setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);

    final existingData = await storage.read(key: 'settings_value');
    SettingsModel settings;

    if (existingData != null) {
      settings = SettingsModel.fromJSON(json.decode(existingData));
    } else {
      settings = SettingsModel();
    }

    settings.theme = _themeModeToString(mode);

    await storage.write(
        key: 'settings_value', value: jsonEncode(settings.toJSON()));
  }

  Future<void> _loadThemeFromSettings() async {
    final data = await storage.read(key: 'settings_value');

    if (data != null) {
      try {
        final jsonData = json.decode(data);
        final settings = SettingsModel.fromJSON(jsonData);

        switch (settings.theme?.toLowerCase()) {
          case 'light':
            themeMode.value = ThemeMode.light;
            break;
          case 'dark':
            themeMode.value = ThemeMode.dark;
            break;
          case 'system default':
            themeMode.value = ThemeMode.system;
            break;
          default:
            themeMode.value = ThemeMode.light;
        }
        Get.changeThemeMode(themeMode.value);
      } catch (e) {
        themeMode.value = ThemeMode.light;
        Get.changeThemeMode(ThemeMode.light);
      }
    } else {
      themeMode.value = ThemeMode.light;
      Get.changeThemeMode(ThemeMode.light);
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system default';
    }
  }

  //TODO
  void setLanguage(ThemeMode mode) async {
    // themeMode.value = mode;
    // Get.changeThemeMode(mode);
    //
    // final existingData = await storage.read(key: 'settings_value');
    // SettingsModel settings;
    //
    // if (existingData != null) {
    //   settings = SettingsModel.fromJSON(json.decode(existingData));
    // } else {
    //   settings = SettingsModel();
    // }
    //
    // settings.theme = _themeModeToString(mode);
    //
    // await storage.write(
    //     key: 'settings_value', value: jsonEncode(settings.toJSON()));
  }

  //TODO
  Future<void> _loadLanguageFromSettings() async {
    final data = await storage.read(key: 'settings_value');

    if (data != null) {
      try {
        final jsonData = json.decode(data);
        final settings = SettingsModel.fromJSON(jsonData);

        switch (settings.language?.toLowerCase()) {
          case 'thai':
            locale.value = 'th';
            break;
          case 'english':
            locale.value = 'en';
            break;
          default:
        }
        Get.updateLocale(Locale(locale.value));
      } catch (e) {
        locale.value = 'th';
        Get.updateLocale(Locale(locale.value));
      }
    } else {
      locale.value = 'th';
      Get.updateLocale(Locale(locale.value));
    }
  }

  contactDev({
    required String name,
    required String email,
    required String message,
  }) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('ไม่มีสัญญาณอินเตอร์เน็ต');
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/contact-dev',
        method: HttpMethod.post,
        data: {
          'name': name,
          'email': email,
          'message': message,
        },
      );

      if (response != null && response.statusCode == 200) {
        Get.dialog(
          CustomAlertDialog(
            title: 'send message successfully'.tr,
            onOk: () {
              Get.back();
            },
          ),
        );
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

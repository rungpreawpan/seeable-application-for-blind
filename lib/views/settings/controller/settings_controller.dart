import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/controller/tts_manager.dart';
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/settings/model/settings_model.dart';
import 'package:seeable/widgets/custom_alert_dialog.dart';

class SettingsController extends GetxController {
  var isLoading = false.obs;

  final ttsManager = TtsManager();
  final storage = const FlutterSecureStorage();
  var themeMode = ThemeMode.light.obs;
  var currentLocale = const Locale('th', 'TH').obs;
  var speechSpeed = 'normal'.obs;
  var useSpeechRecognition = true.obs;

  @override
  void onInit() async {
    super.onInit();

    await loadUseSpeechRecognition();
    await loadSpeechSpeedFromSettings();
    await loadLanguageFromSettings();
    await loadThemeFromSettings();
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

    settings.theme = themeModeToString(mode);

    await storage.write(
        key: 'settings_value', value: jsonEncode(settings.toJSON()));
  }

  Future<void> loadThemeFromSettings() async {
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

  String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system default';
    }
  }

  void setLanguage(Locale locale) async {
    currentLocale.value = locale;
    Get.updateLocale(locale);

    final existingData = await storage.read(key: 'settings_value');
    SettingsModel settings;

    if (existingData != null) {
      settings = SettingsModel.fromJSON(json.decode(existingData));
    } else {
      settings = SettingsModel();
    }

    settings.language = languageToString(locale);

    await storage.write(
        key: 'settings_value', value: jsonEncode(settings.toJSON()));
  }

  Future<void> loadLanguageFromSettings() async {
    final data = await storage.read(key: 'settings_value');

    if (data != null) {
      try {
        final jsonData = json.decode(data);
        final settings = SettingsModel.fromJSON(jsonData);

        switch (settings.language?.toLowerCase()) {
          case 'thai':
            currentLocale.value = languageNameToLocale('thai');
            break;
          case 'english':
            currentLocale.value = languageNameToLocale('english');
            break;
          default:
            currentLocale.value = languageNameToLocale('thai');
        }

        Get.updateLocale(currentLocale.value);
      } catch (e) {
        currentLocale.value = languageNameToLocale('thai');
        Get.updateLocale(currentLocale.value);
      }
    } else {
      currentLocale.value = languageNameToLocale('thai');
      Get.updateLocale(currentLocale.value);
    }
  }

  String languageToString(Locale locale) {
    switch (locale.languageCode) {
      case 'th':
        return 'thai';
      case 'en':
        return 'english';
      default:
        return 'thai';
    }
  }

  Locale languageNameToLocale(String name) {
    switch (name.toLowerCase()) {
      case 'thai':
        return const Locale('th', 'TH');
      case 'english':
        return const Locale('en', 'US');
      default:
        return const Locale('th', 'TH');
    }
  }

  String localeToString(Locale locale) {
    return '${locale.languageCode}-${locale.countryCode}';
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

  void setSpeechSpeed(String? speed) async {
    speechSpeed.value = 'normal';

    final existingData = await storage.read(key: 'settings_value');
    SettingsModel settings;

    if (existingData != null) {
      settings = SettingsModel.fromJSON(json.decode(existingData));
    } else {
      settings = SettingsModel();
    }

    print(speed);

    settings.speed = speed;
    speechSpeed.value = speed ?? 'normal';
    await ttsManager.setSpeechSpeed(speechSpeed.value);

    await storage.write(
        key: 'settings_value', value: jsonEncode(settings.toJSON()));
  }

  Future<void> loadSpeechSpeedFromSettings() async {
    final data = await storage.read(key: 'settings_value');

    if (data != null) {
      try {
        final jsonData = json.decode(data);
        final settings = SettingsModel.fromJSON(jsonData);

        switch (settings.speed?.toLowerCase()) {
          case 'normal':
            speechSpeed.value = 'normal';
            break;
          case 'slow':
            speechSpeed.value = 'slow';
            break;
          case 'fast':
            speechSpeed.value = 'fast';
            break;
          default:
            speechSpeed.value = 'normal';
        }
      } catch (e) {
        speechSpeed.value = 'normal';
      }
    } else {
      speechSpeed.value = 'normal';
    }

    await ttsManager.setSpeechSpeed(speechSpeed.value);
  }

  void setUseSpeechRecognition(bool? useRecognition) async {
    useSpeechRecognition.value = true;

    final existingData = await storage.read(key: 'settings_value');
    SettingsModel settings;

    if (existingData != null) {
      settings = SettingsModel.fromJSON(json.decode(existingData));
    } else {
      settings = SettingsModel();
    }

    settings.useSpeechRecognition = useRecognition;
    useSpeechRecognition.value = useRecognition ?? true;

    await storage.write(
        key: 'settings_value', value: jsonEncode(settings.toJSON()));
  }

  Future<void> loadUseSpeechRecognition() async {
    final data = await storage.read(key: 'settings_value');

    if (data != null) {
      try {
        final jsonData = json.decode(data);
        final settings = SettingsModel.fromJSON(jsonData);

        switch (settings.useSpeechRecognition) {
          case true:
            useSpeechRecognition.value = true;
            break;
          case false:
            useSpeechRecognition.value = false;
            break;
          default:
            useSpeechRecognition.value = true;
        }
      } catch (e) {
        useSpeechRecognition.value = true;
      }
    } else {
      useSpeechRecognition.value = true;
    }
  }
}

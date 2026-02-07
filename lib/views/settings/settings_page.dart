import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/app_info_controller.dart';
import 'package:seeable/views/login/login_page.dart';
import 'package:seeable/views/login/model/user_model.dart';
import 'package:seeable/views/settings/components/settings_label.dart';
import 'package:seeable/views/settings/contact_dev_page.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/views/settings/model/settings_model.dart';
import 'package:seeable/views/settings/update_user_info_page.dart';
import 'package:seeable/widgets/custom_item_picker.dart';
import 'package:seeable/widgets/custom_item_picker_cell.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_ok_cancel_dialog.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppInfoController _appInfoController = Get.find();
  final SettingsController _settingsController = Get.find();

  FlutterSecureStorage storage = const FlutterSecureStorage();

  List<String> get speedList => ['slow'.tr, 'normal'.tr, 'fast'.tr];

  List<String> get languageList => ['thai'.tr, 'english'.tr];

  List<String> get themeList => ['light'.tr, 'dark'.tr];

  bool useSpeechRecognition = false;
  List<String> selectedSpeed = [];
  List<String> selectedLanguage = [];
  List<String> selectedTheme = [];

  UserModel? userInfo;
  SettingsModel? settingsInfo;

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() async {
    String? userData = await storage.read(key: 'user_data');
    String? settingsData = await storage.read(key: 'settings_value');

    if (userData != null) {
      Map<String, dynamic> userDataMap = json.decode(userData);
      userInfo = UserModel.fromJSON(userDataMap);
    }

    if (settingsData != null) {
      Map<String, dynamic> settingsValueMap = json.decode(settingsData);
      settingsInfo = SettingsModel.fromJSON(settingsValueMap);
      _setUseSpeechRecognition();
      _setSpeedValue();
      _setLanguageValue();
      _setThemeValue();
    }

    setState(() {});
  }

  _setUseSpeechRecognition() {
    useSpeechRecognition = _settingsController.useSpeechRecognition.value;
  }

  _setSpeedValue() {
    selectedSpeed.clear();

    if (settingsInfo?.speed == 'slow') {
      selectedSpeed.add('slow'.tr);
    } else if (settingsInfo?.speed == 'normal') {
      selectedSpeed.add('normal'.tr);
    } else if (settingsInfo?.speed == 'fast') {
      selectedSpeed.add('fast'.tr);
    } else {
      selectedSpeed.add('normal'.tr);
    }
  }

  _setLanguageValue() {
    selectedLanguage.clear();

    if (settingsInfo?.language == 'thai') {
      selectedLanguage.add('thai'.tr);
    } else if (settingsInfo?.language == 'english') {
      selectedLanguage.add('english'.tr);
    } else {
      selectedLanguage.add('thai'.tr);
    }
  }

  _setThemeValue() {
    selectedTheme.clear();

    if (settingsInfo?.theme == 'light') {
      selectedTheme.add('light'.tr);
    } else if (settingsInfo?.theme == 'dark') {
      selectedTheme.add('dark'.tr);
    } else {
      selectedSpeed.add('light'.tr);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MainTemplate(
      appBarTitle: 'settings'.tr,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _content(theme),
                  const SizedBox(height: marginX2),
                  _logoutButton(),
                ],
              ),
            ),
          ),
          _loading(),
        ],
      ),
    );
  }

  _content(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _userInfo(theme),
        _sound(theme),
        _divider(),
        _userInterface(theme),
        _divider(),
        _aboutApplication(theme),
      ],
    );
  }

  _userInfo(ThemeData theme) {
    return InkWell(
      onTap: () {
        Get.to(() => const UpdateUserInfoPage());
      },
      child: Container(
        width: Get.width,
        padding: const EdgeInsets.only(
          left: marginX2,
          right: margin,
          top: marginX2,
          bottom: marginX2,
        ),
        margin: const EdgeInsets.all(marginX2),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFontStyle(
                    userInfo?.firstname != null && userInfo?.lastname != null
                        ? '${userInfo!.firstname} ${userInfo!.lastname}'
                        : '-',
                    size: fontSizeXL,
                    weight: FontWeight.bold,
                  ),
                  const SizedBox(height: margin),
                  TextFontStyle(
                    userInfo?.email != null ? '${userInfo!.email}' : '-',
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.navigate_next_rounded,
              size: 30.0,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  _sound(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: marginX2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFontStyle(
            'sound'.tr,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: marginX2),
          SettingsLabel(
            title: 'voice control'.tr,
            settingsLabelStyle: SettingsLabelStyle.onOff,
            switchValue: useSpeechRecognition,
            onChanged: (value) async {
              useSpeechRecognition = !useSpeechRecognition;
              _settingsController.useSpeechRecognition.value =
                  useSpeechRecognition;

              _settingsController.setUseSpeechRecognition(
                  _settingsController.useSpeechRecognition.value);

              setState(() {});
            },
          ),
          const SizedBox(height: marginX2),
          SettingsLabel(
            title: 'speech speed'.tr,
            buttonInitialValue:
                selectedSpeed.isNotEmpty ? selectedSpeed.first : 'normal'.tr,
            settingsLabelStyle: SettingsLabelStyle.interact,
            onTap: () async {
              List? result = await Get.to(
                () => CustomItemPicker(
                  title: 'speech speed'.tr,
                  items: speedList,
                  selectedItems: selectedSpeed,
                  showSearchBar: false,
                  pickMultipleItem: false,
                  onSearch: (String searchText) {},
                  itemWidget: (item, isSelected) {
                    return CustomItemPickerCell(
                      title: item,
                      isSelected: isSelected,
                    );
                  },
                ),
              );

              if (result != null) {
                String speed;
                if (selectedSpeed.first == 'slow'.tr) {
                  speed = 'slow';
                } else if (selectedSpeed.first == 'fast'.tr) {
                  speed = 'fast';
                } else {
                  speed = 'normal';
                }

                _settingsController.setSpeechSpeed(speed);

                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  _userInterface(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: marginX2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFontStyle(
            'user interface'.tr,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: marginX2),
          SettingsLabel(
            title: 'language'.tr,
            buttonInitialValue: selectedLanguage.isNotEmpty
                ? selectedLanguage.first
                : 'thai'.tr,
            settingsLabelStyle: SettingsLabelStyle.interact,
            onTap: () async {
              List? result = await Get.to(
                () => CustomItemPicker(
                  title: 'language'.tr,
                  items: languageList,
                  selectedItems: selectedLanguage,
                  showSearchBar: false,
                  pickMultipleItem: false,
                  onSearch: (String searchText) {},
                  itemWidget: (item, isSelected) {
                    return CustomItemPickerCell(
                      title: item,
                      isSelected: isSelected,
                    );
                  },
                ),
              );

              if (result != null) {
                Locale locale;

                if (selectedLanguage.first == 'thai'.tr) {
                  locale = _settingsController.languageNameToLocale('thai');
                } else {
                  locale = _settingsController.languageNameToLocale('english');
                }

                _settingsController.setLanguage(locale);
                await _prepareData();

                setState(() {});
              }
            },
          ),
          const SizedBox(height: marginX2),
          SettingsLabel(
            title: 'theme'.tr,
            buttonInitialValue: selectedTheme.isNotEmpty
                ? selectedTheme.first
                : 'light'.tr,
            settingsLabelStyle: SettingsLabelStyle.interact,
            onTap: () async {
              List? result = await Get.to(
                () => CustomItemPicker(
                  title: 'theme'.tr,
                  items: themeList,
                  selectedItems: selectedTheme,
                  showSearchBar: false,
                  pickMultipleItem: false,
                  onSearch: (searchText) {},
                  itemWidget: (item, isSelected) {
                    return CustomItemPickerCell(
                      title: item,
                      isSelected: isSelected,
                    );
                  },
                ),
              );

              if (result != null) {
                ThemeMode mode;

                if (selectedTheme.first == 'light'.tr) {
                  mode = ThemeMode.light;
                } else if (selectedTheme.first == 'dark'.tr) {
                  mode = ThemeMode.dark;
                } else {
                  mode = ThemeMode.system;
                }

                _settingsController.setThemeMode(mode);

                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  _aboutApplication(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: marginX2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFontStyle(
            'about application'.tr,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: marginX2),
          SettingsLabel(
            title: 'contact developer'.tr,
            settingsLabelStyle: SettingsLabelStyle.interact,
            onTap: () {
              Get.to(() => const ContactDevPage());
            },
          ),
          const SizedBox(height: marginX2),
          SettingsLabel(
            title: 'application version'.tr,
            buttonInitialValue: _appInfoController.appVersion.value,
            settingsLabelStyle: SettingsLabelStyle.showData,
          ),
        ],
      ),
    );
  }

  _logoutButton() {
    return InkWell(
      onTap: () {
        Get.dialog(
          CustomOkCancelDialog(
            title: 'do you want to logout'.tr,
            onOK: () async {
              FlutterSecureStorage storage = const FlutterSecureStorage();
              await storage.delete(key: 'login');

              Get.offAll(() => const LoginPage());
            },
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(marginX2),
        child: TextFontStyle(
          'logout'.tr,
          size: fontSizeL,
          weight: FontWeight.bold,
          color: _settingsController.themeMode.value == ThemeMode.light
              ? primaryColor
              : Colors.white,
          underline: true,
        ),
      ),
    );
  }

  _divider() {
    return Divider(
      color: Colors.grey.shade300,
      indent: marginX2,
      endIndent: marginX2,
      thickness: 1.0,
      height: 50.0,
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

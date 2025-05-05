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
import 'package:share_plus/share_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppInfoController _appInfoController = Get.find();
  final SettingsController _settingsController = Get.put(SettingsController());

  FlutterSecureStorage storage = const FlutterSecureStorage();

  bool _speechRecognitionValue = false;

  final List<String> speedList = ['slow'.tr, 'normal'.tr, 'fast'.tr];
  final List<String> languageList = ['thai'.tr, 'english'.tr];
  final List<String> themeList = ['system default'.tr, 'light'.tr, 'dark'.tr];

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
      _setSpeechRecognition();
      _setSpeedValue();
      _setLanguageValue();
      _setThemeValue();
    }

    setState(() {});
  }

  _setSpeechRecognition() {
    _speechRecognitionValue =
        settingsInfo?.useSpeechRecognition == true ? true : false;
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

    if (settingsInfo?.theme == 'system default') {
      selectedTheme.add('system default'.tr);
    } else if (settingsInfo?.theme == 'light') {
      selectedTheme.add('light'.tr);
    } else if (settingsInfo?.theme == 'dark') {
      selectedTheme.add('dark'.tr);
    } else {
      selectedSpeed.add('normal'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'settings'.tr,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _content(),
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

  _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _userInfo(),
        _sound(),
        _divider(),
        _userInterface(),
        _divider(),
        _aboutApplication(),
      ],
    );
  }

  _userInfo() {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: customBoxShadow,
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
                    overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }

  _sound() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: marginX2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFontStyle(
            'sound'.tr,
            size: fontSizeXL,
            weight: FontWeight.bold,
          ),
          const SizedBox(height: marginX2),
          SettingsLabel(
            title: 'voice control'.tr,
            settingsLabelStyle: SettingsLabelStyle.onOff,
            switchValue: _speechRecognitionValue,
            onChanged: (value) {
              _speechRecognitionValue = !_speechRecognitionValue;
              setState(() {});
            },
          ),
          const SizedBox(height: marginX2),
          SettingsLabel(
            title: 'speech speed'.tr,
            buttonInitialValue:
                selectedSpeed.isNotEmpty ? selectedSpeed.first : 'test', //TODO
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
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  _userInterface() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: marginX2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFontStyle(
            'user interface'.tr,
            size: fontSizeXL,
            weight: FontWeight.bold,
          ),
          const SizedBox(height: marginX2),
          SettingsLabel(
            title: 'language'.tr,
            buttonInitialValue: selectedLanguage.isNotEmpty
                ? selectedLanguage.first
                : 'test', //TODO:
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
                setState(() {});
              }
            },
          ),
          const SizedBox(height: marginX2),
          SettingsLabel(
            title: 'theme'.tr,
            buttonInitialValue:
                selectedTheme.isNotEmpty ? selectedTheme.first : 'test', //TODO:
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
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  _aboutApplication() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: marginX2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFontStyle(
            'about application'.tr,
            size: fontSizeXL,
            weight: FontWeight.bold,
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
            title: 'share application'.tr,
            settingsLabelStyle: SettingsLabelStyle.interact,
            onTap: () async {
              //TODO: add link
              await SharePlus.instance.share(
                ShareParams(
                  text: 'download seeable app for android and ios'.tr,
                ),
              );
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
          color: primaryColor,
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

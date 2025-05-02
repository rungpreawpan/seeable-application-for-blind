import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/app_info_controller.dart';
import 'package:seeable/views/login/login_page.dart';
import 'package:seeable/views/settings/components/settings_label.dart';
import 'package:seeable/views/settings/contact_dev_page.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
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
  final SettingsController _settingsController = Get.put(SettingsController());

  bool _speechRecognitionValue = false;

  final List<String> speedList = ['slow'.tr, 'normal'.tr, 'fast'.tr];
  final List<String> languageList = ['thai'.tr, 'english'.tr];
  final List<String> themeList = ['system default'.tr, 'light'.tr, 'dark'.tr];

  List<String> selectedSpeed = [];
  List<String> selectedLanguage = [];
  List<String> selectedTheme = [];

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'settings'.tr,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(marginX2),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _content(),
                    const SizedBox(height: 20.0),
                    _logoutButton(),
                  ],
                ),
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
        _sound(),
        const Divider(
          color: Colors.black54,
          thickness: 1.0,
          height: 50.0,
        ),
        _userInterface(),
        const Divider(
          color: Colors.black54,
          thickness: 1.0,
          height: 50.0,
        ),
        _aboutApplication(),
      ],
    );
  }

  _sound() {
    return Column(
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
          settingsLabelStyle: SettingsLabelStyle.dialog,
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
    );
  }

  _userInterface() {
    return Column(
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
          settingsLabelStyle: SettingsLabelStyle.dialog,
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
          settingsLabelStyle: SettingsLabelStyle.dialog,
          onTap: () async {
            List? result = await Get.to(
              () => CustomItemPicker(
                title: 'theme'.tr,
                items: themeList,
                selectedItems: selectedTheme,
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
    );
  }

  _aboutApplication() {
    return Column(
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
          onTap: () {},
        ),
        const SizedBox(height: marginX2),
        SettingsLabel(
          title: 'application version'.tr,
          buttonInitialValue: _appInfoController.appVersion.value,
          settingsLabelStyle: SettingsLabelStyle.showData,
        ),
      ],
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

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _settingsController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/navigation/controller/ble_controller.dart';
import 'package:seeable/views/navigation/select_building_page.dart';
import 'package:seeable/views/object_detection/object_detection_page.dart';
import 'package:seeable/views/scan_text/scan_text_page.dart';
import 'package:seeable/views/settings/settings_page.dart';
import 'package:seeable/widgets/listview_button.dart';
import 'package:seeable/widgets/navigation_main_template.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BleController _bleController = Get.put(BleController());

  List featuresList = [
    {'title': 'navigation'.tr, 'icon_path': 'assets/icons/navigation_icon.svg'},
    {
      'title': 'object detection'.tr,
      'icon_path': 'assets/icons/object_detect_icon.svg'
    },
    {'title': 'scan text'.tr, 'icon_path': 'assets/icons/scan_text_icon.svg'},
    {'title': 'settings'.tr, 'icon_path': 'assets/icons/settings_icon.svg'}
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationMainTemplate(
      appBarTitle: '',
      items: featuresList,
      itemWidget: (context, index) {
        var item = featuresList[index];

        return ListViewButton(
          onTap: () {
            if (item['title'] == 'navigation'.tr) {
              Get.to(() => const SelectBuildingPage());
            } else if (item['title'] == 'object detection'.tr) {
              Get.to(() => const ObjectDetectionPage());
              // Get.to(() => const CameraDetectionPage());
            } else if (item['title'] == 'scan text'.tr) {
              Get.to(() => const ScanTextPage());
            } else if (item['title'] == 'settings'.tr) {
              Get.to(() => const SettingsPage());
            } else {
              Get.offAll(() => const HomePage());
            }
          },
          iconPath: item['icon_path'],
          title: item['title'],
          showArrow: false,
        );
      },
    );
  }
}

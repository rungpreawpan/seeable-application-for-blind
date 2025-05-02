import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/navigation/ble_with_server/location/location_list_page.dart';
import 'package:seeable/views/navigation/controller/ble_controller.dart';
import 'package:seeable/views/object_detection/object_detect_server/object_detect_server_page.dart';
import 'package:seeable/views/object_detection/test/realtime_page.dart';
import 'package:seeable/views/object_detection/test_label/image_label_page.dart';
import 'package:seeable/views/object_detection/test_ml_kit/object_detect_ml_kit.dart';
import 'package:seeable/views/object_detection/test_ml_kit/test_ml_kit.dart';
import 'package:seeable/views/scan_text/scan_text_page.dart';
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
              // Get.to(() => const SelectBuildingPage());
              Get.to(() => const LocationListPage());
            } else if (item['title'] == 'object detection'.tr) {
              // Get.to(() => const ObjectDetectionPage());
              // Get.to(() => const RealtimeObjectDetectionPage());
              // Get.to(() => const RealtimePage());
              //  Get.to(() => TestMlKit()); //ObjectDetectMlKit
              // Get.to(() => const CameraObjectDetectionPage());
              // Get.to(() => ImageLabelingExample());
              Get.to(() => const ObjectDetectServerPage());
            } else if (item['title'] == 'scan text'.tr) {
              Get.to(() => const ScanTextPage());
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

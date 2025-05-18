import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/controller/app_info_controller.dart';
import 'package:seeable/views/login/model/user_model.dart';
import 'package:seeable/views/navigation/ble_with_server/location/location_list_page.dart';
import 'package:seeable/views/navigation/controller/ble_controller.dart';
import 'package:seeable/views/object_detection/server/object_detect_server_page.dart';
import 'package:seeable/views/scan_text/real_time_scan_text_page.dart';
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
  final AppInfoController _appInfoController = Get.find();
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

  FlutterSecureStorage storage = const FlutterSecureStorage();

  UserModel? userInfo;

  List featuresList = [
    {'title': 'navigation'.tr, 'icon_path': 'assets/icons/navigation_icon.svg'},
    {
      'title': 'object detection'.tr,
      'icon_path': 'assets/icons/object_detect_icon.svg'
    },
    {'title': 'scan text'.tr, 'icon_path': 'assets/icons/scan_text_icon.svg'},
  ];

  @override
  void initState() {
    super.initState();

    _startAdvertiseBluetooth();
  }

  _stopAdvertiseBluetooth() async {
    if (await FlutterBlePeripheral().isAdvertising) {
      await FlutterBlePeripheral().stop();
    }
  }

  _startAdvertiseBluetooth() async {
    String? userData = await storage.read(key: 'user_data');

    if (userData == null) return;

    Map<String, dynamic> userDataMap = json.decode(userData);
    userInfo = UserModel.fromJSON(userDataMap);

    String convertHexToUUID(String hex) {
      String padded = hex.padRight(32, '0');
      return '${padded.substring(0, 8)}-'
          '${padded.substring(8, 12)}-'
          '${padded.substring(12, 16)}-'
          '${padded.substring(16, 20)}-'
          '${padded.substring(20, 32)}';
    }

    AdvertiseData advertiseData = AdvertiseData(
      serviceUuid: convertHexToUUID(userInfo!.uuid!),
      localName: 'seeable',
      manufacturerId: 1234,
      manufacturerData: Uint8List.fromList('seeable-${userInfo!.uuid!}'.codeUnits),
      includeDeviceName: true,
    );

    await FlutterBlePeripheral().start(
      advertiseData: advertiseData,
      advertiseSettings: AdvertiseSettings(
        advertiseMode: AdvertiseMode.advertiseModeLowLatency,
        txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
        timeout: 0,
      ),
    );
    log('bluetooth advertise: ${advertiseData.localName} | ${advertiseData.serviceUuid}');
  }

  @override
  void dispose() {
    super.dispose();

    _stopAdvertiseBluetooth();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationMainTemplate(
      appBarTitle: '',
      items: featuresList,
      itemWidget: (context, index) {
        var item = featuresList[index];

        return ListViewButton(
          onTap: () async {
            if (item['title'] == 'navigation'.tr) {
              // await FlutterBlePeripheral().stop();
              // _stopAdvertiseBluetooth();
              Get.to(() => const LocationListPage());
            } else if (item['title'] == 'object detection'.tr) {
              // Get.to(() => const ObjectDetectionPage());
              // Get.to(() => const RealtimeObjectDetectionPage());
              // Get.to(() => const RealtimePage());
              // Get.to(() => const CameraObjectDetectionPage());
              Get.to(() => const ObjectDetectServerPage());
            } else if (item['title'] == 'scan text'.tr) {
              // Get.to(() => const ScanTextPage());
              Get.to(() => const RealTimeScanTextPage());
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

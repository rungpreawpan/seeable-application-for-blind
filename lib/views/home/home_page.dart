import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:seeable/controller/app_info_controller.dart';
import 'package:seeable/views/login/model/user_model.dart';
import 'package:seeable/views/navigation/fingerprint_navigation_page.dart';
import 'package:seeable/views/object_detection/real_time_object_detect_server_page.dart';
import 'package:seeable/views/scan_text/scan_text_page.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/widgets/listview_button.dart';
import 'package:seeable/widgets/navigation_main_template.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AppInfoController _appInfoController = Get.find();
  final SettingsController _settingsController = Get.find();
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

  FlutterSecureStorage storage = const FlutterSecureStorage();

  UserModel? userInfo;

  // late stt.SpeechToText _speech;
  // String? _text;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

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
    // _speech = stt.SpeechToText();

    // _initSpeech();
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
      manufacturerData:
          Uint8List.fromList('seeable-${userInfo!.uuid!}'.codeUnits),
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

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _startWakeWordListening();
        }
      },
    );
    if (available) {
      _startWakeWordListening();
    }
  }

  void _startWakeWordListening() {
    _speech.listen(
      localeId: _settingsController
          .localeToString(_settingsController.currentLocale.value),
      onResult: (val) {
        if (val.recognizedWords.isNotEmpty) {
          print("ได้ยิน: ${val.recognizedWords}");
          _lastWords = val.recognizedWords.toLowerCase();
          if (_lastWords.contains("สิริ")) {
            print("เรียก wake word แล้ว!");
            _speech.stop();
            _startCommandListening();
          }
        }
      },
    );
  }

  void _startCommandListening() {
    _speech.listen(
      localeId: _settingsController
          .localeToString(_settingsController.currentLocale.value),
      onResult: (val) {
        if (val.finalResult) {
          print("คำสั่ง: ${val.recognizedWords}");
          _startWakeWordListening();
        }
      },
      listenFor: Duration(seconds: 5),
    );
  }

  // void _listen() async {
  //   bool available = await _speech.initialize();
  //   if (available) {
  //     _speech.listen(
  //       localeId: _settingsController
  //           .localeToString(_settingsController.currentLocale.value),
  //       onResult: (val) {
  //         if (val.hasConfidenceRating && val.confidence > 0) {
  //           _text = val.recognizedWords;
  //           setState(() {});
  //         }
  //       },
  //     );
  //   }
  // }

  @override
  void dispose() {
    super.dispose();

    _stopAdvertiseBluetooth();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap: _listen,
      child: NavigationMainTemplate(
        appBarTitle: '',
        items: featuresList,
        itemWidget: (context, index) {
          var item = featuresList[index];

          return ListViewButton(
            onTap: () async {
              if (item['title'] == 'navigation'.tr) {
                Get.to(() => const FingerprintNavigationPage());
              } else if (item['title'] == 'object detection'.tr) {
                Get.to(() => const RealTimeObjectDetectServerPage());
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
      ),
    );
  }
}

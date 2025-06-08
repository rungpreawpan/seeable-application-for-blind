import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/navigation/fingerprint/controller/fingerprint_controller.dart';
import 'package:seeable/views/navigation/fingerprint/controller/test_ble_controller.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';

class FingerprintNavigationPage extends StatefulWidget {
  const FingerprintNavigationPage({super.key});

  @override
  State<FingerprintNavigationPage> createState() =>
      _FingerprintNavigationPageState();
}

class _FingerprintNavigationPageState extends State<FingerprintNavigationPage> {
  // final TestBleController _testBleController = Get.put(TestBleController());
  final FingerprintController _fingerprintController =
      Get.put(FingerprintController());

  // Timer? _scanBle;
  // Timer? _readRssi;

  Timer? _scanning;

  Timer? _localize;

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() async {
    // await _testBleController.clearData();
    //
    // _scanBle = Timer.periodic(
    //   const Duration(seconds: 5),
    //   (Timer t) async {
    //     await _testBleController.scanDevices();
    //   },
    // );
    //
    // _readRssi = Timer.periodic(
    //   const Duration(seconds: 1),
    //   (Timer t) async {
    //     await _testBleController.readRssi();
    //   },
    // );

    _scanning = Timer.periodic(
      const Duration(seconds: 3),
      (Timer t) async {
        await _fingerprintController.scanDevices();
      },
    );
  }

  @override
  void dispose() {
    super.dispose();

    // _scanBle?.cancel();
    // _scanBle = null;
    //
    // _readRssi?.cancel();
    // _readRssi = null;
    //
    // _testBleController.clearData();

    _scanning?.cancel();
    _scanning = null;
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'navigation'.tr,
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.all(marginX2),
        child: Column(
          children: [
            _map(),
            const SizedBox(height: marginX2),
            _navigationButton(),
          ],
        ),
      ),
    );
  }

  _map() {
    return Container(
      height: 200.0,
      color: Colors.grey.shade300,
    );
  }

  _navigationButton() {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        _fingerprintController.sendRssi();
      },
      child: Container(
        height: 50.0,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(35.0),
        ),
        child: Center(
          child: TextFontStyle(
            'start'.tr,
            style: theme.textTheme.labelLarge,
          ),
        ),
      ),
    );
  }
}

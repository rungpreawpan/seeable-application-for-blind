import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/navigation/fingerprint/controller/fingerprint_controller.dart';
import 'package:seeable/widgets/main_template.dart';

class FingerprintNavigationPage extends StatefulWidget {
  const FingerprintNavigationPage({super.key});

  @override
  State<FingerprintNavigationPage> createState() =>
      _FingerprintNavigationPageState();
}

class _FingerprintNavigationPageState extends State<FingerprintNavigationPage> {
  final FingerprintController _fingerprintController =
      Get.put(FingerprintController());

  Timer? _scanBle;
  Timer? _readRssi;

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() async {
    await _fingerprintController.clearData();

    _scanBle = Timer.periodic(
      const Duration(seconds: 5),
      (Timer t) async {
        await _fingerprintController.scanDevices();
      },
    );

    _readRssi = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) async {
        await _fingerprintController.readRssi();
      },
    );
  }

  @override
  void dispose() {
    super.dispose();

    _scanBle?.cancel();
    _scanBle = null;

    _readRssi?.cancel();
    _readRssi = null;

    _fingerprintController.clearData();
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'navigation'.tr,
      showBackButton: true,
      body: Column(
        children: [],
      ),
    );
  }
}

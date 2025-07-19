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

  Timer? _readRssi;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  void _prepareData() async {
    await _fingerprintController.clearData();

    _startAutoScan();

    // RSSI อัปเดตทุก 1 วิ
    _readRssi = Timer.periodic(
      const Duration(seconds: 1),
          (Timer t) async {
        await _fingerprintController.readRssi();
      },
    );
  }

  void _startAutoScan() async {
    if (!mounted) return;

    await _fingerprintController.scanDevices();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _startAutoScan();
    });
  }

  @override
  void dispose() {
    _readRssi?.cancel();
    _readRssi = null;

    _fingerprintController.clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'navigation'.tr,
      showBackButton: true,
      body: Column(
        children: [
          Obx(
                () => Text(
              _fingerprintController.isScanning.value
                  ? "Scanning..."
                  : "Idle",
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Obx(
                () => Text(
              "Connected devices: ${_fingerprintController.connectedList.length}",
            ),
          ),
        ],
      ),
    );
  }
}
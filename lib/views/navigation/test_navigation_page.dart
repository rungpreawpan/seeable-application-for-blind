import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/navigation/controller/test_controller.dart';
import 'package:seeable/widgets/text_font_style.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TestNavigationPage extends StatefulWidget {
  final String navigated;

  const TestNavigationPage({
    super.key,
    required this.navigated,
  });

  @override
  State<TestNavigationPage> createState() => _TestNavigationPageState();
}

class _TestNavigationPageState extends State<TestNavigationPage> {
  final TestController _testController = Get.put(TestController());

  Timer? _timer;
  double? heading;

  @override
  void initState() {
    super.initState();

    _startTimer();
  }

  _startTimer() async {
    _timer ??= Timer.periodic(
      const Duration(seconds: 3),
      (Timer t) async {
        await _testController.scanDevices();
        await _compass();
        await _testController.findPosition(
            _testController.deviceList, heading ?? 0);

        setState(() {});
      },
    );
  }

  _compass() async {
    CompassEvent compassEvent = await FlutterCompass.events!.first;
    heading = compassEvent.heading;
    print(heading);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFontStyle(widget.navigated),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 330.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      TextFontStyle('(0.0,3.0)'),
                      TextFontStyle('Ruuvi 862F'),
                    ],
                  ),
                  Column(
                    children: [
                      TextFontStyle('(3.6,3.0)'),
                      TextFontStyle('Ruuvi BAAD'),
                    ],
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                Container(
                  height: 300.0,
                  width: 360.0,
                  color: primaryColor,
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  child: Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: 16.0,
                  ),
                ),
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: 16.0,
                  ),
                ),
                const Positioned(
                  bottom: 0,
                  left: 0,
                  child: Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: 16.0,
                  ),
                ),
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: Icon(
                    Icons.circle,
                    color: Colors.white,
                    size: 16.0,
                  ),
                ),
                Positioned(
                  bottom: _testController.calculateY * 100,
                  left: _testController.calculateX * 100,
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: Colors.black,
                    size: 16.0,
                  ),
                ),
              ],
            ),
            const SizedBox(
              width: 330.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      TextFontStyle('(0.0,0.0)'),
                      TextFontStyle('Ruuvi B69D'),
                    ],
                  ),
                  Column(
                    children: [
                      TextFontStyle('(3.6,0)'),
                      TextFontStyle('Ruuvi 2559'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

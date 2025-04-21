import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/navigation/controller/ble_controller.dart';
import 'package:seeable/widgets/custom_submit_button.dart';
import 'package:seeable/widgets/text_font_style.dart';
import 'package:sensors_plus/sensors_plus.dart';

class NavigationOldPage extends StatefulWidget {
  final BluetoothDevice device;

  const NavigationOldPage({
    super.key,
    required this.device,
  });

  @override
  State<NavigationOldPage> createState() => _NavigationOldPageState();
}

class _NavigationOldPageState extends State<NavigationOldPage> {
  final BleController _bleController = Get.find();

  Timer? _timer;
  bool isNavigate = false;
  bool isFavorite = false; //TODO: edit this fn

  double angle = 0;
  double userX = 0.0, userY = 0.0;
  double rotationX = 0.0, rotationY = 0.0, rotationZ = 0.0;

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();

    _tts.setLanguage("th-TH");
    _startTimer();
    _trackOrientation();
  }

  void _provideNavigationInstruction(double angle) async {
    String instruction;
    if (angle == 0.0) {
      instruction = 'straight ahead'.tr;
    } else if (angle < 0.0) {
      instruction = 'turn left'.tr;
    } else {
      instruction = 'turn right'.tr;
    }
    await _tts.speak(instruction);
  }

  _startTimer() async {
    _timer ??= Timer.periodic(
      const Duration(seconds: 3),
      (Timer t) async {
        await _bleController.scanDevices();

        await _bleController.calculateRssi(_bleController.deviceList);

        setState(() {});
      },
    );
  }

  _trackOrientation() {
    _magnetometerSubscription =
        magnetometerEvents.listen((MagnetometerEvent event) {
      angle = atan2(event.y, event.x) * (180 / pi);
      setState(() {});
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      rotationX += event.x;
      rotationY += event.y;
      rotationZ += event.z;

      userX += event.y * 0.01;
      userY += event.x * 0.01;

      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _magnetometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextFontStyle(
          widget.device.platformName,
          size: fontAppbar,
          color: primaryColor,
          weight: FontWeight.bold,
          align: TextAlign.center,
        ),
        leading: InkWell(
          onTap: () async {
            await _bleController.disconnectDevice(widget.device);
            _bleController.clearData();
            _timer?.cancel();
            _magnetometerSubscription?.cancel();
            _gyroscopeSubscription?.cancel();

            Get.back(result: true);
          },
          child: const Padding(
            padding: EdgeInsets.only(left: marginX2),
            child: CircleAvatar(
              backgroundColor: primaryColor,
              radius: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 19,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: primaryColor,
                  size: 30.0,
                ),
              ),
            ),
          ),
        ),
        actions: [
          InkWell(
            onTap: () {
              isFavorite = !isFavorite;
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.only(right: marginX2),
              child: SvgPicture.asset(
                isFavorite
                    ? 'assets/icons/favorite_filled_icon.svg'
                    : 'assets/icons/favorite_icon.svg',
                color: primaryColor,
                height: 30.0,
              ),
            ),
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.white,
        toolbarHeight: 90.0,
        elevation: 0.0,
      ),
      body: _content(),
    );
  }

  _content() {
    if (isNavigate) {
      return _navigation();
    } else {
      return _map();
    }
  }

  _map() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _infographic(),
        const SizedBox(height: marginX2),
        CustomSubmitButton(
          onTap: () {
            // _provideNavigationInstruction();
            _timer ??= Timer.periodic(
              const Duration(seconds: 3),
              (Timer t) async {
                await _bleController.scanDevices();

                await _bleController.calculateRssi(_bleController.deviceList);

                setState(() {});
              },
            );
            isNavigate = true;
            setState(() {});
          },
          title: 'start'.tr,
          buttonHeight: 70.0,
          buttonColor: Colors.grey.shade300,
          buttonMargin: const EdgeInsets.symmetric(
            horizontal: 30.0,
            vertical: 20.0,
          ),
          borderRadius: 40.0,
          fontSize: 30.0,
          fontWeight: FontWeight.normal,
          fontColor: Colors.black,
          icon: SvgPicture.asset(
            'assets/icons/navigate_arrow_icon.svg',
          ),
        ),
      ],
    );
  }

  _infographic() {
    //TODO: add map
    return Container(
      color: Colors.grey.shade700,
      height: 100,
      width: 100,
    );
  }

  _navigation() {
    // return Obx(() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // TextFontStyle('angle: $angle'),
        // const SizedBox(height: marginX2),
        SizedBox(
          width: Get.width,
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
                        TextFontStyle('(0.0,2.6)'),
                        TextFontStyle('Ruuvi BAAD'),
                      ],
                    ),
                    Column(
                      children: [
                        TextFontStyle('(2.65,2.6)'),
                        TextFontStyle('Ruuvi 2559'),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 260.0,
                width: 330.0,
                color: primaryColor,
                child: Stack(
                  children: [
                    const Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 16.0,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 65,
                          child: Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 16.0,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 16.0,
                          ),
                        ),
                        Positioned(
                          bottom: 125,
                          right: 0,
                          child: Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 16.0,
                          ),
                        ),
                      ],
                    ),
                    // TODO:
                    // phone
                    Positioned(
                      bottom: _bleController.calculateY != null
                          ? _bleController.calculateY! * 100
                          : 0,
                      left: _bleController.calculateX != null
                          ? _bleController.calculateX! * 100
                          : 0,
                      child: const Icon(
                        Icons.phone_android_rounded,
                        color: Colors.black,
                        size: 16.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 330.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        TextFontStyle('(0.0,0.0)'),
                        TextFontStyle('Ruuvi 30E9'),
                      ],
                    ),
                    Column(
                      children: [
                        TextFontStyle('(3.3,1.25)'),
                        TextFontStyle('Ruuvi 862F'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
    // });
    // return Column(
    //   mainAxisAlignment: MainAxisAlignment.center,
    //   children: [
    //     Container(
    //       width: Get.width - 40.0,
    //       height: Get.width - 40.0,
    //       decoration: BoxDecoration(
    //         color: Colors.grey.shade300,
    //         borderRadius: BorderRadius.circular(Get.width - 40 / 2),
    //       ),
    //       child: Center(
    //         child: RotationTransition(
    //           turns: AlwaysStoppedAnimation(angle / 360),
    //           child: Icon(
    //             Icons.navigation_rounded,
    //             color: Colors.grey.shade800,
    //             size: 250.0,
    //           ),
    //         ),
    //       ),
    //     ),
    //     const SizedBox(height: marginX2),
    //     CustomSubmitButton(
    //       onTap: () {},
    //       title:
    //           '${angle.toStringAsFixed(0)}° / ${_bleController.rssi} / ${_calculateRssi()}m',
    //       buttonHeight: 80.0,
    //       buttonColor: Colors.grey.shade300,
    //       buttonMargin: const EdgeInsets.symmetric(
    //         horizontal: 40.0,
    //         vertical: 20.0,
    //       ),
    //       borderRadius: 15.0,
    //       fontSize: 30.0,
    //       fontColor: Colors.black,
    //     ),
    //   ],
    // );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/navigation/controller/ble_controller.dart';
import 'package:seeable/views/navigation/controller/copy_controller.dart';
import 'package:seeable/views/navigation/navigation_page.dart';
import 'package:seeable/views/navigation/test_compass.dart';
import 'package:seeable/views/navigation/test_navigation_page.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/listview_button.dart';
import 'package:seeable/widgets/main_template.dart';
import 'dart:math';

class PlaceListPage extends StatefulWidget {
  final String appBarTitle;
  final bool isFavoritePlace;
  final List favoriteList;

  const PlaceListPage({
    super.key,
    required this.appBarTitle,
    this.isFavoritePlace = false,
    this.favoriteList = const [],
  });

  @override
  State<PlaceListPage> createState() => _PlaceListPageState();
}

class _PlaceListPageState extends State<PlaceListPage> {
  final BleController _bleController = Get.find();
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _prepareData();
    _startTimer();
  }

  _prepareData() async {
    _bleController.isLoading.value = true;
    await _bleController.scanDevices();
    _bleController.isLoading.value = false;

    setState(() {});
  }

  _startTimer() async {
    _timer ??= Timer.periodic(
      const Duration(seconds: 3),
      (Timer t) async {
        await _bleController.scanDevices();

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   body: SizedBox(
    //     width: Get.width,
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.center,
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         ElevatedButton(
    //           onPressed: () {
    //             Get.to(() => TestNavigationPage());
    //           },
    //           child: Text('navigation'),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
      return Stack(
        children: [
          MainTemplate(
            appBarTitle: widget.appBarTitle,
            onBack: () {
              _timer?.cancel();
            },
            actions: [
              InkWell(
                onTap: () async {
                  await _bleController.scanDevices();

                  setState(() {});
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: marginX2),
                  child: Icon(
                    Icons.refresh_rounded,
                    color: primaryColor,
                    size: 30.0,
                  ),
                ),
              ),
            ],
            items: widget.isFavoritePlace
                ? widget.favoriteList
                : _bleController.deviceList
              ..sort((a, b) => _calculateRssi(a).compareTo(_calculateRssi(b))),
            itemWidget: (context, index) {
              if (widget.isFavoritePlace) {
                // var item = widget.favoriteList[index];

                return Container(
                  height: 100,
                  color: Colors.grey,
                );
              } else {
                ScanResult item = _bleController.deviceList[index];

                return ListViewButton(
                  onTap: () {
                    _timer?.cancel();
                    _timer = null;

                    // Get.to(
                    //   () => NavigationPage(device: item.device),
                    // );
                    Get.to(() => TestNavigationPage(navigated: item.device.platformName));
                    // Get.to(() => TestCompass());
                  },
                  iconPath: '',
                  title: item.device.platformName,
                  showDistance: true,
                  distance: _calculateRssi(item),
                );
              }
            },
          ),
          _loading(),
        ],
      );
  }

  _calculateRssi(ScanResult bleDevice) {
    // Distance = 10 ^ ((Measured Power -RSSI)/(10 * N))
    double distance = pow(10, (-60 - bleDevice.rssi) / (10 * 3)).toDouble();

    return distance.toStringAsFixed(2);
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _bleController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

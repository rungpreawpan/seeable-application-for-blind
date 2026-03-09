import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/ar_marker/ar_scanner_page.dart';

class ArMain extends StatefulWidget {
  const ArMain({super.key});

  @override
  State<ArMain> createState() => _ArMainState();
}

class _ArMainState extends State<ArMain> {
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();

    _prepareData();
  }

  _prepareData() async {
    cameras = await availableCameras();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
            onPressed: () {
              Get.to(
                () => ArucoScannerPage(cameras: cameras),
              );
            },
            child: Text('AR MARKER')),
      ),
    );
  }
}

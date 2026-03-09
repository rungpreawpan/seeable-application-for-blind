import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/tts_manager.dart';
import 'package:seeable/utils/camera_service.dart';
import 'package:seeable/views/navigation/controller/navigation_controller.dart';
import 'package:seeable/widgets/custom_camera_button.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_switch_camera_button.dart';
import 'package:seeable/widgets/main_template.dart';

class ScanMarkerPage extends StatefulWidget {
  const ScanMarkerPage({super.key});

  @override
  State<ScanMarkerPage> createState() => _ScanMarkerPageState();
}

class _ScanMarkerPageState extends State<ScanMarkerPage> {
  final NavigationController _navigationController = Get.find();

  final ttsManager = TtsManager();

  late CameraService _cameraService;

  @override
  void initState() {
    super.initState();

    _cameraService = CameraService();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _cameraService.initializeCamera();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();

    ttsManager.stop();
    _cameraService.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'marker scan'.tr,
      showBackButton: true,
      body: SafeArea(
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              Stack(
                children: [
                  _cameraService.controller != null &&
                          _cameraService.controller!.value.isInitialized
                      ? _cameraService.isFrontCamera
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: CameraPreview(_cameraService.controller!),
                            )
                          : CameraPreview(_cameraService.controller!)
                      : const SizedBox(),
                  _loading(),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: marginX2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        height: 50.0,
                        width: 50.0,
                      ),
                      _cameraButton(),
                      _switchCamera(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _cameraButton() {
    return CustomCameraButton(
      semanticsLabel: 'marker scan'.tr,
      onTap: () async {
        await ttsManager.speak('marker scan'.tr);

        HapticFeedback.selectionClick();

        CameraImage? cameraImage = await _cameraService.captureFrame();
        _navigationController.detectARUcoMarker(
            isAllMarker: false, cameraImage: cameraImage);
      },
    );
  }

  _switchCamera() {
    return CustomSwitchCameraButton(
      isFrontCamera: _cameraService.selectedCameraIndex == 1,
      onTap: () async {
        await _cameraService.switchCamera();
        if (mounted) setState(() {});
      },
    );
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _navigationController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

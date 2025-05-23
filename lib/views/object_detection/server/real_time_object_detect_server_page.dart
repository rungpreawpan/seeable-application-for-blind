import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/object_detection/server/controller/object_detection_controller.dart';
import 'package:seeable/widgets/custom_camera_button.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_switch_camera_button.dart';
import 'package:seeable/widgets/main_template.dart';

class RealTimeObjectDetectServerPage extends StatefulWidget {
  const RealTimeObjectDetectServerPage({super.key});

  @override
  State<RealTimeObjectDetectServerPage> createState() =>
      _RealTimeObjectDetectServerPageState();
}

class _RealTimeObjectDetectServerPageState
    extends State<RealTimeObjectDetectServerPage> {
  final ObjectDetectionController _objectDetectionController =
      Get.put(ObjectDetectionController());

  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;

  File? _imageFile;

  @override
  void initState() {
    super.initState();

    _initializeCamera();
    // _loadLatestImage();
  }

  Future<void> _initializeCamera([int cameraIndex = 0]) async {
    try {
      _cameras = await availableCameras();

      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![cameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();

        if (!mounted) return;

        setState(() {});
      } else {
        log('No cameras available');
      }
    } catch (e) {
      log('Error initializing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'object detection'.tr,
      showBackButton: true,
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  _cameraController != null
                      ? CameraPreview(_cameraController!)
                      : const SizedBox(),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: marginX2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // _selectImageButton(),
                          CustomCameraButton(
                            onTap: () {
                              //TODO
                            },
                          ),
                          CustomSwitchCameraButton(
                            onTap: () {
                              if (_cameras == null || _cameras!.length < 2) {
                                return;
                              }

                              if (_selectedCameraIndex == 0) {
                                _selectedCameraIndex =
                                    (_selectedCameraIndex + 1) %
                                        _cameras!.length;
                              } else {
                                _selectedCameraIndex = 0;
                              }
                              _initializeCamera(_selectedCameraIndex);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _loading(),
        ],
      ),
    );
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _objectDetectionController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

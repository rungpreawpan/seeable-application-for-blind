import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/scan_text/controller/ocr_controller.dart';
import 'package:seeable/views/scan_text/scan_text_result_page.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/main_template.dart';

class RealTimeScanTextPage extends StatefulWidget {
  const RealTimeScanTextPage({super.key});

  @override
  State<RealTimeScanTextPage> createState() => _RealTimeScanTextPageState();
}

class _RealTimeScanTextPageState extends State<RealTimeScanTextPage> {
  final OcrController _ocrController = Get.put(OcrController());

  List<CameraDescription>? _cameras;
  CameraController? _cameraController;

  File? _imageFile;

  @override
  void initState() {
    super.initState();

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
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
      appBarTitle: 'scan text'.tr,
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
                    child: _cameraButton(),
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

  _cameraButton() {
    return InkWell(
      onTap: () {
        _scanText();
      },
      child: Container(
        height: 70.0,
        width: 70.0,
        margin: const EdgeInsets.all(30.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35.0),
        ),
        child: Center(
          child: Container(
            height: 66.0,
            width: 66.0,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(33.0),
            ),
            child: Center(
              child: Container(
                height: 65.0,
                width: 65.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(33.0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _scanText() async {
    final XFile picture = await _cameraController!.takePicture();
    _imageFile = File(picture.path);

    await _ocrController.uploadImage(_imageFile!);
    Get.to(() => const ScanTextResultPage());
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: _ocrController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

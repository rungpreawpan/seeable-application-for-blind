import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/utils/camera_service.dart';
import 'package:seeable/utils/gallery_service.dart';
import 'package:seeable/views/scan_text/controller/ocr_controller.dart';
import 'package:seeable/views/scan_text/scan_text_result_page.dart';
import 'package:seeable/widgets/custom_camera_button.dart';
import 'package:seeable/widgets/custom_gallery_button.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_switch_camera_button.dart';
import 'package:seeable/widgets/main_template.dart';

class ScanTextPage extends StatefulWidget {
  const ScanTextPage({super.key});

  @override
  State<ScanTextPage> createState() => _ScanTextPageState();
}

class _ScanTextPageState extends State<ScanTextPage> {
  final OcrController _ocrController = Get.put(OcrController());

  late CameraService _cameraService;
  final GalleryService _galleryService = GalleryService();

  File? _imageFile;
  Uint8List? _thumbnailImage;

  @override
  void initState() {
    super.initState();

    _cameraService = CameraService();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _cameraService.initializeCamera();
    _thumbnailImage = await _galleryService.loadLatestImage();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
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
                  Stack(
                    children: [
                      _cameraService.controller != null &&
                              _cameraService.controller!.value.isInitialized
                          ? _cameraService.isFrontCamera
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..rotateY(math.pi),
                                  child:
                                      CameraPreview(_cameraService.controller!),
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
                          _galleryThumbnail(),
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
          _loading(),
        ],
      ),
    );
  }

  _cameraButton() {
    return CustomCameraButton(
      semanticsLabel: 'scan text'.tr,
      onTap: () async {
        HapticFeedback.selectionClick();

        XFile? file = await _cameraService.takePicture();

        if (file != null) {
          _imageFile = File(file.path);
          await _ocrController.uploadText(_imageFile!);

          if (_ocrController.ocrText != null) {
            Get.to(() => ScanTextResultPage(imageFile: _imageFile!));
          }
        }
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

  _galleryThumbnail() {
    return CustomGalleryButton(
      onTap: () async {
        XFile? file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );

        if (file != null) {
          await _ocrController.uploadText(File(file.path));
          Get.to(() => ScanTextResultPage(imageFile: File(file.path)));
        }
      },
      thumbnailImage: _thumbnailImage,
    );
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

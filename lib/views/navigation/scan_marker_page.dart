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
import 'package:seeable/views/navigation/controller/navigation_controller.dart';
import 'package:seeable/widgets/custom_camera_button.dart';
import 'package:seeable/widgets/custom_gallery_button.dart';
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

  late CameraService _cameraService;
  final GalleryService _galleryService = GalleryService();

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
    );
  }

  _cameraButton() {
    return CustomCameraButton(
      semanticsLabel: 'scan marker'.tr,
      onTap: () async {
        HapticFeedback.selectionClick();

        XFile? file = await _cameraService.takePicture();

        if (file != null) {
          File imageFile = File(file.path);
          await _navigationController.uploadMarker(imageFile);
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
          File imageFile = File(file.path);
          await _navigationController.uploadMarker(imageFile);
        }
      },
      thumbnailImage: _thumbnailImage,
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

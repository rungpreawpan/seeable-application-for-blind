import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/tts_manager.dart';
import 'package:seeable/utils/camera_service.dart';
import 'package:seeable/utils/gallery_service.dart';
import 'package:seeable/views/object_detection/controller/object_detection_controller.dart';
import 'package:seeable/views/object_detection/model/object_detection_model.dart';
import 'package:seeable/views/object_detection/object_detection_result_page.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/views/settings/model/settings_model.dart';
import 'package:seeable/widgets/custom_camera_button.dart';
import 'package:seeable/widgets/custom_gallery_button.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/custom_switch_camera_button.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:image/image.dart' as img;
import 'package:seeable/widgets/text_font_style.dart';
import 'package:translator/translator.dart';

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
  final SettingsController _settingsController = Get.find();

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  final ttsManager = TtsManager();
  final translator = GoogleTranslator();

  SettingsModel? settingsInfo;

  late CameraService _cameraService;
  final GalleryService _galleryService = GalleryService();

  Timer? _autoCaptureTimer;
  bool _isCapturing = false;

  Uint8List? _thumbnailImage;

  String? translatedText;

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

  Future _speak() async {
    if (_objectDetectionController.objectDetected?.boxes != null) {
      List<String> objects = [];
      translatedText = null;

      for (BoxesModel object
          in _objectDetectionController.objectDetected!.boxes!) {
        if (object.label != null) {
          objects.add(object.label!);
        }
      }

      if (objects.isNotEmpty) {
        List translations = await Future.wait(
          objects.map((obj) async {
            Translation? translation;

            if (_settingsController.currentLocale.value.languageCode == 'th') {
              translation = await translator.translate(obj, to: 'th');
            } else {
              translation = await translator.translate(obj, to: 'en');
            }

            return translation.text;
          }),
        );

        translatedText = translations.toSet().toList().join(', ');
        await ttsManager.speak('${'detected'.tr} $translatedText');
        HapticFeedback.heavyImpact();
      } else {
        await ttsManager.speak('unable to detect objects'.tr);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    ttsManager.stop();

    _cameraService.dispose();
    _autoCaptureTimer?.cancel();
    _autoCaptureTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'object detection'.tr,
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
              translatedText != null
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: _resultBox(
                        result: translatedText,
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  void _startAutoCapture() async {
    await ttsManager.speak('start object detection'.tr);
    _isCapturing = true;

    _autoCaptureTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        XFile? file = await _cameraService.takePicture();

        if (file != null) {
          await _objectDetectionController.uploadObject(File(file.path));
          await _speak();

          setState(() {});
        }
      },
    );
  }

  void _stopAutoCapture() async {
    _autoCaptureTimer?.cancel();
    ttsManager.stop();
    _autoCaptureTimer = null;
    _isCapturing = false;
    translatedText = null;

    setState(() {});

    await ttsManager.speak('stop object detection'.tr);
  }

  _cameraButton() {
    return CustomCameraButton(
      onTap: () async {
        if (_isCapturing) {
          _isCapturing = false;
          _stopAutoCapture();
        } else {
          _isCapturing = true;
          _startAutoCapture();
        }

        HapticFeedback.selectionClick();
        setState(() {});
      },
      icon: _isCapturing
          ? const Icon(
              Icons.stop_rounded,
              size: 28.0,
              color: Colors.black,
            )
          : null,
    );
  }

  _switchCamera() {
    return CustomSwitchCameraButton(
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
          await _objectDetectionController.uploadObject(File(file.path));

          Get.to(
            () => ObjectDetectionResultPage(
              imageFile: File(file.path),
            ),
          );
        }
      },
      thumbnailImage: _thumbnailImage,
    );
  }

  _resultBox({
    required String? result,
  }) {
    return Visibility(
      visible: result != null,
      child: Container(
        width: Get.width,
        margin: const EdgeInsets.all(marginX2),
        padding: const EdgeInsets.symmetric(
          horizontal: marginX2,
          vertical: margin,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: TextFontStyle(
          result!,
          size: fontSizeXL,
          align: TextAlign.center,
        ),
      ),
    );
  }

  Future<Size?> getImageSize(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    return Size(image.width.toDouble(), image.height.toDouble());
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

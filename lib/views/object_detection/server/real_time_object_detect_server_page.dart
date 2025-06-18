import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/object_detection/server/controller/object_detection_controller.dart';
import 'package:seeable/views/object_detection/server/model/object_detection_model.dart';
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

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  final FlutterTts flutterTts = FlutterTts();
  final translator = GoogleTranslator();

  SettingsModel? settingsInfo;

  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;

  File? _imageFile;
  Size? _imageSize;

  Uint8List? _thumbnailImage;

  @override
  void initState() {
    super.initState();

    _initializeCamera();
    _loadLatestImage();
    _ttsSettings();
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

  Future<void> _loadLatestImage() async {
    final permission = await PhotoManager.requestPermissionExtend();

    if (permission.isAuth || permission == PermissionState.limited) {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        final recentAlbum = albums.first;
        final recentAssets =
            await recentAlbum.getAssetListPaged(page: 0, size: 1);

        if (recentAssets.isNotEmpty) {
          final asset = recentAssets.first;
          final thumb =
              await asset.thumbnailDataWithSize(const ThumbnailSize(200, 200));
          _thumbnailImage = thumb;
          setState(() {});
        }
      }

      if (permission == PermissionState.limited) {
        await PhotoManager.presentLimited();
      }
    }
  }

  _ttsSettings() async {
    String? settingsData = await storage.read(key: 'settings_value');
    if (settingsData != null) {
      Map<String, dynamic> settingsValueMap = json.decode(settingsData);
      settingsInfo = SettingsModel.fromJSON(settingsValueMap);

      if (settingsInfo?.useSpeechRecognition == false) {
        return;
      } else {
        if (settingsInfo?.speed == 'slow') {
          await flutterTts.setSpeechRate(0.0);
        } else if (settingsInfo?.speed == 'fast') {
          await flutterTts.setSpeechRate(1.0);
        } else {
          await flutterTts.setSpeechRate(0.5);
        }
      }
    }
  }

  Future _speak() async {
    if (_objectDetectionController.objectDetected?.boxes != null) {
      List<String> objects = [];
      for (BoxesModel object
          in _objectDetectionController.objectDetected!.boxes!) {
        objects.add(object.label!);
      }

      if (objects.isNotEmpty) {
        List<String> translateObjects = [];
        for (String obj in objects) {
          var translation =
              await translator.translate(obj, from: 'en', to: 'th'); //todo ต้องแปลจากth to enด้วยต้องเช็คจากsettings
          translateObjects.add(translation.text);
        }

        await flutterTts.speak('ตรวจพบวัตถุดังนี้ $translateObjects');
      } else {
        await flutterTts.speak('ไม่สามารถตรวจจับวัตถุได้');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    flutterTts.stop();
    _cameraController?.dispose();
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
                          CustomGalleryButton(
                            onTap: () async {
                              XFile? file = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                              );

                              if (file != null) {
                                _imageSize =
                                    await getImageSize(File(file.path));
                                await _objectDetectionController
                                    .uploadObject(File(file.path));
                                await _speak();
                              }
                              //TODO: กดถ่าย = ถ่ายอัตโนมัติทุก 3-5 วิแล้วแสดงผลที่หน้าจอเป็น snack bar
                            },
                            thumbnailImage: _thumbnailImage,
                          ),
                          CustomCameraButton(
                            onTap: () async {
                              //TODO: to result page
                              XFile? file =
                                  await _cameraController!.takePicture();

                              _imageSize = await getImageSize(File(file.path));
                              await _objectDetectionController
                                  .uploadObject(File(file.path));
                              await _speak();
                              // _imageFile = File(picture.path);
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
          Align(
            alignment: Alignment.topCenter,
            child: _resultBox(
              result: 'test', //TODO add real result
            ),
          ),
          _loading(),
        ],
      ),
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

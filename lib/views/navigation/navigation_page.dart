import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/tts_manager.dart';
import 'package:seeable/views/navigation/controller/navigation_controller.dart';
import 'package:seeable/views/navigation/model/obstacle_model.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/select_camera_gallery_bottomsheet.dart';
import 'package:seeable/widgets/text_font_style.dart';
import 'package:translator/translator.dart';

class FingerprintNavigationPage extends StatefulWidget {
  const FingerprintNavigationPage({super.key});

  @override
  State<FingerprintNavigationPage> createState() =>
      _FingerprintNavigationPageState();
}

class _FingerprintNavigationPageState extends State<FingerprintNavigationPage> {
  final SettingsController _settingsController = Get.find();
  final NavigationController _fingerprintController =
      Get.put(NavigationController());

  Timer? _scanning;
  Timer? _obstacleScanning;

  List<CameraDescription>? _cameras;
  CameraController? _cameraController;

  final ttsManager = TtsManager();
  final translator = GoogleTranslator();

  String? translatedText;

  @override
  void initState() {
    super.initState();

    _initializeCamera();
    _prepareData();
  }

  _prepareData() async {
    _scanning = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        await _fingerprintController.scanDevices();
      },
    );
    _obstacleScanning = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        _obstacle();
      },
    );
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

  _obstacle() async {
    XFile? file = await _cameraController!.takePicture();
    _fingerprintController.obstacleList.clear();

    await _fingerprintController.uploadObstacle(File(file.path));

    if (_fingerprintController.obstacleList.isNotEmpty) {
      for (ObstacleModel obstacle in _fingerprintController.obstacleList) {
        if (obstacle.priority! >= 0.3) {
          if (_settingsController.currentLocale.value.languageCode == 'th') {
            var translate =
                await translator.translate(obstacle.message!, to: 'th');
            await ttsManager.speak(translate.toString());
          } else {
            var translate =
                await translator.translate(obstacle.message!, to: 'en');
            await ttsManager.speak(translate.toString());
          }
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    _scanning?.cancel();
    _scanning = null;

    _obstacleScanning?.cancel();
    _obstacleScanning = null;

    _cameraController?.dispose();

    ttsManager.stop();
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'navigation'.tr,
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.all(marginX2),
        child: Column(
          children: [
            _map(),
            const SizedBox(height: marginX2),
            _navigationButton(),
          ],
        ),
      ),
    );
  }

  _map() {
    return InkWell(
      onTap: () async {
        XFile? result =
            await Get.bottomSheet(const SelectCameraGalleryBottomSheet());

        if (result != null) {
          await _fingerprintController.uploadObstacle(File(result.path));
        }
      },
      child: Container(
        height: 200.0,
        color: Colors.grey.shade300,
      ),
    );
  }

  _navigationButton() {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        await _fingerprintController.sendRssi();
        // _fingerprintController.uploadObstacle();
      },
      child: Container(
        height: 50.0,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(35.0),
        ),
        child: Center(
          child: TextFontStyle(
            'start'.tr,
            style: theme.textTheme.labelLarge,
          ),
        ),
      ),
    );
  }
}

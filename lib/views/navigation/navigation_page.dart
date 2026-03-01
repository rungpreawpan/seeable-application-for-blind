import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/controller/tts_manager.dart';
import 'package:seeable/utils/camera_service.dart';
import 'package:seeable/views/navigation/components/navigation_direction_popup.dart';
import 'package:seeable/views/navigation/components/obstacle_alert_popup.dart';
import 'package:seeable/views/navigation/controller/navigation_controller.dart';
import 'package:seeable/views/navigation/model/obstacle_model.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:translator/translator.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final SettingsController _settingsController = Get.find();
  final NavigationController _navigationController =
      Get.put(NavigationController());

  late CameraService _cameraService;

  Timer? _scanning;
  Timer? _obstacleScanning;

  final ttsManager = TtsManager();
  final translator = GoogleTranslator();

  String? translatedText;

  @override
  void initState() {
    super.initState();

    _cameraService = CameraService();

    // _initCamera();
    // _prepareData();
  }

  Future<void> _initCamera() async {
    await _cameraService.initializeCamera();

    if (mounted) setState(() {});
  }

  //TODO
  _prepareData() async {
    _scanning = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        _updatePosition();
      },
    );
    _obstacleScanning = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        _obstacle();
      },
    );
  }

  Future<XFile?> _takePicture() async {
    XFile? file = await _cameraService.takePicture();

    return file;
  }

  _obstacle() async {
    XFile? file = await _takePicture();

    if (file != null) {
      _navigationController.obstacleDetected = null;
      await _navigationController.uploadObstacle(File(file.path));

      if (_navigationController.obstacleDetected != null) {
        if (_navigationController.obstacleDetected!.boxes!.isNotEmpty) {
          for (ObstacleBoxesModel obstacle
              in _navigationController.obstacleDetected!.boxes!) {
            if (obstacle.priority! >= 0.3) {
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
  }

  _updatePosition() async {
    XFile? file = await _takePicture();

    if (file != null) {
      File markerImage = File(file.path);

      await _navigationController.updatePosition(markerImage: markerImage);
      //TODO add tts
    }
  }

  @override
  void dispose() {
    super.dispose();
    _cameraService.dispose();

    _scanning?.cancel();
    _scanning = null;

    _obstacleScanning?.cancel();
    _obstacleScanning = null;

    ttsManager.stop();
  }

  @override
  Widget build(BuildContext context) {
    // return MainTemplate(
    //   appBarTitle: 'navigation'.tr,
    //   showBackButton: true,
    //   body: Container(
    //     color: Colors.black,
    //     child: Stack(
    //       children: [
    //         SingleChildScrollView(
    //           scrollDirection: Axis.horizontal,
    //           child: Row(
    //             mainAxisAlignment: MainAxisAlignment.end,
    //             children: [
    //               Image.asset(
    //                 // 'assets/test/arrived.jpg',
    //                 'assets/test/obstacle.jpg',
    //                 fit: BoxFit.fitHeight,
    //                 height: Get.height,
    //               ),
    //             ],
    //           ),
    //         ),
    //         Column(
    //           children: [
    //             NavigationDirectionPopup(),
    //             ObstacleAlertPopup(),
    //           ],
    //         ),
    //       ],
    //     ),
    //   ),
    // );
    return MainTemplate(
      appBarTitle: 'navigation'.tr,
      showBackButton: true,
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            _cameraService.controller != null &&
                    _cameraService.controller!.value.isInitialized
                ? CameraPreview(_cameraService.controller!)
                : const SizedBox(),
            _loading(),
          ],
        ),
      ),
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

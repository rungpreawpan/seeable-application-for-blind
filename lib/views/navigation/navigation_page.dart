import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
      Get.find();

  late CameraService _cameraService;

  Timer? _scanning;
  Timer? _obstacleScanning;

  final ttsManager = TtsManager();
  final translator = GoogleTranslator();

  final RxnString translatedText = RxnString();

  bool _isSpeaking = false;
  String? _lastMessage;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
    _initCamera();
    _prepareData();
  }

  Future<void> _initCamera() async {
    await _cameraService.initializeCamera();
    if (mounted) setState(() {});
  }

  Future<void> _speakSafe(String message) async {
    if (message.isEmpty) return;
    if (_isSpeaking) return;
    if (_lastMessage == message) return;

    _isSpeaking = true;
    _lastMessage = message;

    await ttsManager.speak(message);

    _isSpeaking = false;
  }

  _prepareData() async {
    _navigationController.clearUpdatePosition();

    if (_navigationController.selectedStartMarker.isNotEmpty &&
        _navigationController.selectedDestinationMarker.isNotEmpty) {
      String startMarker =
          _navigationController.selectedStartMarker.first.markerName ?? '-';

      String destinationMarker =
          _navigationController.selectedDestinationMarker.first.markerName ??
              '-';

      String navigationMessage =
          '${'start navigation'.tr} ${'from'.tr} ${startMarker.substring(0, 4)} '
          '${'to'.tr} ${destinationMarker.substring(0, 4)} '
          '${'total distance'.tr} ${_navigationController.navigationData?.totalDistance} '
          '${'meter'.tr} ${'destination will be on'.tr} '
          '${_navigationController.navigationData?.destinationSide?.tr}';

      await _speakSafe(navigationMessage);
    }

    await Future.delayed(const Duration(seconds: 1));

    _scanning = Timer.periodic(
      const Duration(seconds: 2),
          (_) => _updatePosition(),
    );

    _obstacleScanning = Timer.periodic(
      const Duration(seconds: 4),
          (_) => _obstacle(),
    );
  }

  _obstacle() async {
    XFile? file = await  _cameraService.takePicture();

    if (file != null) {
      await _navigationController.uploadObstacle(File(file.path));

      if (_navigationController.obstacleDetected?.boxes != null) {
        List<String> obstacles = [];

        for (ObstacleBoxesModel obstacle
        in _navigationController.obstacleDetected!.boxes!) {
          if (obstacle.label != null) {
            obstacles.add(obstacle.label!);
          }
        }

        if (obstacles.isNotEmpty) {
          List translations = await Future.wait(
            obstacles.map((obs) async {
              Translation translation;

              if (_settingsController.currentLocale.value.languageCode ==
                  'th') {
                translation = await translator.translate(obs, to: 'th');
              } else {
                translation = await translator.translate(obs, to: 'en');
              }

              return translation.text;
            }),
          );

          translatedText.value = translations.toSet().toList().join(', ');

          if (translatedText.value == 'ถ่วง' || translatedText.value == 'clutter') {
            translatedText.value = 'สิ่งของที่วางเกลื่อนกลาด';
          }

          await _speakSafe('${'detected'.tr} ${translatedText.value}');
          HapticFeedback.heavyImpact();
        } else {
          translatedText.value = null;
        }
      }
    }
  }

  _updatePosition() async {
    _navigationController.detectedMarker = null;

    if (_navigationController.stopUpdatePosition == true) {
      _scanning?.cancel();
      _obstacleScanning?.cancel();
      return;
    }

    _navigationController.updatePositionMessage.value = null;
    _navigationController.updatePositionStatus.value = null;

    CameraImage? cameraImage = await _cameraService.captureFrame();
    await _navigationController.detectARUcoMarker(cameraImage: cameraImage);

    // await _navigationController.updatePosition(
    //     detectedMarker: _navigationController.detectedMarker?.markerName
    //         ?.replaceAll('-', ''));

    await _speakSafe(_navigationController.updatePositionMessage.value ?? '');

    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _scanning?.cancel();
    _obstacleScanning?.cancel();
    ttsManager.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            _warning(),
            _loading(),
          ],
        ),
      ),
    );
  }

  Widget _warning() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          final status =
              _navigationController.updatePositionStatus.value ?? 'ON_PATH';

          final message =
              _navigationController.updatePositionMessage.value;

          if (message == null) return const SizedBox();

          return NavigationDirectionPopup(
            status: status,
            alertText: message,
          );
        }),
        _obstacleWarning(),
      ],
    );
  }

  Widget _obstacleWarning() {
    return Obx(() {
      if (translatedText.value == null) return const SizedBox();

      return ObstacleAlertPopup(
        obstacle: '${'detected'.tr} ${translatedText.value}',
      );
    });
  }

  Widget _loading() {
    return Obx(() {
      return Visibility(
        visible: _navigationController.isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}
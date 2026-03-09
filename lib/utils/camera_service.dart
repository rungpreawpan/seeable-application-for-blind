import 'dart:async';
import 'dart:developer';
import 'package:camera/camera.dart';

class CameraService {
  List<CameraDescription>? _cameras;
  CameraController? controller;
  int _selectedCameraIndex = 0;

  List<CameraDescription>? get cameras => _cameras;
  int get selectedCameraIndex => _selectedCameraIndex;

  bool get isFrontCamera =>
      _cameras != null &&
          _cameras!.isNotEmpty &&
          _cameras![_selectedCameraIndex].lensDirection ==
              CameraLensDirection.front;

  bool get isBackCamera =>
      _cameras != null &&
          _cameras!.isNotEmpty &&
          _cameras![_selectedCameraIndex].lensDirection ==
              CameraLensDirection.back;

  Future<void> initializeCamera({int cameraIndex = 0}) async {
    try {
      _cameras = await availableCameras();

      if (_cameras != null && _cameras!.isNotEmpty) {
        _selectedCameraIndex = cameraIndex;

        controller = CameraController(
          _cameras![cameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await controller!.initialize();
      } else {
        log('No cameras available');
      }
    } catch (e) {
      log('Error initializing camera: $e');
      rethrow;
    }
  }

  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _cameras!.length;

    await controller?.dispose();
    await initializeCamera(cameraIndex: _selectedCameraIndex);
  }

  Future<XFile?> takePicture() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        controller!.value.isTakingPicture) {
      return null;
    }

    try {
      return await controller!.takePicture();
    } catch (e) {
      return null;
    }
  }

  Future<CameraImage?> captureFrame() async {
    if (controller == null || !controller!.value.isInitialized) return null;

    final completer = Completer<CameraImage>();

    await controller!.startImageStream((CameraImage image) async {
      if (!completer.isCompleted) {
        completer.complete(image);
        await controller!.stopImageStream();
      }
    });

    return completer.future;
  }

  void dispose() {
    controller?.dispose();
  }
}
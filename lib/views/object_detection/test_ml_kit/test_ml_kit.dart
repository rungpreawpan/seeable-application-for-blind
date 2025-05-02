import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'dart:ui' as ui;

import 'package:seeable/widgets/text_font_style.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

// class CameraObjectDetectionPage extends StatefulWidget {
//   const CameraObjectDetectionPage({super.key});
//
//   @override
//   State<CameraObjectDetectionPage> createState() =>
//       _CameraObjectDetectionPageState();
// }
//
// class _CameraObjectDetectionPageState extends State<CameraObjectDetectionPage> {
//   late List<CameraDescription> _cameras;
//   late CameraController _cameraController;
//   late ObjectDetector _objectDetector;
//   bool _isDetecting = false;
//   bool _isCameraInitialized = false;
//   int _cameraIndex = 0;
//   List<DetectedObject> _detectedObjects = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }
//
//   Future<void> _initialize() async {
//     _cameras = await availableCameras();
//     await _startCamera();
//
//     // _objectDetector = ObjectDetector(
//     //   options: LocalObjectDetectorOptions(
//     //     modelPath: 'assets/mobile_net/mobile_net.tflite',
//     //     mode: DetectionMode.stream,
//     //     classifyObjects: true,
//     //     multipleObjects: true,
//     //   ),
//     // );
//
//     _objectDetector = ObjectDetector(
//       options: ObjectDetectorOptions(
//         classifyObjects: false, // แนะนำปิด classify เพื่อจับกรอบได้ดีขึ้น
//         multipleObjects: true,
//         mode: DetectionMode.stream,
//       ),
//     );
//   }
//
//   Future<void> _startCamera() async {
//     _cameraController = CameraController(
//       _cameras[_cameraIndex],
//       ResolutionPreset.medium,
//       enableAudio: false,
//       imageFormatGroup: ImageFormatGroup.yuv420, // ชัดเจน format
//     );
//
//     await _cameraController.initialize();
//     _cameraController.startImageStream(_processCameraImage);
//
//     setState(() {
//       _isCameraInitialized = true;
//     });
//   }
//
//   Future<void> _switchCamera() async {
//     if (_cameras.length < 2) return;
//
//     _cameraIndex = (_cameraIndex + 1) % _cameras.length;
//
//     await _cameraController.stopImageStream();
//     await _cameraController.dispose();
//
//     setState(() {
//       _isCameraInitialized = false;
//     });
//
//     await _startCamera();
//   }
//
//   Future<void> _processCameraImage(CameraImage image) async {
//     if (_isDetecting) return;
//     _isDetecting = true;
//
//     try {
//       final WriteBuffer allBytes = WriteBuffer();
//       for (Plane plane in image.planes) {
//         allBytes.putUint8List(plane.bytes);
//       }
//       final bytes = allBytes.done().buffer.asUint8List();
//
//       final inputImage = InputImage.fromBytes(
//         bytes: bytes,
//         metadata: InputImageMetadata(
//           size: Size(image.width.toDouble(), image.height.toDouble()),
//           rotation: _rotationIntToImageRotation(
//             _cameraController.description.sensorOrientation,
//           ),
//           format: InputImageFormat.nv21, // <<< ต้องใช้ NV21 นะครับ
//           bytesPerRow: image.planes[0].bytesPerRow,
//         ),
//       );
//
//       final objects = await _objectDetector.processImage(inputImage);
//
//       print('objects detected: ${objects.length}');
//
//       setState(() {
//         _detectedObjects = objects;
//       });
//     } catch (e) {
//       print('Error: $e');
//     } finally {
//       _isDetecting = false;
//     }
//   }
//
//   InputImageRotation _rotationIntToImageRotation(int rotation) {
//     switch (rotation) {
//       case 0:
//         return InputImageRotation.rotation0deg;
//       case 90:
//         return InputImageRotation.rotation90deg;
//       case 180:
//         return InputImageRotation.rotation180deg;
//       case 270:
//         return InputImageRotation.rotation270deg;
//       default:
//         return InputImageRotation.rotation0deg;
//     }
//   }
//
//   @override
//   void dispose() {
//     _cameraController.dispose();
//     _objectDetector.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Live Object Detection'),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.cameraswitch),
//             onPressed: _switchCamera,
//           ),
//         ],
//       ),
//       body: !_isCameraInitialized
//           ? const Center(child: CircularProgressIndicator())
//           : Stack(
//               fit: StackFit.expand,
//               children: [
//                 CameraPreview(_cameraController),
//                 CustomPaint(
//                   painter: LiveObjectPainter(_detectedObjects),
//                 ),
//               ],
//             ),
//     );
//   }
// }
//
// class LiveObjectPainter extends CustomPainter {
//   final List<DetectedObject> objects;
//
//   LiveObjectPainter(this.objects);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint paint = Paint()
//       ..color = Colors.green
//       ..strokeWidth = 3
//       ..style = PaintingStyle.stroke;
//
//     final textStyle = const TextStyle(
//       color: Colors.red,
//       fontSize: 14,
//       backgroundColor: Colors.white,
//     );
//
//     final textPainter = TextPainter(
//       textAlign: TextAlign.left,
//       textDirection: TextDirection.ltr,
//     );
//
//     for (final object in objects) {
//       final rect = object.boundingBox;
//
//       canvas.drawRect(rect, paint);
//
//       if (object.labels.isNotEmpty) {
//         final label = object.labels.first;
//         final displayText =
//             '${label.text} ${(label.confidence * 100).toStringAsFixed(2)}%';
//
//         textPainter.text = TextSpan(text: displayText, style: textStyle);
//         textPainter.layout();
//         textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant LiveObjectPainter oldDelegate) {
//     return oldDelegate.objects != objects;
//   }
// }

class TestMlKit extends StatefulWidget {
  const TestMlKit({super.key});

  @override
  State<TestMlKit> createState() => _TestMlKitState();
}

class _TestMlKitState extends State<TestMlKit> {
  late final ObjectDetector objectDetector;

  var selectedImagePath = ''.obs;
  RxBool isLoading = false.obs;
  XFile? _imageFile;
  List<DetectedObject> _objectsList = [];
  ui.Image? _image;

  @override
  void initState() {
    super.initState();

    _loadModel();
  }

  _loadModel() {
    objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );

    //TODO
    // objectDetector = ObjectDetector(
    //   options: LocalObjectDetectorOptions(
    //     mode: DetectionMode.single,
    //     classifyObjects: true,
    //     multipleObjects: true,
    //     modelPath: 'assets/yolov8_small/yolov8n.tflite',
    //   ),
    // );
  }

  _getImageAndDetectObjects() async {
    _imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (_imageFile == null) return;

    isLoading.value = true;
    _objectsList.clear();
    selectedImagePath.value = _imageFile!.path;

    final inputImage = InputImage.fromFilePath(_imageFile!.path);

    _objectsList = await objectDetector.processImage(inputImage);
    print('object detected: ${_objectsList.length}');

    final imageData = await _imageFile!.readAsBytes();
    _image = await decodeImageFromList(imageData);

    isLoading.value = false;

    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();

    objectDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox.expand(
              child: Column(
                children: [
                  _imageBox(),
                  const SizedBox(height: marginX2),
                  _button(),
                ],
              ),
            ),
            _loading(),
          ],
        ),
      ),
    );
  }

  _imageBox() {
    return selectedImagePath.value.isEmpty || _image == null
        ? Container(
            height: 300.0,
            width: 300.0,
            color: Colors.grey.shade300,
          )
        : SizedBox(
            height: 300.0,
            width: 300.0,
            child: FittedBox(
              child: SizedBox(
                width: _image?.width.toDouble(),
                height: _image?.height.toDouble(),
                child: CustomPaint(
                  painter: ObjectPainter(_image!, _objectsList),
                ),
              ),
            ),
          );
  }

  _button() {
    return InkWell(
      onTap: () async {
        _getImageAndDetectObjects();
      },
      child: Container(
        padding: const EdgeInsets.all(marginX2),
        color: Colors.grey,
        child: const TextFontStyle('Pick Image'),
      ),
    );
  }

  _loading() {
    return Obx(() {
      return Visibility(
        visible: isLoading.value,
        child: const CustomLoading(),
      );
    });
  }
}

class ObjectPainter extends CustomPainter {
  final ui.Image image;
  final List<DetectedObject> objects;
  final List<Rect> rects = [];

  ObjectPainter(this.image, this.objects) {
    for (var i = 0; i < objects.length; i++) {
      rects.add(objects[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    canvas.drawImage(image, Offset.zero, Paint());

    for (var i = 0; i < objects.length; i++) {
      final object = objects[i];
      final rect = rects[i];

      canvas.drawRect(rect, paint);

      String label = '';
      if (object.labels.isNotEmpty) {
        print(object.labels.map((e) => e.text));
      }
      // if (object.labels.isNotEmpty) {
      //   final firstLabel = object.labels.first;
      //   label = '${firstLabel.text} ${(firstLabel.confidence * 100).toStringAsFixed(2)}%';
      //   print(label);
      // } else {
      //   label = 'Unknown';
      // }

      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 20.0,
          backgroundColor: Colors.white,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );

      textPainter.paint(canvas, Offset(rect.left, rect.top - 25));
    }
  }

  @override
  bool shouldRepaint(ObjectPainter oldDelegate) {
    return image != oldDelegate.image || objects != oldDelegate.objects;
  }
}

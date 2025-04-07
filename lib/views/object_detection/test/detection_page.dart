import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/widgets/text_font_style.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  late Interpreter _interpreter;
  late List<String> _labels;
  List<dynamic>? _recognitions;
  File? _image;
  int _imageHeight = 0;
  int _imageWidth = 0;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/data/yolov8s.tflite');
    } catch (e) {
      log('Error loading model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      String labelsData = await rootBundle.loadString('assets/data/labels.txt');
      _labels = labelsData.split('\n');
    } catch (e) {
      log('Error loading labels: $e');
    }
  }

  Future<void> _detectObjects(File image) async {
    // แปลงข้อมูลภาพมาเป็น byte
    img.Image? imageInput = img.decodeImage(await image.readAsBytes());
    if (imageInput == null) {
      log('Error decoding image');
      return;
    }

    // ขนาดภาพ original
    _imageHeight = imageInput.height;
    _imageWidth = imageInput.width;

    // resize ภาพให้เป็นขนาด 640x640 ตามที่โมเดลต้องการ
    img.Image resizedImage =
        img.copyResize(imageInput, width: 640, height: 640);

    // สร้าง list 3 มิติ [640, 640, 3]
    List<List<List<num>>> imageMatrix = List.generate(
      640,
      (y) => List.generate(
        640,
        (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [pixel.r, pixel.g, pixel.b];
        },
      ),
    );

    // นำ imageMatrix 3 มิติ มาแปลงเป็น 4 มิติ [1, 640, 640, 3]
    List<List<List<List<num>>>> input = [imageMatrix];
    List<List<List<num>>> output = List.generate(
      1,
      (i) => List.generate(
        84,
        (j) => List.generate(
          8400,
          (k) => 0,
        ),
      ),
    );

    _interpreter.run(input, output);
    _recognitions = _processOutput(output[0]);

    setState(() {});
  }

  List<dynamic> _processOutput(List<List<num>> output) {
    List<dynamic> recognitions = [];
    double confidenceThreshold = 0.6;
    double minObjectSize = 50.0;

    for (int i = 0; i < output[0].length; i++) {
      if (output[4][i] > confidenceThreshold) {
        double x = (output[0][i] * _imageWidth / 640).toDouble();
        double y = (output[1][i] * _imageHeight / 640).toDouble();
        double w = (output[2][i] * _imageWidth / 640).toDouble();
        double h = (output[3][i] * _imageHeight / 640).toDouble();

        if (w > minObjectSize && h > minObjectSize) {
          int labelIndex = output
              .sublist(5)
              .map((list) => list[i])
              .toList()
              .indexOf(
              output.sublist(5).map((list) => list[i]).toList().reduce(max));
          String label = _labels[labelIndex];

          // create bounding box
          recognitions.add({
            'rect': Rect.fromLTWH(x - w / 2, y - h / 2, w, h),
            'label': label,
            'confidence': output[4][i],
          });
        }
      }
    }

    return recognitions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SizedBox(
          width: Get.width,
          child: Column(
            children: [
              _selectedImage(),
              const SizedBox(height: margin),
              _selectedImageButton(),
              const SizedBox(height: margin),
              _detectedLabel(),
            ],
          ),
        ),
      ),
    );
  }

  _selectedImage() {
    if (_image != null) {
      return Expanded(
        child: FittedBox(
          child: SizedBox(
            width: _imageWidth.toDouble(),
            height: _imageHeight.toDouble(),
            child: CustomPaint(
              painter: ObjectPainter(
                _image,
                _recognitions,
                _imageWidth,
                _imageHeight,
              ),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
    // if (_image != null) {
    //   return Column(
    //     children: [
    //       Container(
    //         height: 300.0,
    //         width: 300.0,
    //         color: Colors.grey,
    //         child: Image.file(
    //           _image!,
    //         ),
    //       ),
    //     ],
    //   );
    // } else {
    //   return Container(
    //     height: 300.0,
    //     width: 300.0,
    //     color: Colors.grey,
    //   );
    // }
  }

  _selectedImageButton() {
    return InkWell(
      onTap: () async {
        final pickedImage =
            await ImagePicker().pickImage(source: ImageSource.gallery);

        if (pickedImage != null) {
          _image = File(pickedImage.path);
          _detectObjects(_image!);
          setState(() {});
        }
      },
      child: Container(
        width: 150.0,
        height: 40.0,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: const Center(
          child: TextFontStyle('Pick Image'),
        ),
      ),
    );
  }

  _detectedLabel() {
    // return SizedBox();
    if (_recognitions != null && _recognitions!.isNotEmpty) {
      return Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: _recognitions!.map((e) {
              return TextFontStyle(
                  '${e['label'].toString()} ${e['confidence'].toString()}');
            }).toList(),
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}

class ObjectPainter extends CustomPainter {
  final File? imageFile;
  final List<dynamic>? recognitions;
  final int imageWidth;
  final int imageHeight;

  ObjectPainter(
      this.imageFile,
      this.recognitions,
      this.imageWidth,
      this.imageHeight,
      );

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      final image = FileImage(imageFile!);
      image.resolve(ImageConfiguration.empty).addListener(
        ImageStreamListener((ImageInfo info, bool synchronousCall) {
          paintImage(
            canvas: canvas,
            rect: Rect.fromLTRB(
                0, 0, imageWidth.toDouble(), imageHeight.toDouble()),
            image: info.image,
          );
        }),
      );
    }

    if (recognitions != null) {
      for (var recognition in recognitions!) {
        final rect = recognition['rect'];
        final label = recognition['label'];
        final confidence = recognition['confidence'];

        final paint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawRect(rect, paint);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$label (${(confidence * 100).toStringAsFixed(2)}%)',
            style: const TextStyle(color: Colors.red),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
            canvas, Offset(rect.left, rect.top - textPainter.height));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
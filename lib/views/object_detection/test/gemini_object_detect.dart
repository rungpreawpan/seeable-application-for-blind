import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ObjectDetection extends StatefulWidget {
  const ObjectDetection({super.key});

  @override
  State<ObjectDetection> createState() => _ObjectDetectionState();
}

class _ObjectDetectionState extends State<ObjectDetection> {
  late Interpreter _interpreter;
  late List<String> _labels;
  File? _image;
  List<dynamic>? _recognitions;
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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 640.0,
      maxHeight: 640.0,
    );

    if (pickedFile != null) {
      _image = File(pickedFile.path);
      _detectObjects(_image!);
      setState(() {});
    }
  }

  Future<void> _detectObjects(File image) async {
    img.Image? imageInput = img.decodeImage(await image.readAsBytes());
    if (imageInput == null) {
      log('Error decoding image');
      return;
    }

    _imageHeight = imageInput.height;
    _imageWidth = imageInput.width;

    // resize to 640x640
    img.Image resizedImage =
        img.copyResize(imageInput, width: 640, height: 640);
    // create list of input shape [1, 640, 640, 3]
    List<List<List<num>>> imageMatrix = List.generate(
      640,
      (y) => List.generate(
        640,
        (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [pixel.r/255.0, pixel.g/255.0, pixel.b/255.0]; //แก้เพิ่มที่เอามาหารด้วย 255
        },
      ),
    );

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
    for (int i = 0; i < output[0].length; i++) {
      if (output[4][i] > 0.5) {
        double x = (output[0][i] * _imageWidth).toDouble(); //แก้เอา 640 ที่หาร width height ออก
        double y = (output[1][i] * _imageHeight).toDouble() ;
        double w = (output[2][i] * _imageWidth).toDouble();
        double h = (output[3][i] * _imageHeight).toDouble();

        int labelIndex = output
            .sublist(5)
            .map((list) => list[i])
            .toList()
            .indexOf(
                output.sublist(5).map((list) => list[i]).toList().reduce(max));
        String label = _labels[labelIndex];

        // create bouding box
        recognitions.add({
          'rect': Rect.fromLTWH(x - w / 2, y - h / 2, w, h),
          'label': label,
          'confidence': output[4][i],
        });
      }
    }
    return recognitions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Detection'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _showImage(),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _showImage() {
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
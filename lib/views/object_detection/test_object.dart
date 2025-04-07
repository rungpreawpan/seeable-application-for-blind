import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ImageClassificationScreen extends StatefulWidget {
  const ImageClassificationScreen({super.key});

  @override
  State<ImageClassificationScreen> createState() =>
      _ImageClassificationScreenState();
}

class _ImageClassificationScreenState extends State<ImageClassificationScreen> {
  File? _image;
  late Interpreter _interpreter;
  List<String> _labels = [];
  String _result = 'No result yet';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
          'assets/data/yolov8s.tflite'); // Replace with your model path
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData = await File('assets/data/labels.txt')
          .readAsString(); // Replace with your labels path
      _labels = labelsData.split('\n');
    } catch (e) {
      print('Error loading labels: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = 'Processing...';
        _isBusy = true;
      });
      _classifyImage(_image!);
    }
  }

  // Future<void> _classifyImage(File image) async {
  //   final inputImage = img.decodeImage(await image.readAsBytes());
  //   if (inputImage == null) {
  //     setState(() {
  //       _result = 'Error decoding image.';
  //       _isBusy = false;
  //     });
  //     return;
  //   }
  //   final resizedImage = img.copyResize(inputImage, width: 224, height: 224);
  //   final input = _imageToByteListFloat32(resizedImage, 224);
  //   final output = List.generate(
  //     1,
  //     (index) => Float32List(1001),
  //   ); // Adjust 1001 to your model's output size.
  //
  //   _interpreter.run(input, output);
  //
  //   final results = output[0];
  //   int maxIndex = 0;
  //   double maxConfidence = 0;
  //   for (int i = 0; i < results.length; i++) {
  //     if (results[i] > maxConfidence) {
  //       maxConfidence = results[i];
  //       maxIndex = i;
  //     }
  //   }
  //
  //   setState(() {
  //     _result =
  //         '${_labels[maxIndex]} (Confidence: ${(maxConfidence * 100).toStringAsFixed(2)}%)';
  //     _isBusy = false;
  //   });
  // }

  Future<void> _classifyImage(File image) async {
    final inputImage = img.decodeImage(await image.readAsBytes());
    if (inputImage == null) {
      setState(() {
        _result = 'Error decoding image.';
        _isBusy = false;
      });
      return;
    }

    // Resize image to 640x640
    final resizedImage = img.copyResize(inputImage, width: 640, height: 640);
    final input = _imageToByteListFloat32(resizedImage, 640);

    // Prepare output buffer
    final outputShape = _interpreter.getOutputTensors()[0].shape;
    final output = List.generate(
        outputShape[0],
            (index) => Float32List(outputShape[1] * outputShape[2]));

    // Run inference
    _interpreter.run(input, output);

    // Decode output
    final results = output[0];
    final List<Map<String, dynamic>> detections = [];

    for (int i = 0; i < 8400; i++) {
      final double confidence = results[4 + i * 84];
      if (confidence > 0.5) { // Filter by confidence threshold
        final double x = results[0 + i * 84];
        final double y = results[1 + i * 84];
        final double width = results[2 + i * 84];
        final double height = results[3 + i * 84];

        int classId = 0;
        double maxClassScore = 0;
        for (int j = 0; j < 80; j++) {
          final double classScore = results[5 + j + i * 84];
          if (classScore > maxClassScore) {
            maxClassScore = classScore;
            classId = j;
          }
        }

        detections.add({
          'classId': classId,
          'confidence': confidence,
          'x': x,
          'y': y,
          'width': width,
          'height': height,
        });
      }
    }

    // Apply Non-Max Suppression (NMS) to filter overlapping boxes
    final filteredDetections = _nonMaxSuppression(detections);

    // Display results
    setState(() {
      _result = 'Detected ${filteredDetections.length} objects';
      _isBusy = false;
    });
  }

  List<Map<String, dynamic>> _nonMaxSuppression(List<Map<String, dynamic>> detections) {
    detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));

    final List<Map<String, dynamic>> filteredDetections = [];
    while (detections.isNotEmpty) {
      final Map<String, dynamic> current = detections.removeAt(0);
      filteredDetections.add(current);

      detections.removeWhere((detection) {
        final double iou = _calculateIOU(current, detection);
        return iou > 0.5; // Overlap threshold
      });
    }

    return filteredDetections;
  }

  double _calculateIOU(Map<String, dynamic> boxA, Map<String, dynamic> boxB) {
    final double x1 = max(boxA['x'], boxB['x']);
    final double y1 = max(boxA['y'], boxB['y']);
    final double x2 = min(boxA['x'] + boxA['width'], boxB['x'] + boxB['width']);
    final double y2 = min(boxA['y'] + boxA['height'], boxB['y'] + boxB['height']);

    final double intersection = max(0, x2 - x1) * max(0, y2 - y1);
    final double areaA = boxA['width'] * boxA['height'];
    final double areaB = boxB['width'] * boxB['height'];
    final double union = areaA + areaB - intersection;

    return intersection / union;
  }

  Uint8List _imageToByteListFloat32(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixelSafe(j, i);
        buffer[pixelIndex++] = pixel.r / 255.0; // Normalize to [0, 1]
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Classification'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null ? Text('No image selected.') : Image.file(_image!),
            SizedBox(height: 20),
            _isBusy ? CircularProgressIndicator() : Text(_result),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }
}

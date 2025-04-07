import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class YOLOModel {
  late Interpreter _interpreter;
  late List<String> _labels;
  static const int inputSize = 640;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/data/yolov8s.tflite');
      _interpreter.allocateTensors();
      _labels = await _loadLabels();
      _isModelLoaded = true;
      print("✅ Model loaded successfully!");
    } catch (e) {
      print("❌ Error loading model: $e");
    }
  }

  Future<List<String>> _loadLabels() async {
    final labelData = await rootBundle.loadString('assets/data/labels.txt');
    return labelData.split('\n');
  }

  // Future<List<Map<String, dynamic>>> runInference(File imageFile) async {
  //   if (!_isModelLoaded) {
  //     throw Exception("❌ Model is not loaded! Call `await loadModel()` first.");
  //   }
  //
  //   Float32List input = preprocessImage(imageFile, inputSize);
  //
  //   // ✅ Ensure input shape is [1, 640, 640, 3]
  //   var inputTensor = [input];
  //
  //   var output = List.generate(1, (i) => List.filled(25200, 0.0));
  //
  //   try {
  //     _interpreter.run(inputTensor, output);
  //     print("✅ Inference successful!");
  //     return _parseResults(output);
  //   } catch (e) {
  //     print("❌ Error during inference: $e");
  //     return [];
  //   }
  // }

  Future<List<Map<String, dynamic>>> runInference(File imageFile) async {
    if (!_isModelLoaded) {
      throw Exception("❌ Model is not loaded! Call `await loadModel()` first.");
    }

    Float32List input = preprocessImage(imageFile, inputSize);
    var inputTensor = [input]; // ✅ ใช้ List

    // ✅ ตรวจสอบขนาด output
    var outputShape = _interpreter.getOutputTensor(0).shape;
    print("🧐 Output Shape: $outputShape");

    var outputBuffer = List.generate(outputShape.reduce((a, b) => a * b), (_) => 0.0);
    var outputTensor = [outputBuffer];

    try {
      _interpreter.run(inputTensor, outputTensor);
      print("✅ Inference successful!");
      return _parseResults(outputTensor);
    } catch (e) {
      print("❌ Error during inference: $e");
      return [];
    }
  }

  // Float32List preprocessImage(File imageFile, int size) {
  //   img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;
  //   img.Image resizedImage = img.copyResize(image, width: size, height: size);
  //
  //   var buffer = Float32List(1 * size * size * 3);
  //   int pixelIndex = 0;
  //
  //   for (int y = 0; y < size; y++) {
  //     for (int x = 0; x < size; x++) {
  //       img.Pixel pixel = resizedImage.getPixelSafe(x, y);
  //
  //       buffer[pixelIndex++] = pixel.r / 255.0;
  //       buffer[pixelIndex++] = pixel.g / 255.0;
  //       buffer[pixelIndex++] = pixel.b / 255.0;
  //     }
  //   }
  //
  //   // Add batch dimension: Convert from [640, 640, 3] to [1, 640, 640, 3]
  //   return Float32List.fromList(buffer);
  // }

  Float32List preprocessImage(File imageFile, int size) {
    img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;
    img.Image resizedImage = img.copyResize(image, width: size, height: size);

    var buffer = Float32List(size * size * 3);
    int pixelIndex = 0;

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final pixel = resizedImage.getPixelSafe(x, y);
        buffer[pixelIndex++] = pixel.r / 255.0; // Normalize to [0, 1]
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return buffer;
  }

  // List<Map<String, dynamic>> _parseResults(List<List<double>> output) {
  //   List<Map<String, dynamic>> results = [];
  //   for (int i = 0; i < output[0].length; i += 6) {
  //     double confidence = output[0][i + 4];
  //     if (confidence > 0.5) {
  //       int labelIndex = output[0][i + 5].toInt();
  //       results.add({
  //         'x': output[0][i],
  //         'y': output[0][i + 1],
  //         'width': output[0][i + 2],
  //         'height': output[0][i + 3],
  //         'confidence': confidence,
  //         'label': _labels[labelIndex],
  //       });
  //     }
  //   }
  //   return results;
  // }

  List<Map<String, dynamic>> _parseResults(List<List<double>> output) {
    List<Map<String, dynamic>> results = [];
    List<double> rawOutput = output[0]; // Flatten array

    int numDetections = rawOutput.length ~/ 84; // จำนวน detection

    for (int i = 0; i < numDetections; i++) {
      double confidence = rawOutput[i * 84 + 4]; // Confidence score
      if (confidence > 0.5) {
        int maxIndex = 0;
        double maxClassScore = 0.0;

        // ค้นหาคลาสที่มีค่าความมั่นใจสูงสุด
        for (int j = 5; j < 84; j++) {
          if (rawOutput[i * 84 + j] > maxClassScore) {
            maxClassScore = rawOutput[i * 84 + j];
            maxIndex = j - 5;
          }
        }

        // เก็บค่าเป็น bounding box
        results.add({
          'x': rawOutput[i * 84] * inputSize,
          'y': rawOutput[i * 84 + 1] * inputSize,
          'width': rawOutput[i * 84 + 2] * inputSize,
          'height': rawOutput[i * 84 + 3] * inputSize,
          'confidence': confidence,
          'label': _labels[maxIndex],
        });
      }
    }
    return results;
  }
}

class TestYolo extends StatefulWidget {
  const TestYolo({super.key});

  @override
  State<TestYolo> createState() => _TestYoloState();
}

class _TestYoloState extends State<TestYolo> {
  final YOLOModel _yoloModel = YOLOModel();
  File? _selectedImage;
  List<Map<String, dynamic>> _detections = [];
  bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _yoloModel.loadModel();
    setState(() {
      _isModelLoaded = true;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_isModelLoaded) {
      print("❌ Model not loaded yet!");
      return;
    }

    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    _runObjectDetection();
  }

  Future<void> _runObjectDetection() async {
    if (_selectedImage == null) return;
    List<Map<String, dynamic>> results =
        await _yoloModel.runInference(_selectedImage!);

    setState(() {
      _detections = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOLOv8 Object Detection'),
      ),
      body: Column(
        children: [
          if (!_isModelLoaded)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_selectedImage != null)
            Expanded(
              child: Stack(
                children: [
                  Image.file(_selectedImage!),
                  ..._detections.map((detection) {
                    return Positioned(
                      left: detection['x'],
                      top: detection['y'],
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${detection['label']} (${(detection['confidence'] * 100).toStringAsFixed(1)}%)",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                child: const Text('📷 Camera'),
              ),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: const Text('🖼️ Gallery'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

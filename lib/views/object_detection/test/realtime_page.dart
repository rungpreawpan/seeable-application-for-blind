import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/object_detection/components/object_detection_view.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/text_font_style.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class RealtimePage extends StatefulWidget {
  const RealtimePage({super.key});

  @override
  State<RealtimePage> createState() => _RealtimePageState();
}

class _RealtimePageState extends State<RealtimePage> {
  File? oldImageFile;
  File? _imageFile;
  int? imageHeight;
  int? imageWidth;
  bool _isLoading = false;
  bool _isProcessing = false;
  late Interpreter _interpreter;
  late List<String> _labels;
  List<Map<String, dynamic>> _recognitions = [];

  // Camera related variables
  List<CameraDescription>? cameras;
  CameraController? cameraController;
  bool _isCameraInitialized = false;
  bool _isIntervalMode = false;
  Timer? _captureTimer;
  int _captureInterval = 1; // seconds
  int _captureCount = 0;
  bool _isCapturing = false;

  // เพิ่มตัวแปรเพื่อจำกัดจำนวนรูปภาพที่เก็บไว้
  int _maxStoredImages = 3; // เก็บไว้สูงสุด 3 รูป
  List<File> _capturedImageFiles = []; // เก็บรายการรูปที่ถ่ายไว้

  final int inputSize = 640;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _initializeCamera();
  }

  Future<void> _loadModel() async {
    try {
      // Load YOLOv8n model
      _interpreter =
          await Interpreter.fromAsset('assets/yolov8_small/yolov8n.tflite');
      log('Input Shape: ${_interpreter.getInputTensor(0).shape}');
      log('Output Shape: ${_interpreter.getOutputTensor(0).shape}');

      // Load labels
      final labelsData =
          await rootBundle.loadString('assets/yolov8_small/yolov8n.txt');
      _labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();
      log('Model loaded with ${_labels.length} labels');
    } catch (e) {
      log('Error loading model: $e');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        cameraController = CameraController(
          cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await cameraController!.initialize();

        if (!mounted) return;

        setState(() {
          _isCameraInitialized = true;
        });

        log('Camera initialized successfully');
      } else {
        log('No cameras available');
      }
    } catch (e) {
      log('Error initializing camera: $e');
    }
  }

  Future<void> _startIntervalCapture() async {
    if (!_isCameraInitialized ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
      log('Camera not initialized');
      return;
    }

    if (_isIntervalMode) return; // Already in interval mode

    // ปรับความละเอียดของกล้องให้ต่ำลงเพื่อประหยัดหน่วยความจำ
    try {
      // หยุดกล้องที่ใช้อยู่
      await cameraController!.dispose();

      // เริ่มกล้องใหม่ด้วยความละเอียดต่ำ
      cameraController = CameraController(
        cameras![0],
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await cameraController!.initialize();

      if (!mounted) return;
    } catch (e) {
      log('Error resetting camera with lower resolution: $e');
      return;
    }

    setState(() {
      _isIntervalMode = true;
      _imageFile = null;
      _recognitions = [];
      _captureCount = 0;
      _capturedImageFiles.clear();
    });

    // เริ่มตัวจับเวลาสำหรับการถ่ายภาพเป็นช่วงเวลา
    _captureTimer =
        Timer.periodic(Duration(seconds: _captureInterval), (timer) {
      _captureAndDetect();
    });

    // // ถ่ายภาพทันทีสำหรับเฟรมแรก
    // _captureAndDetect();
  }

  Future<void> _stopIntervalCapture() async {
    if (!_isIntervalMode) return;

    _captureTimer?.cancel();
    _captureTimer = null;

    // ปรับความละเอียดของกล้องกลับเป็นค่าเดิม
    try {
      // หยุดกล้องที่ใช้อยู่
      await cameraController!.dispose();

      // เริ่มกล้องใหม่ด้วยความละเอียดปกติ
      cameraController = CameraController(
        cameras![0],
        ResolutionPreset.medium, // กลับไปใช้ความละเอียดปกติ
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await cameraController!.initialize();

      if (!mounted) return;
    } catch (e) {
      log('Error resetting camera with normal resolution: $e');
    }

    setState(() {
      _isIntervalMode = false;

      // ล้างรายการรูปภาพและลบไฟล์
      for (final file in _capturedImageFiles) {
        file.exists().then((exists) {
          if (exists) {
            file.delete().catchError((e) {
              log('Error deleting image file: $e');
            });
          }
        });
      }

      _capturedImageFiles.clear();
      _recognitions = [];
    });
  }

  Future<void> _captureAndDetect() async {
    if (_isCapturing || _isProcessing) return;

    try {
      _isCapturing = true;

      // กำหนดคุณภาพของรูปภาพให้ต่ำลง (เพื่อลดขนาดไฟล์ ใช้หน่วยความจำน้อยลง)
      final XFile picture = await cameraController!.takePicture();
      log('Picture captured: ${picture.path}');

      _captureCount++;

      // สร้าง File จาก XFile
      final File newImageFile = File(picture.path);

      // บันทึกรูปใหม่ลงในรายการ
      _capturedImageFiles.add(newImageFile);

      // จำกัดจำนวนรูปภาพที่เก็บไว้
      while (_capturedImageFiles.length > _maxStoredImages) {
        final File oldFile = _capturedImageFiles.removeAt(0);
        try {
          if (await oldFile.exists()) {
            await oldFile.delete();
            log('Deleted old image file: ${oldFile.path}');
          }
        } catch (e) {
          log('Error deleting old image: $e');
        }
      }

      // อัปเดต UI
      if (mounted) {
        setState(() {
          _imageFile = newImageFile;
          _recognitions = []; // ล้างผลการตรวจจับเดิม
        });

        // ประมวลผลการตรวจจับวัตถุ - พยายามลดขนาดรูปภาพให้เล็กลง
        await _runObjectDetection(reduceSize: true);
      }
    } catch (e) {
      log('Error capturing image: $e');
    } finally {
      _isCapturing = false;

      // บังคับให้เรียกใช้ Garbage Collection - อาจช่วยได้ในบางกรณี
      // ไม่รับประกันว่า GC จะทำงานจริง แต่เป็นการบอกใบ้ระบบ
      // อาจไม่มีผลใน Dart หรือ Flutter เวอร์ชันใหม่
      // ในกรณีที่มีปัญหาเรื่องหน่วยความจำจริงๆ
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _getImage(XFile? pickedFile) async {
    // Stop interval mode if active
    if (_isIntervalMode) {
      await _stopIntervalCapture();
    }

    setState(() {
      _isLoading = true;
      _recognitions = [];
    });

    try {
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _runObjectDetection();
      }
    } catch (e) {
      log('Error picking image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ปรับปรุงฟังก์ชันประมวลผลการตรวจจับวัตถุ
  Future<void> _runObjectDetection({bool reduceSize = false}) async {
    if (_imageFile == null) return;

    if (_isProcessing) {
      log('Still processing previous image, skipping');
      return;
    }

    _isProcessing = true;

    try {
      // อ่านข้อมูลไฟล์รูปภาพ
      final imageData = await _imageFile!.readAsBytes();

      // ถอดรหัสรูปภาพ
      img.Image? image = img.decodeImage(imageData);
      if (image == null) {
        log('Failed to decode image');
        _isProcessing = false;
        return;
      }

      // ลดขนาดรูปภาพก่อนประมวลผล (ถ้าต้องการ)
      if (reduceSize && image.width > 1000) {
        // ลดขนาดรูปให้เล็กลง ถ้าใหญ่เกินไป
        double scaleFactor = 1000.0 / image.width;
        image = img.copyResize(
          image,
          width: (image.width * scaleFactor).round(),
          height: (image.height * scaleFactor).round(),
          interpolation: img.Interpolation.average, // ใช้ average เพื่อความเร็ว
        );
        log('Reduced image size to: ${image.width}x${image.height}');
      }

      // บันทึกขนาดรูปภาพต้นฉบับ
      imageHeight = image.height;
      imageWidth = image.width;

      // ย่อขนาดรูปภาพให้พอดีกับขนาดอินพุตของโมเดล
      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.average, // ใช้ average เพื่อความเร็ว
      );

      // เตรียมข้อมูลสำหรับรูปแบบอินพุตของโมเดล
      final inputShape = _interpreter.getInputTensor(0).shape;
      List<List<List<List<double>>>> inputData;

      // ตรวจสอบรูปแบบอินพุต (NCHW หรือ NHWC)
      if (inputShape.length == 4 && inputShape[1] == 3) {
        // NCHW format
        inputData = _prepareInputNCHW(resizedImage);
      } else {
        // NHWC format
        inputData = _prepareInputNHWC(resizedImage);
      }

      // เตรียมเอาต์พุต
      final outputShape = _interpreter.getOutputTensor(0).shape;
      List<dynamic> outputData = [];

      // เตรียมคอนเทนเนอร์สำหรับเอาต์พุตตามรูปแบบที่รองรับ
      if (outputShape.length == 3) {
        if (outputShape[1] == 84) {
          // Format [1, 84, 8400]
          var output = List.generate(
            outputShape[0],
            (_) => List.generate(
              outputShape[1],
              (_) => List<double>.filled(outputShape[2], 0.0),
            ),
          );
          outputData = output;
        } else if (outputShape[2] == 84) {
          // Format [1, 8400, 84]
          var output = List.generate(
            outputShape[0],
            (_) => List.generate(
              outputShape[1],
              (_) => List<double>.filled(outputShape[2], 0.0),
            ),
          );
          outputData = output;
        } else {
          log('Unsupported output shape: $outputShape');
          _isProcessing = false;
          return;
        }
      } else {
        log('Unsupported output shape: $outputShape');
        _isProcessing = false;
        return;
      }

      // รันการอนุมาน
      _interpreter.run(inputData, outputData);

      // ประมวลผลผลลัพธ์
      final results =
          _processOutputs(outputData, outputShape, imageWidth!, imageHeight!);

      // ลดจำนวนผลลัพธ์ถ้ามีมากเกินไป (เพื่อประหยัดหน่วยความจำ)
      List<Map<String, dynamic>> limitedResults = results;
      if (results.length > 20) {
        // จำกัดเหลือ 20 วัตถุที่มีความเชื่อมั่นสูงสุด
        limitedResults = results.sublist(0, 20);
      }

      if (mounted) {
        setState(() {
          _recognitions = limitedResults;
          log('Found ${_recognitions.length} objects (limited from ${results.length})');
        });
      }

      // ล้างตัวแปรที่ไม่ใช้แล้ว - ลบบรรทัดนี้ออก
      // image = null; // อันนี้ยังทำได้
      // inputData = null; // ไม่ต้องล้างอย่างนี้
      // outputData = null; // ไม่ต้องล้างอย่างนี้
      // results.clear(); // ไม่จำเป็นต้องล้าง เพราะตัวแปรจะหมดอายุเมื่อออกจากฟังก์ชัน
    } catch (e) {
      log('Error running object detection: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Prepare input in NCHW format [batch, channels, height, width]
  List<List<List<List<double>>>> _prepareInputNCHW(img.Image image) {
    return List.generate(
      1, // batch size
      (_) => List.generate(
        3, // channels (RGB)
        (c) => List.generate(
          inputSize, // height
          (y) => List.generate(
            inputSize, // width
            (x) {
              final pixel = image.getPixel(x, y);
              if (c == 0) return pixel.r / 255.0; // Red channel
              if (c == 1) return pixel.g / 255.0; // Green channel
              return pixel.b / 255.0; // Blue channel
            },
          ),
        ),
      ),
    );
  }

  // Prepare input in NHWC format [batch, height, width, channels]
  List<List<List<List<double>>>> _prepareInputNHWC(img.Image image) {
    return List.generate(
      1, // batch size
      (_) => List.generate(
        inputSize, // height
        (y) => List.generate(
          inputSize, // width
          (x) => List.generate(
            3, // channels (RGB)
            (c) {
              final pixel = image.getPixel(x, y);
              if (c == 0) return pixel.r / 255.0; // Red channel
              if (c == 1) return pixel.g / 255.0; // Green channel
              return pixel.b / 255.0; // Blue channel
            },
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _processOutputs(List<dynamic> outputData,
      List<int> outputShape, int sourceWidth, int sourceHeight) {
    const confidenceThreshold = 0.25;
    const iouThreshold = 0.45;
    List<Map<String, dynamic>> detections = [];

    try {
      // Option 1: Transpose-style output (shape [1, 84, 8400])
      if (outputShape.length == 3 && outputShape[1] == 84) {
        final numClasses = min(outputShape[1] - 4, 80); // Cap at 80 classes
        final numBoxes = outputShape[2];

        log('Processing transpose-style output: $numBoxes boxes, $numClasses classes');

        for (int i = 0; i < numBoxes; i++) {
          try {
            // Get bbox coordinates
            final x = outputData[0][0][i] as double; // Center x
            final y = outputData[0][1][i] as double; // Center y
            final w = outputData[0][2][i] as double; // Width
            final h = outputData[0][3][i] as double; // Height

            // Find class with highest confidence
            double maxConfidence = 0;
            int classId = 0;

            for (int c = 0; c < numClasses; c++) {
              final confidence = outputData[0][4 + c][i] as double;
              if (confidence > maxConfidence) {
                maxConfidence = confidence;
                classId = c;
              }
            }

            // Filter by confidence threshold
            if (maxConfidence > confidenceThreshold) {
              final label =
                  classId < _labels.length ? _labels[classId] : 'Unknown';

              // Skip unknown labels
              if (label == 'Unknown') {
                continue;
              }

              // YOLOv8 outputs normalized coordinates (0-1)
              // Determine if coordinates are normalized (0-1) or absolute
              double normalizedX = x;
              double normalizedY = y;
              double normalizedW = w;
              double normalizedH = h;

              // Check if inputs might be in input size coordinates (0-640)
              if (x > 1.0 || y > 1.0 || w > 1.0 || h > 1.0) {
                if (x <= inputSize &&
                    y <= inputSize &&
                    w <= inputSize &&
                    h <= inputSize) {
                  // Values are probably in input size space (0-640)
                  normalizedX = x / inputSize;
                  normalizedY = y / inputSize;
                  normalizedW = w / inputSize;
                  normalizedH = h / inputSize;
                } else if (x <= sourceWidth && y <= sourceHeight) {
                  // Values might be in source image space
                  normalizedX = x / sourceWidth;
                  normalizedY = y / sourceHeight;
                  normalizedW = w / sourceWidth;
                  normalizedH = h / sourceHeight;
                } else {
                  // Values are using some other scale we don't understand
                  // Use a different approach - try to estimate the scale
                  double estimatedScale = max(
                    max(x, y) / max(sourceWidth, sourceHeight),
                    max(w, h) / max(sourceWidth, sourceHeight),
                  );
                  normalizedX = x / (estimatedScale * sourceWidth);
                  normalizedY = y / (estimatedScale * sourceHeight);
                  normalizedW = w / (estimatedScale * sourceWidth);
                  normalizedH = h / (estimatedScale * sourceHeight);
                }
              }

              // Convert normalized coordinates to pixel values on the original image
              final xmin =
                  ((normalizedX - normalizedW / 2) * sourceWidth).round();
              final ymin =
                  ((normalizedY - normalizedH / 2) * sourceHeight).round();
              final xmax =
                  ((normalizedX + normalizedW / 2) * sourceWidth).round();
              final ymax =
                  ((normalizedY + normalizedH / 2) * sourceHeight).round();

              // Clamp values to ensure they're within image boundaries
              final finalXmin = xmin.clamp(0, sourceWidth - 1);
              final finalYmin = ymin.clamp(0, sourceHeight - 1);
              final finalXmax = xmax.clamp(0, sourceWidth - 1);
              final finalYmax = ymax.clamp(0, sourceHeight - 1);

              detections.add({
                'bbox': [finalXmin, finalYmin, finalXmax, finalYmax],
                'confidence': maxConfidence,
                'class': classId,
                'label': label,
              });
            }
          } catch (e) {
            log('Error processing detection $i: $e');
          }
        }
      }
      // Option 2: Box-first output (shape [1, 8400, 84])
      else if (outputShape.length == 3 && outputShape[2] == 84) {
        final numBoxes = outputShape[1];
        final numClasses = min(outputShape[2] - 4, 80); // Cap at 80 classes

        log('Processing box-first output: $numBoxes boxes, $numClasses classes');

        for (int i = 0; i < numBoxes; i++) {
          try {
            // Get bbox coordinates
            final x = outputData[0][i][0] as double; // Center x
            final y = outputData[0][i][1] as double; // Center y
            final w = outputData[0][i][2] as double; // Width
            final h = outputData[0][i][3] as double; // Height

            // Find class with highest confidence
            double maxConfidence = 0;
            int classId = 0;

            for (int c = 0; c < numClasses; c++) {
              final confidence = outputData[0][i][4 + c] as double;
              if (confidence > maxConfidence) {
                maxConfidence = confidence;
                classId = c;
              }
            }

            // Filter by confidence threshold
            if (maxConfidence > confidenceThreshold) {
              final label =
                  classId < _labels.length ? _labels[classId] : 'Unknown';

              // Skip unknown labels
              if (label == 'Unknown') {
                continue;
              }

              // Determine if coordinates are normalized (0-1) or absolute
              double normalizedX = x;
              double normalizedY = y;
              double normalizedW = w;
              double normalizedH = h;

              // Check if inputs might be in input size coordinates (0-640)
              if (x > 1.0 || y > 1.0 || w > 1.0 || h > 1.0) {
                if (x <= inputSize &&
                    y <= inputSize &&
                    w <= inputSize &&
                    h <= inputSize) {
                  // Values are probably in input size space (0-640)
                  normalizedX = x / inputSize;
                  normalizedY = y / inputSize;
                  normalizedW = w / inputSize;
                  normalizedH = h / inputSize;
                } else if (x <= sourceWidth && y <= sourceHeight) {
                  // Values might be in source image space
                  normalizedX = x / sourceWidth;
                  normalizedY = y / sourceHeight;
                  normalizedW = w / sourceWidth;
                  normalizedH = h / sourceHeight;
                } else {
                  // Values are using some other scale we don't understand
                  // Use a different approach - try to estimate the scale
                  double estimatedScale = max(
                    max(x, y) / max(sourceWidth, sourceHeight),
                    max(w, h) / max(sourceWidth, sourceHeight),
                  );
                  normalizedX = x / (estimatedScale * sourceWidth);
                  normalizedY = y / (estimatedScale * sourceHeight);
                  normalizedW = w / (estimatedScale * sourceWidth);
                  normalizedH = h / (estimatedScale * sourceHeight);
                }
              }

              // Convert normalized coordinates to pixel values on the original image
              final xmin =
                  ((normalizedX - normalizedW / 2) * sourceWidth).round();
              final ymin =
                  ((normalizedY - normalizedH / 2) * sourceHeight).round();
              final xmax =
                  ((normalizedX + normalizedW / 2) * sourceWidth).round();
              final ymax =
                  ((normalizedY + normalizedH / 2) * sourceHeight).round();

              // Clamp values to ensure they're within image boundaries
              final finalXmin = xmin.clamp(0, sourceWidth - 1);
              final finalYmin = ymin.clamp(0, sourceHeight - 1);
              final finalXmax = xmax.clamp(0, sourceWidth - 1);
              final finalYmax = ymax.clamp(0, sourceHeight - 1);

              detections.add({
                'bbox': [finalXmin, finalYmin, finalXmax, finalYmax],
                'confidence': maxConfidence,
                'class': classId,
                'label': label,
              });
            }
          } catch (e) {
            log('Error processing detection $i: $e');
          }
        }
      }
    } catch (e) {
      log('Error processing detections: $e');
    }

    // Apply non-maximum suppression
    final filteredDetections = _nonMaxSuppression(detections, iouThreshold);
    log('After NMS: ${filteredDetections.length} detections remaining');

    return filteredDetections;
  }

  List<Map<String, dynamic>> _nonMaxSuppression(
      List<Map<String, dynamic>> detections, double iouThreshold) {
    // Sort by confidence
    detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));

    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i < detections.length; i++) {
      bool shouldKeep = true;

      for (final kept in result) {
        final iou = _calculateIoU(
          List<int>.from(detections[i]['bbox']), // Explicitly cast to List<int>
          List<int>.from(kept['bbox']), // Explicitly cast to List<int>
        );

        if (iou > iouThreshold) {
          shouldKeep = false;
          break;
        }
      }

      if (shouldKeep) {
        result.add(detections[i]);
      }
    }

    return result;
  }

  double _calculateIoU(List<int> box1, List<int> box2) {
    // Calculate intersection area
    final int xmin = max(box1[0], box2[0]);
    final int ymin = max(box1[1], box2[1]);
    final int xmax = min(box1[2], box2[2]);
    final int ymax = min(box1[3], box2[3]);

    if (xmin >= xmax || ymin >= ymax) return 0.0;

    final intersectionArea = (xmax - xmin) * (ymax - ymin);

    // Calculate union area
    final box1Area = (box1[2] - box1[0]) * (box1[3] - box1[1]);
    final box2Area = (box2[2] - box2[0]) * (box2[3] - box2[1]);

    final unionArea = box1Area + box2Area - intersectionArea;

    return intersectionArea / unionArea;
  }

  // Create a widget to display camera preview with bounding boxes
  Widget _buildIntervalCaptureView() {
    if (!_isCameraInitialized || cameraController == null) {
      return const Center(
        child: Text('Camera initializing...'),
      );
    }

    return Stack(
      children: [
        // Camera preview
        CameraPreview(cameraController!),

        // Last captured image with bounding boxes (overlay)
        if (_imageFile != null)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1),
              child: IntervalDetectionView(
                key: UniqueKey(),
                // ใช้ UniqueKey เพื่อบังคับให้สร้างใหม่ทุกครั้ง
                imageFile: _imageFile!,
                imageHeight: imageHeight ?? 1,
                imageWidth: imageWidth ?? 1,
                recognitions: _recognitions,
              ),
            ),
          ),

        // Interval capture info
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Captures: $_captureCount',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Interval: ${_captureInterval}s',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Objects: ${_recognitions.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        // Processing indicator
        if (_isProcessing || _isCapturing)
          const Positioned(
            bottom: 20,
            left: 20,
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainTemplate(
      appBarTitle: 'object detection'.tr,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _isLoading
                  ? const CustomLoading()
                  : _isIntervalMode
                      ? _buildIntervalCaptureView()
                      : _imageFile == null
                          ? InkWell(
                              onTap: _isLoading
                                  ? null
                                  : () async {
                                      // Show options: Camera interval, Camera photo, Gallery
                                      final choice = await showDialog<String>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return SimpleDialog(
                                            title: TextFontStyle(
                                              'upload photo'.tr,
                                              size: fontSizeXL,
                                            ),
                                            children: <Widget>[
                                              SimpleDialogOption(
                                                onPressed: () {
                                                  Navigator.pop(
                                                      context, 'interval');
                                                },
                                                child: TextFontStyle(
                                                  'real time'.tr,
                                                  size: fontSizeL,
                                                ),
                                              ),
                                              SimpleDialogOption(
                                                onPressed: () {
                                                  Navigator.pop(
                                                      context, 'camera');
                                                },
                                                child: TextFontStyle(
                                                  'camera'.tr,
                                                  size: fontSizeL,
                                                ),
                                              ),
                                              SimpleDialogOption(
                                                onPressed: () {
                                                  Navigator.pop(
                                                      context, 'gallery');
                                                },
                                                child: TextFontStyle(
                                                  'gallery'.tr,
                                                  size: fontSizeL,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (choice == 'interval') {
                                        _startIntervalCapture();
                                      } else if (choice == 'camera' ||
                                          choice == 'gallery') {
                                        final source = choice == 'camera'
                                            ? ImageSource.camera
                                            : ImageSource.gallery;
                                        final imagePicker = ImagePicker();
                                        final pickedFile = await imagePicker
                                            .pickImage(source: source);
                                        if (pickedFile != null) {
                                          _getImage(pickedFile);
                                        }
                                      }
                                    },
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/gallery_icon.svg',
                                      color: primaryColor,
                                      height: 100.0,
                                    ),
                                    const SizedBox(height: margin),
                                    TextFontStyle(
                                      'upload photo'.tr,
                                      size: fontSizeXL,
                                      color: primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ObjectDetectionView(
                              imageFile: _imageFile!,
                              imageHeight: imageHeight!,
                              imageWidth: imageWidth!,
                              recognitions: _recognitions,
                            ),
            ),

            // Detection results (only show in image mode, not in interval mode)
            if (_recognitions.isNotEmpty && !_isIntervalMode)
              Container(
                height: 200.0,
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: _recognitions.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final recognition = _recognitions[index];
                    return ListTile(
                      dense: true,
                      title: TextFontStyle(
                        '${recognition['label']}',
                        size: fontSizeM,
                        weight: FontWeight.bold,
                      ),
                      subtitle: TextFontStyle(
                          'Confidence: ${(recognition['confidence'] * 100).toStringAsFixed(1)}%'),
                      leading: Container(
                        width: 50.0,
                        height: 50.0,
                        color: Colors.primaries[
                            recognition['class'] % Colors.primaries.length],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      // floatingActionButton: Stack(
      //   children: [
      //     // Show back button when in interval mode to exit
      //     if (_isIntervalMode)
      //       Positioned(
      //         bottom: 16,
      //         right: 16,
      //         child: FloatingActionButton(
      //           heroTag: 'backButton',
      //           onPressed: _stopIntervalCapture,
      //           backgroundColor: Colors.red,
      //           child: const Icon(Icons.stop),
      //         ),
      //       ),
      //
      //     // Adjust interval button
      //     if (_isIntervalMode)
      //       Positioned(
      //         bottom: 16,
      //         right: 80,
      //         child: FloatingActionButton(
      //           heroTag: 'adjustIntervalButton',
      //           onPressed: () async {
      //             // Show dialog to adjust interval
      //             final newInterval = await showDialog<int>(
      //               context: context,
      //               builder: (BuildContext context) {
      //                 return SimpleDialog(
      //                   title: Text('Adjust Capture Interval'.tr),
      //                   children: <Widget>[
      //                     for (int interval = 1; interval <= 5; interval++)
      //                       SimpleDialogOption(
      //                         onPressed: () {
      //                           Navigator.pop(context, interval);
      //                         },
      //                         child: Text('$interval seconds'),
      //                       ),
      //                   ],
      //                 );
      //               },
      //             );
      //
      //             if (newInterval != null) {
      //               setState(() {
      //                 _captureInterval = newInterval;
      //               });
      //
      //               // Reset the timer with new interval
      //               _captureTimer?.cancel();
      //               _captureTimer = Timer.periodic(Duration(seconds: _captureInterval), (timer) {
      //                 _captureAndDetect();
      //               });
      //             }
      //           },
      //           backgroundColor: Colors.blue,
      //           child: const Icon(Icons.timer),
      //         ),
      //       ),
      //
      //     // Manual capture button in interval mode
      //     if (_isIntervalMode)
      //       Positioned(
      //         bottom: 16,
      //         right: 144,
      //         child: FloatingActionButton(
      //           heroTag: 'manualCaptureButton',
      //           onPressed: _isCapturing || _isProcessing
      //               ? null
      //               : () {
      //             _captureAndDetect();
      //           },
      //           backgroundColor: Colors.green,
      //           child: const Icon(Icons.camera),
      //         ),
      //       ),
      //
      //     // Show image picker button when not in interval mode and have an image
      //     if (!_isIntervalMode && _imageFile != null)
      //       Positioned(
      //         bottom: 16,
      //         right: 16,
      //         child: FloatingActionButton(
      //           heroTag: 'changeImageButton',
      //           onPressed: _isLoading
      //               ? null
      //               : () async {
      //             final choice = await showDialog<String>(
      //               context: context,
      //               builder: (BuildContext context) {
      //                 return SimpleDialog(
      //                   title: Text('Select source'.tr),
      //                   children: <Widget>[
      //                     SimpleDialogOption(
      //                       onPressed: () {
      //                         Navigator.pop(context, 'interval');
      //                       },
      //                       child: Text('Camera interval capture (1s)'.tr),
      //                     ),
      //                     SimpleDialogOption(
      //                       onPressed: () {
      //                         Navigator.pop(context, 'camera');
      //                       },
      //                       child: Text('Take photo'.tr),
      //                     ),
      //                     SimpleDialogOption(
      //                       onPressed: () {
      //                         Navigator.pop(context, 'gallery');
      //                       },
      //                       child: Text('Gallery'.tr),
      //                     ),
      //                   ],
      //                 );
      //               },
      //             );
      //
      //             if (choice == 'interval') {
      //               _startIntervalCapture();
      //             } else if (choice == 'camera' || choice == 'gallery') {
      //               final source = choice == 'camera'
      //                   ? ImageSource.camera
      //                   : ImageSource.gallery;
      //               final imagePicker = ImagePicker();
      //               final pickedFile = await imagePicker.pickImage(source: source);
      //               if (pickedFile != null) {
      //                 _getImage(pickedFile);
      //               }
      //             }
      //           },
      //           backgroundColor: primaryColor,
      //           child: SvgPicture.asset(
      //             'assets/icons/gallery_icon.svg',
      //             color: Colors.white,
      //             height: 28.0,
      //           ),
      //         ),
      //       ),
      //   ],
      // ),
    );
  }

  @override
  void dispose() {
    // ล้างตัวจับเวลา
    _captureTimer?.cancel();
    _captureTimer = null;

    // หยุดกล้อง
    cameraController?.stopImageStream();
    cameraController?.dispose();
    cameraController = null;

    // ปิดตัวแปลโมเดล
    _interpreter.close();

    // ลบไฟล์รูปภาพทั้งหมด
    for (final file in _capturedImageFiles) {
      file.exists().then((exists) {
        if (exists) {
          file.delete().catchError((e) {
            log('Error deleting image file: $e');
          });
        }
      });
    }

    // ล้างรายการรูปภาพ
    _capturedImageFiles.clear();
    _recognitions.clear();
    _imageFile = null;

    super.dispose();
  }
}

// Widget for displaying captured image with detections in interval mode
class IntervalDetectionView extends StatelessWidget {
  final File imageFile;
  final int imageHeight;
  final int imageWidth;
  final List<Map<String, dynamic>> recognitions;

  const IntervalDetectionView({
    super.key,
    required this.imageFile,
    required this.imageHeight,
    required this.imageWidth,
    required this.recognitions,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      // ตรวจสอบการมีอยู่ของไฟล์ก่อนแสดงผล
      future: imageFile.exists(),
      builder: (context, snapshot) {
        // ถ้าไฟล์ไม่มีอยู่หรือยังเช็คไม่เสร็จ ไม่ต้องแสดงอะไร
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data != true) {
          return const SizedBox.shrink();
        }

        // ถ้าไฟล์มีอยู่ แสดงรูปภาพพร้อมกล่องขอบเขต
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.file(
                imageFile,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  // หากเกิดข้อผิดพลาดในการโหลดรูป ให้แสดงข้อความแทน
                  log('Error loading image: $error');
                  return const Center(
                    child: Text('Image unavailable',
                        style: TextStyle(color: Colors.white)),
                  );
                },
              ),

              // Bounding boxes - แสดงเฉพาะเมื่อมีการตรวจจับ
              if (recognitions.isNotEmpty)
                CustomPaint(
                  size: Size(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height),
                  painter: BoundingBoxPainter(
                    recognitions: recognitions,
                    imageWidth: imageWidth.toDouble(),
                    imageHeight: imageHeight.toDouble(),
                    screenWidth: MediaQuery.of(context).size.width,
                    screenHeight: MediaQuery.of(context).size.width *
                        imageHeight /
                        imageWidth,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Custom painter for drawing bounding boxes
class BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;
  final double imageWidth;
  final double imageHeight;
  final double screenWidth;
  final double screenHeight;

  BoundingBoxPainter({
    required this.recognitions,
    required this.imageWidth,
    required this.imageHeight,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scaling factors
    final double scaleX = screenWidth / imageWidth;
    final double scaleY = screenHeight / imageHeight;

    for (final recognition in recognitions) {
      // Get bbox coordinates
      final List<int> bbox = List<int>.from(recognition['bbox']);
      final int classId = recognition['class'] as int;
      final double confidence = recognition['confidence'] as double;
      final String label = recognition['label'] as String;

      // Select color based on class
      final Color boxColor =
          Colors.primaries[classId % Colors.primaries.length];

      // Scale bbox to screen size
      final double left = bbox[0] * scaleX;
      final double top = bbox[1] * scaleY;
      final double right = bbox[2] * scaleX;
      final double bottom = bbox[3] * scaleY;

      // Create bounding box paint
      final Paint boxPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Draw bounding box
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        boxPaint,
      );

      // Create text paint for label
      final TextSpan textSpan = TextSpan(
        text: '$label ${(confidence * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          backgroundColor: boxColor.withOpacity(0.8),
        ),
      );

      final TextPainter textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Draw text label at top of bounding box
      textPainter.paint(
        canvas,
        Offset(left, top > 10 ? top - textPainter.height : top),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

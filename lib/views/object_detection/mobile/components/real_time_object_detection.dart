import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/views/object_detection/mobile/components/object_detection_view.dart';
import 'package:seeable/widgets/custom_loading.dart';
import 'package:seeable/widgets/main_template.dart';
import 'package:seeable/widgets/select_camera_gallery_bottomsheet.dart';
import 'package:seeable/widgets/text_font_style.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class RealtimeObjectDetectionPage extends StatefulWidget {
  const RealtimeObjectDetectionPage({super.key});

  @override
  State<RealtimeObjectDetectionPage> createState() => _RealtimeObjectDetectionPageState();
}

class _RealtimeObjectDetectionPageState extends State<RealtimeObjectDetectionPage> {
  File? _imageFile;
  int? imageHeight;
  int? imageWidth;
  bool _isLoading = false;
  late Interpreter _interpreter;
  late List<String> _labels;
  List<Map<String, dynamic>> _recognitions = [];

  // Camera related variables
  List<CameraDescription>? cameras;
  CameraController? cameraController;
  bool _isCameraInitialized = false;
  bool _isStreamMode = false;
  bool _isProcessingFrame = false;
  int _processingTime = 0;
  int _framesPerSecond = 0;
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();

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
          imageFormatGroup: ImageFormatGroup.yuv420,
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

  Future<void> _getImage(XFile? pickedFile) async {
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

  Future<void> _runObjectDetection() async {
    if (_imageFile == null) return;

    try {
      // Read and decode image
      final imageData = await _imageFile!.readAsBytes();
      final image = img.decodeImage(imageData);
      if (image == null) {
        log('Failed to decode image');
        return;
      }

      // Store original dimensions
      imageHeight = image.height;
      imageWidth = image.width;
      log('Original image dimensions: ${imageWidth}x${imageHeight}');

      // Get model shapes
      final inputShape = _interpreter.getInputTensor(0).shape;
      final outputShape = _interpreter.getOutputTensor(0).shape;
      log('Model input shape: $inputShape');
      log('Model output shape: $outputShape');

      // Resize image to model input size
      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.cubic,
      );
      log('Resized to: ${resizedImage.width}x${resizedImage.height}');

      // Determine input format (NCHW or NHWC) and prepare input
      List<List<List<List<double>>>> inputData;
      if (inputShape.length == 4 && inputShape[1] == 3) {
        // NCHW format [batch, channels, height, width]
        log('Using NCHW input format');
        inputData = _prepareInputNCHW(resizedImage);
      } else {
        // NHWC format [batch, height, width, channels]
        log('Using NHWC input format');
        inputData = _prepareInputNHWC(resizedImage);
      }

      // Create output container based on shape
      List<dynamic> outputData = [];

      if (outputShape.length == 3) {
        if (outputShape[1] == 84) {
          // Format [1, 84, 8400]
          log('Output format: [1, 84, 8400]');
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
          log('Output format: [1, 8400, 84]');
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
          return;
        }
      } else {
        log('Unsupported output shape: $outputShape');
        return;
      }

      // Run inference
      log('Running inference...');
      _interpreter.run(inputData, outputData);

      // For debugging: log a sample of the raw output
      if (outputShape[1] == 84) {
        log('Sample output [0][0][0]: ${outputData[0][0][0]}');
        log('Sample output [0][1][0]: ${outputData[0][1][0]}');
        log('Sample output [0][2][0]: ${outputData[0][2][0]}');
        log('Sample output [0][3][0]: ${outputData[0][3][0]}');
      } else if (outputShape[2] == 84) {
        log('Sample output [0][0][0]: ${outputData[0][0][0]}');
        log('Sample output [0][0][1]: ${outputData[0][0][1]}');
        log('Sample output [0][0][2]: ${outputData[0][0][2]}');
        log('Sample output [0][0][3]: ${outputData[0][0][3]}');
      }

      // Process results
      final results =
      _processOutputs(outputData, outputShape, imageWidth!, imageHeight!);

      // Apply scaling factor if the detection was performed on a resized image
      final List<Map<String, dynamic>> scaledResults = results.map((detection) {
        final List<int> bbox = List<int>.from(detection['bbox']);

        // Log the original bounding box
        log('Original bbox: $bbox');

        return {
          'bbox': bbox,
          'confidence': detection['confidence'],
          'class': detection['class'],
          'label': detection['label'],
        };
      }).toList();

      setState(() {
        _recognitions = scaledResults;
        log('Found ${_recognitions.length} objects');
        // Debug output for the first detection
        if (_recognitions.isNotEmpty) {
          log('First detection: ${_recognitions[0]}');
        }
      });
    } catch (e) {
      log('Error running object detection: $e');
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

            // Log some samples for debugging
            if (i < 3 && maxConfidence > confidenceThreshold) {
              log('Sample detection $i: x=$x, y=$y, w=$w, h=$h, conf=$maxConfidence, class=$classId');
            }

            // Filter by confidence threshold
            if (maxConfidence > confidenceThreshold) {
              final label =
              classId < _labels.length ? _labels[classId] : 'Unknown';

              // Skip unknown labels
              if (label == 'Unknown') {
                log('Skipping Unknown label detection');
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
                  log('Normalizing from input size space: $x,$y,$w,$h -> $normalizedX,$normalizedY,$normalizedW,$normalizedH');
                } else if (x <= sourceWidth && y <= sourceHeight) {
                  // Values might be in source image space
                  normalizedX = x / sourceWidth;
                  normalizedY = y / sourceHeight;
                  normalizedW = w / sourceWidth;
                  normalizedH = h / sourceHeight;
                  log('Normalizing from source image space');
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
                  log('Using estimated scale normalization: $estimatedScale');
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

              // Log the bbox conversion for the first few detections
              if (i < 3) {
                log('BBox conversion: [$normalizedX, $normalizedY, $normalizedW, $normalizedH] -> [$finalXmin, $finalYmin, $finalXmax, $finalYmax]');
              }

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

            // Log some samples for debugging
            if (i < 3 && maxConfidence > confidenceThreshold) {
              log('Sample detection $i: x=$x, y=$y, w=$w, h=$h, conf=$maxConfidence, class=$classId');
            }

            // Filter by confidence threshold
            if (maxConfidence > confidenceThreshold) {
              final label =
              classId < _labels.length ? _labels[classId] : 'Unknown';

              // Skip unknown labels
              if (label == 'Unknown') {
                log('Skipping Unknown label detection');
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
                  log('Normalizing from input size space: $x,$y,$w,$h -> $normalizedX,$normalizedY,$normalizedW,$normalizedH');
                } else if (x <= sourceWidth && y <= sourceHeight) {
                  // Values might be in source image space
                  normalizedX = x / sourceWidth;
                  normalizedY = y / sourceHeight;
                  normalizedW = w / sourceWidth;
                  normalizedH = h / sourceHeight;
                  log('Normalizing from source image space');
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
                  log('Using estimated scale normalization: $estimatedScale');
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

              // Log the bbox conversion for the first few detections
              if (i < 3) {
                log('BBox conversion: [$normalizedX, $normalizedY, $normalizedW, $normalizedH] -> [$finalXmin, $finalYmin, $finalXmax, $finalYmax]');
              }

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
                  : _imageFile == null
                  ? InkWell(
                onTap: _isLoading
                    ? null
                    : () async {
                  XFile? result = await Get.bottomSheet(
                      const SelectCameraGalleryBottomSheet());

                  if (result != null) {
                    _getImage(result);
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

            // Detection results
            if (_recognitions.isNotEmpty)
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
      floatingActionButton: Visibility(
        visible: _imageFile != null,
        child: FloatingActionButton(
          onPressed: _isLoading
              ? null
              : () async {
            XFile? result = await Get.bottomSheet(
                const SelectCameraGalleryBottomSheet());

            if (result != null) {
              _getImage(result);
            }
          },
          backgroundColor: primaryColor,
          child: SvgPicture.asset(
            'assets/icons/gallery_icon.svg',
            color: Colors.white,
            height: 28.0,
          ),
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

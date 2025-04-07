import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// A simpler, more direct implementation for object detection visualization
class ObjectDetectionView extends StatelessWidget {
  final File imageFile;
  final int imageHeight;
  final int imageWidth;
  final List<Map<String, dynamic>> recognitions;
  final double confidence;

  const ObjectDetectionView({
    super.key,
    required this.imageFile,
    required this.imageHeight,
    required this.imageWidth,
    required this.recognitions,
    this.confidence = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      // fit: StackFit.expand,
      children: [
        // Image layer
        Image.file(
          imageFile,
          fit: BoxFit.contain,
        ),

        // // Overlay layer for bounding boxes
        // CustomPaint(
        //   painter: SimpleBoxPainter(
        //     recognitions: recognitions,
        //     confidence: confidence,
        //     imageHeight: imageHeight,
        //     imageWidth: imageWidth,
        //   ),
        // ),

        ...recognitions.map((recognition) {
          final List<int> bbox = List<int>.from(recognition['bbox']);
          final String label = recognition['label'] as String;
          final double score = recognition['confidence'] as double;
          final int classId = recognition['class'] as int;

          final color = Colors.primaries[classId % Colors.primaries.length];

          final double scaleX = Get.width / imageWidth;
          final double scaleY = Get.height / imageHeight;

          final double left = bbox[0] * scaleX;
          final double top = bbox[1] * scaleY;
          final double right = bbox[2] * scaleX;
          final double bottom = bbox[3] * scaleY;

          return Positioned(
            left: 0,
            top: 0,
            width: 100,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$label ${(score * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  backgroundColor: color,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class SimpleBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;
  final double confidence;
  final int imageHeight;
  final int imageWidth;

  SimpleBoxPainter({
    required this.recognitions,
    this.confidence = 0.5,
    required this.imageHeight,
    required this.imageWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final recognition in recognitions) {
      try {
        // Skip if confidence is too low
        if ((recognition['confidence'] as double) < confidence) continue;

        // Get basic info
        final List<int> bbox = List<int>.from(recognition['bbox']);
        final String label = recognition['label'] as String;
        final double score = recognition['confidence'] as double;
        final int classId = recognition['class'] as int;

        // // Calculate position on screen
        // final double displayRatio =
        //     size.width / 1000; // Adjust this ratio as needed

        final double scaleX = size.width / imageWidth;
        final double scaleY = size.height / imageHeight;

        // final double left = bbox[0] * displayRatio;
        // final double top = bbox[1] * displayRatio;
        // final double right = bbox[2] * displayRatio;
        // final double bottom = bbox[3] * displayRatio;

        final double left = bbox[0] * scaleX;
        final double top = bbox[1] * scaleY;
        final double right = bbox[2] * scaleX;
        final double bottom = bbox[3] * scaleY;

        // Box color based on class
        final color = Colors.primaries[classId % Colors.primaries.length];

        // Box styles
        final boxPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;

        // Draw the box
        canvas.drawRect(
          Rect.fromLTRB(left, top, right, bottom),
          boxPaint,
        );

        // Background for label
        final bgPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        // Text style
        const textStyle = TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        );

        // Draw label text
        final textSpan = TextSpan(
          text: '$label ${(score * 100).toStringAsFixed(0)}%',
          style: textStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        // Draw label background
        canvas.drawRect(
          Rect.fromLTWH(left, top - 28, textPainter.width + 10, 28),
          bgPaint,
        );

        // Draw text
        textPainter.paint(canvas, Offset(left + 5, top - 25));
      } catch (e) {
        print('Error drawing box: $e');
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class YoloDetectionPage extends StatefulWidget {
  const YoloDetectionPage({super.key});

  @override
  State<YoloDetectionPage> createState() => _YoloDetectionPageState();
}

class _YoloDetectionPageState extends State<YoloDetectionPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  int? imageHeight;
  int? imageWidth;
  bool _isLoading = false;
  late Interpreter _interpreter;
  late List<String> _labels;
  List<Map<String, dynamic>> _recognitions = [];

  final int inputSize = 640;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      // Load YOLOv8n model
      _interpreter = await Interpreter.fromAsset('assets/model/yolov8n.tflite');

      // Debug info
      print('Input Shape: ${_interpreter.getInputTensor(0).shape}');
      print('Output Shape: ${_interpreter.getOutputTensor(0).shape}');

      // Load labels
      final labelsData =
      await rootBundle.loadString('assets/model/yolov8n.txt');
      _labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();
      print('Model loaded with ${_labels.length} labels');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _getImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _recognitions = [];
    });

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _runObjectDetection();
      }
    } catch (e) {
      print('Error picking image: $e');
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
      imageHeight = image?.height;
      imageWidth = image?.width;
      if (image == null) return;

      // Get model shapes
      final inputShape = _interpreter.getInputTensor(0).shape;
      final outputShape = _interpreter.getOutputTensor(0).shape;

      // Resize image to model input size
      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.cubic,
      );

      // Prepare input data - determine if NCHW or NHWC
      List<List<List<List<double>>>> inputData;
      if (inputShape.length == 4 && inputShape[1] == 3) {
        // NCHW format [batch, channels, height, width]
        inputData = _prepareInputNCHW(resizedImage);
      } else {
        // NHWC format [batch, height, width, channels]
        inputData = _prepareInputNHWC(resizedImage);
      }

      // Create output container based on shape
      List<dynamic> outputData = [];

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
          print('Unsupported output shape: $outputShape');
          return;
        }
      } else {
        print('Unsupported output shape: $outputShape');
        return;
      }

      // Run inference
      _interpreter.run(inputData, outputData);

      // Process results
      final results =
      _processOutputs(outputData, outputShape, image.width, image.height);
      setState(() {
        _recognitions = results;
        print('Found ${_recognitions.length} objects');
        // Debug output for the first detection
        if (_recognitions.isNotEmpty) {
          print('First detection: ${_recognitions[0]}');
        }
      });
    } catch (e) {
      print('Error running object detection: $e');
      print(e.toString());
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
        final numClasses = outputShape[1] - 4;
        final numBoxes = outputShape[2];

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

            for (int c = 0; c < numClasses && c < 80; c++) {
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

              // Convert normalized coordinates to actual pixel values
              final xmin = ((x - w / 2) * sourceWidth).round();
              final ymin = ((y - h / 2) * sourceHeight).round();
              final xmax = ((x + w / 2) * sourceWidth).round();
              final ymax = ((y + h / 2) * sourceHeight).round();

              detections.add({
                'bbox': [xmin, ymin, xmax, ymax],
                'confidence': maxConfidence,
                'class': classId,
                'label': label,
              });
            }
          } catch (e) {
            print('Error processing detection $i: $e');
          }
        }
      }
      // Option 2: Box-first output (shape [1, 8400, 84])
      else if (outputShape.length == 3 && outputShape[2] == 84) {
        final numBoxes = outputShape[1];
        final numClasses = min(outputShape[2] - 4, 80); // Cap at 80 classes

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

              // Convert normalized coordinates to actual pixel values
              final xmin = ((x - w / 2) * sourceWidth).round();
              final ymin = ((y - h / 2) * sourceHeight).round();
              final xmax = ((x + w / 2) * sourceWidth).round();
              final ymax = ((y + h / 2) * sourceHeight).round();

              detections.add({
                'bbox': [xmin, ymin, xmax, ymax],
                'confidence': maxConfidence,
                'class': classId,
                'label': label,
              });
            }
          } catch (e) {
            print('Error processing detection $i: $e');
          }
        }
      }
    } catch (e) {
      print('Error processing detections: $e');
    }

    // Apply non-maximum suppression
    final filteredDetections = _nonMaxSuppression(detections, iouThreshold);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Detection'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _imageFile == null
                  ? const Center(
                  child: Text(
                      'No image selected. Please select an image.'))
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
                padding: const EdgeInsets.all(8),
                height: 120,
                child: ListView.builder(
                  itemCount: _recognitions.length,
                  itemBuilder: (context, index) {
                    final recognition = _recognitions[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        '${recognition['label']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                          'Confidence: ${(recognition['confidence'] * 100).toStringAsFixed(1)}%'),
                      leading: Container(
                        width: 50,
                        height: 50,
                        color: Colors.primaries[
                        recognition['class'] % Colors.primaries.length],
                      ),
                    );
                  },
                ),
              ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                    _isLoading ? null : () => _getImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _getImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
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

// A direct, simplified box painter that doesn't attempt async operations
class DirectBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;

  DirectBoxPainter({required this.recognitions});

  @override
  void paint(Canvas canvas, Size size) {
    for (final recognition in recognitions) {
      try {
        // Get detection data
        final List<int> bbox = List<int>.from(recognition['bbox']);
        final String label = recognition['label'] as String;
        final double confidence = recognition['confidence'] as double;
        final int classId = recognition['class'] as int;

        // Find appropriate scale for the image
        final double scaleX =
            size.width / 1000; // Adjust this based on your image
        final double scaleY =
            size.height / 1000; // Adjust this based on your image
        final double scale = min(scaleX, scaleY);

        // Determine display coordinates
        final double left = bbox[0] * scale;
        final double top = bbox[1] * scale;
        final double right = bbox[2] * scale;
        final double bottom = bbox[3] * scale;

        // Colors and styles
        final Color boxColor =
        Colors.primaries[classId % Colors.primaries.length];

        // Draw the bounding box
        final boxPaint = Paint()
          ..color = boxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

        canvas.drawRect(
          Rect.fromLTRB(left, top, right, bottom),
          boxPaint,
        );

        // Draw the label background
        final labelBgPaint = Paint()
          ..color = boxColor
          ..style = PaintingStyle.fill;

        // Draw the text label
        final textSpan = TextSpan(
          text: '$label ${(confidence * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        // Draw label background
        canvas.drawRect(
          Rect.fromLTWH(left, top - 25, textPainter.width + 8, 25),
          labelBgPaint,
        );

        // Draw label text
        textPainter.paint(canvas, Offset(left + 4, top - 23));
      } catch (e) {
        print('Error drawing box: $e');
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
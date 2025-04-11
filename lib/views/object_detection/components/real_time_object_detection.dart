// import 'package:flutter/material.dart';
//
// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/services.dart';
// import 'package:camera/camera.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
//
// class CameraDetectionPage extends StatefulWidget {
//   const CameraDetectionPage({super.key});
//
//   @override
//   State<CameraDetectionPage> createState() => _CameraDetectionPageState();
// }
//
// class _CameraDetectionPageState extends State<CameraDetectionPage> with WidgetsBindingObserver {
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;
//
//   bool _isDetecting = false;
//   bool _isInitialized = false;
//   late Interpreter _interpreter;
//   late List<String> _labels;
//   List<Map<String, dynamic>> _recognitions = [];
//
//   // Detection parameters
//   final int inputSize = 640;
//   final double confidenceThreshold = 0.5;
//
//   // Processing frame rate control
//   DateTime? _lastProcessingTime;
//   final int _processingDelayMs = 500; // Process frames every 500ms
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeCamera();
//     _loadModel();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // Handle app lifecycle state changes
//     final CameraController? cameraController = _cameraController;
//
//     if (cameraController == null || !cameraController.value.isInitialized) {
//       return;
//     }
//
//     if (state == AppLifecycleState.inactive) {
//       cameraController.dispose();
//     } else if (state == AppLifecycleState.resumed) {
//       _initializeCamera();
//     }
//   }
//
//   Future<void> _initializeCamera() async {
//     try {
//       _cameras = await availableCameras();
//       if (_cameras!.isEmpty) {
//         print('No cameras available');
//         return;
//       }
//
//       // Use the first camera (usually back camera)
//       final CameraDescription camera = _cameras!.first;
//
//       _cameraController = CameraController(
//         camera,
//         ResolutionPreset.medium, // Balance between quality and performance
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.yuv420,
//       );
//
//       await _cameraController!.initialize();
//
//       // Start image stream for detection
//       await _cameraController!.startImageStream(_processCameraImage);
//
//       if (mounted) {
//         setState(() {
//           _isInitialized = true;
//         });
//       }
//     } catch (e) {
//       print('Error initializing camera: $e');
//     }
//   }
//
//   Future<void> _loadModel() async {
//     try {
//       // Load YOLOv8n model
//       _interpreter = await Interpreter.fromAsset('assets/yolov8_small/yolov8n.tflite');
//
//       // Debug info
//       print('Input Shape: ${_interpreter.getInputTensor(0).shape}');
//       print('Output Shape: ${_interpreter.getOutputTensor(0).shape}');
//
//       // Load labels
//       final labelsData = await rootBundle.loadString('assets/yolov8_small/yolov8n.txt');
//       _labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();
//       print('Model loaded with ${_labels.length} labels');
//     } catch (e) {
//       print('Error loading model: $e');
//     }
//   }
//
//   void _processCameraImage(CameraImage cameraImage) async {
//     // Skip if already processing an image or too soon since last processing
//     if (_isDetecting) return;
//
//     final now = DateTime.now();
//     if (_lastProcessingTime != null &&
//         now.difference(_lastProcessingTime!).inMilliseconds < _processingDelayMs) {
//       return;
//     }
//     _lastProcessingTime = now;
//
//     _isDetecting = true;
//
//     try {
//       // Convert camera image to format suitable for the model
//       final img.Image? image = await _convertCameraImageToImage(cameraImage);
//       if (image == null) {
//         _isDetecting = false;
//         return;
//       }
//
//       // Get model shapes
//       final inputShape = _interpreter.getInputTensor(0).shape;
//       final outputShape = _interpreter.getOutputTensor(0).shape;
//
//       // Resize image to model input size
//       final resizedImage = img.copyResize(
//         image,
//         width: inputSize,
//         height: inputSize,
//         interpolation: img.Interpolation.cubic,
//       );
//
//       // Prepare input data - determine if NCHW or NHWC
//       List<List<List<List<double>>>> inputData;
//       if (inputShape.length == 4 && inputShape[1] == 3) {
//         // NCHW format [batch, channels, height, width]
//         inputData = _prepareInputNCHW(resizedImage);
//       } else {
//         // NHWC format [batch, height, width, channels]
//         inputData = _prepareInputNHWC(resizedImage);
//       }
//
//       // Create output container based on shape
//       List<dynamic> outputData = [];
//
//       if (outputShape.length == 3) {
//         if (outputShape[1] == 84) {
//           // Format [1, 84, 8400]
//           var output = List.generate(
//             outputShape[0],
//                 (_) => List.generate(
//               outputShape[1],
//                   (_) => List<double>.filled(outputShape[2], 0.0),
//             ),
//           );
//           outputData = output;
//         } else if (outputShape[2] == 84) {
//           // Format [1, 8400, 84]
//           var output = List.generate(
//             outputShape[0],
//                 (_) => List.generate(
//               outputShape[1],
//                   (_) => List<double>.filled(outputShape[2], 0.0),
//             ),
//           );
//           outputData = output;
//         } else {
//           print('Unsupported output shape: $outputShape');
//           _isDetecting = false;
//           return;
//         }
//       } else {
//         print('Unsupported output shape: $outputShape');
//         _isDetecting = false;
//         return;
//       }
//
//       // Run inference
//       _interpreter.run(inputData, outputData);
//
//       // Process results
//       final results = _processOutputs(outputData, outputShape, image.width, image.height);
//
//       if (mounted) {
//         setState(() {
//           _recognitions = results;
//         });
//       }
//     } catch (e) {
//       print('Error processing camera image: $e');
//     } finally {
//       _isDetecting = false;
//     }
//   }
//
//   Future<img.Image?> _convertCameraImageToImage(CameraImage cameraImage) async {
//     try {
//       // Handle YUV_420_888 format (most common for Android)
//       if (cameraImage.format.group == ImageFormatGroup.yuv420) {
//         return _convertYUV420ToImageOptimized(cameraImage);
//       }
//
//       // Handle other formats if needed
//       print('Unsupported image format: ${cameraImage.format.group}');
//       return null;
//     } catch (e) {
//       print('Error converting camera image: $e');
//       return null;
//     }
//   }
//
//   img.Image _convertYUV420ToImageOptimized(CameraImage cameraImage) {
//     // Create a new image with reduced dimensions (every 2nd pixel)
//     const scaleFactor = 2;
//     final width = cameraImage.width ~/ scaleFactor;
//     final height = cameraImage.height ~/ scaleFactor;
//
//     final image = img.Image(width: width, height: height);
//
//     // Get the planes
//     final yPlane = cameraImage.planes[0];
//     final uPlane = cameraImage.planes[1];
//     final vPlane = cameraImage.planes[2];
//
//     final yPixels = yPlane.bytes;
//     final uPixels = uPlane.bytes;
//     final vPixels = vPlane.bytes;
//
//     final yRowStride = yPlane.bytesPerRow;
//     final uRowStride = uPlane.bytesPerRow;
//     final vRowStride = vPlane.bytesPerRow;
//
//     final yPixelStride = yPlane.bytesPerPixel ?? 1;
//     final uPixelStride = uPlane.bytesPerPixel ?? 1;
//     final vPixelStride = vPlane.bytesPerPixel ?? 1;
//
//     // Fill the image with data (sampling every 2nd pixel)
//     for (int y = 0; y < height; y++) {
//       for (int x = 0; x < width; x++) {
//         final sourceX = x * scaleFactor;
//         final sourceY = y * scaleFactor;
//
//         // Get Y value
//         final yIndex = sourceY * yRowStride + sourceX * yPixelStride;
//         final yValue = yPixels[yIndex];
//
//         // Get U and V values
//         final uvX = sourceX ~/ 2;
//         final uvY = sourceY ~/ 2;
//         final uIndex = uvY * uRowStride + uvX * uPixelStride;
//         final vIndex = uvY * vRowStride + uvX * vPixelStride;
//
//         final uValue = uPixels[uIndex];
//         final vValue = vPixels[vIndex];
//
//         // Simplified YUV to RGB conversion
//         int r = (yValue + 1.370705 * (vValue - 128)).round().clamp(0, 255);
//         int g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128)).round().clamp(0, 255);
//         int b = (yValue + 1.732446 * (uValue - 128)).round().clamp(0, 255);
//
//         // Set pixel in the image
//         image.setPixelRgba(x, y, r, g, b, 255);
//       }
//     }
//
//     return image;
//   }
//
//   // Prepare input in NCHW format [batch, channels, height, width]
//   List<List<List<List<double>>>> _prepareInputNCHW(img.Image image) {
//     return List.generate(
//       1, // batch size
//           (_) => List.generate(
//         3, // channels (RGB)
//             (c) => List.generate(
//           inputSize, // height
//               (y) => List.generate(
//             inputSize, // width
//                 (x) {
//               final pixel = image.getPixel(x, y);
//               if (c == 0) return pixel.r / 255.0;  // Red channel
//               if (c == 1) return pixel.g / 255.0;  // Green channel
//               return pixel.b / 255.0;              // Blue channel
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Prepare input in NHWC format [batch, height, width, channels]
//   List<List<List<List<double>>>> _prepareInputNHWC(img.Image image) {
//     return List.generate(
//       1, // batch size
//           (_) => List.generate(
//         inputSize, // height
//             (y) => List.generate(
//           inputSize, // width
//               (x) => List.generate(
//             3, // channels (RGB)
//                 (c) {
//               final pixel = image.getPixel(x, y);
//               if (c == 0) return pixel.r / 255.0;  // Red channel
//               if (c == 1) return pixel.g / 255.0;  // Green channel
//               return pixel.b / 255.0;              // Blue channel
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   List<Map<String, dynamic>> _processOutputs(
//       List<dynamic> outputData, List<int> outputShape, int sourceWidth, int sourceHeight) {
//     const confidenceThreshold = 0.25;
//     const iouThreshold = 0.45;
//     List<Map<String, dynamic>> detections = [];
//
//     try {
//       // Option 1: Transpose-style output (shape [1, 84, 8400])
//       if (outputShape.length == 3 && outputShape[1] == 84) {
//         final numClasses = outputShape[1] - 4;
//         final numBoxes = outputShape[2];
//
//         for (int i = 0; i < numBoxes; i++) {
//           try {
//             // Get bbox coordinates
//             final x = outputData[0][0][i] as double; // Center x
//             final y = outputData[0][1][i] as double; // Center y
//             final w = outputData[0][2][i] as double; // Width
//             final h = outputData[0][3][i] as double; // Height
//
//             // Find class with highest confidence
//             double maxConfidence = 0;
//             int classId = 0;
//
//             for (int c = 0; c < numClasses && c < 80; c++) {
//               final confidence = outputData[0][4 + c][i] as double;
//               if (confidence > maxConfidence) {
//                 maxConfidence = confidence;
//                 classId = c;
//               }
//             }
//
//             // Filter by confidence threshold
//             if (maxConfidence > confidenceThreshold) {
//               final label = classId < _labels.length ? _labels[classId] : 'Unknown';
//
//               // Convert normalized coordinates to actual pixel values
//               final xmin = ((x - w / 2) * sourceWidth).round();
//               final ymin = ((y - h / 2) * sourceHeight).round();
//               final xmax = ((x + w / 2) * sourceWidth).round();
//               final ymax = ((y + h / 2) * sourceHeight).round();
//
//               detections.add({
//                 'bbox': [xmin, ymin, xmax, ymax],
//                 'confidence': maxConfidence,
//                 'class': classId,
//                 'label': label,
//               });
//             }
//           } catch (e) {
//             print('Error processing detection $i: $e');
//           }
//         }
//       }
//       // Option 2: Box-first output (shape [1, 8400, 84])
//       else if (outputShape.length == 3 && outputShape[2] == 84) {
//         final numBoxes = outputShape[1];
//         final numClasses = min(outputShape[2] - 4, 80); // Cap at 80 classes
//
//         for (int i = 0; i < numBoxes; i++) {
//           try {
//             // Get bbox coordinates
//             final x = outputData[0][i][0] as double; // Center x
//             final y = outputData[0][i][1] as double; // Center y
//             final w = outputData[0][i][2] as double; // Width
//             final h = outputData[0][i][3] as double; // Height
//
//             // Find class with highest confidence
//             double maxConfidence = 0;
//             int classId = 0;
//
//             for (int c = 0; c < numClasses; c++) {
//               final confidence = outputData[0][i][4 + c] as double;
//               if (confidence > maxConfidence) {
//                 maxConfidence = confidence;
//                 classId = c;
//               }
//             }
//
//             // Filter by confidence threshold
//             if (maxConfidence > confidenceThreshold) {
//               final label = classId < _labels.length ? _labels[classId] : 'Unknown';
//
//               // Convert normalized coordinates to actual pixel values
//               final xmin = ((x - w / 2) * sourceWidth).round();
//               final ymin = ((y - h / 2) * sourceHeight).round();
//               final xmax = ((x + w / 2) * sourceWidth).round();
//               final ymax = ((y + h / 2) * sourceHeight).round();
//
//               detections.add({
//                 'bbox': [xmin, ymin, xmax, ymax],
//                 'confidence': maxConfidence,
//                 'class': classId,
//                 'label': label,
//               });
//             }
//           } catch (e) {
//             print('Error processing detection $i: $e');
//           }
//         }
//       }
//     } catch (e) {
//       print('Error processing detections: $e');
//     }
//
//     // Apply non-maximum suppression
//     final filteredDetections = _nonMaxSuppression(detections, iouThreshold);
//
//     return filteredDetections;
//   }
//
//   List<Map<String, dynamic>> _nonMaxSuppression(List<Map<String, dynamic>> detections, double iouThreshold) {
//     // Sort by confidence
//     detections.sort((a, b) => b['confidence'].compareTo(a['confidence']));
//
//     final List<Map<String, dynamic>> result = [];
//
//     for (int i = 0; i < detections.length; i++) {
//       bool shouldKeep = true;
//
//       for (final kept in result) {
//         final iou = _calculateIoU(
//           List<int>.from(detections[i]['bbox']),  // Explicitly cast to List<int>
//           List<int>.from(kept['bbox']),           // Explicitly cast to List<int>
//         );
//
//         if (iou > iouThreshold) {
//           shouldKeep = false;
//           break;
//         }
//       }
//
//       if (shouldKeep) {
//         result.add(detections[i]);
//       }
//     }
//
//     return result;
//   }
//
//   double _calculateIoU(List<int> box1, List<int> box2) {
//     // Calculate intersection area
//     final int xmin = max(box1[0], box2[0]);
//     final int ymin = max(box1[1], box2[1]);
//     final int xmax = min(box1[2], box2[2]);
//     final int ymax = min(box1[3], box2[3]);
//
//     if (xmin >= xmax || ymin >= ymax) return 0.0;
//
//     final intersectionArea = (xmax - xmin) * (ymax - ymin);
//
//     // Calculate union area
//     final box1Area = (box1[2] - box1[0]) * (box1[3] - box1[1]);
//     final box2Area = (box2[2] - box2[0]) * (box2[3] - box2[1]);
//
//     final unionArea = box1Area + box2Area - intersectionArea;
//
//     return intersectionArea / unionArea;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_isInitialized || _cameraController == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Camera Object Detection')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Camera Object Detection'),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   // Camera preview
//                   CameraPreview(_cameraController!),
//
//                   // Draw bounding boxes
//                   CustomPaint(
//                     size: Size.infinite,
//                     painter: CameraBoxPainter(
//                       recognitions: _recognitions,
//                       previewSize: _cameraController!.value.previewSize!,
//                       screenSize: MediaQuery.of(context).size,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Detection results
//             if (_recognitions.isNotEmpty)
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 height: 120,
//                 color: Colors.black54,
//                 child: ListView.builder(
//                   itemCount: _recognitions.length,
//                   itemBuilder: (context, index) {
//                     final recognition = _recognitions[index];
//                     return ListTile(
//                       dense: true,
//                       title: Text(
//                         '${recognition['label']}',
//                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Text(
//                         'Confidence: ${(recognition['confidence'] * 100).toStringAsFixed(1)}%',
//                         style: const TextStyle(color: Colors.white70),
//                       ),
//                       leading: Container(
//                         width: 40,
//                         height: 40,
//                         color: Colors.primaries[recognition['class'] % Colors.primaries.length],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//
//             // Controls
//             Container(
//               padding: const EdgeInsets.all(16),
//               color: Colors.black87,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   Text(
//                     'Detected: ${_recognitions.length} objects',
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
//                     onPressed: _switchCamera,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _switchCamera() async {
//     if (_cameras == null || _cameras!.length < 2) {
//       // No secondary camera available
//       return;
//     }
//
//     // Get current camera index
//     final int currentCameraIndex = _cameras!.indexOf(_cameraController!.description);
//     final int newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;
//
//     // Dispose current controller
//     await _cameraController!.stopImageStream();
//     await _cameraController!.dispose();
//
//     // Initialize new camera
//     _cameraController = CameraController(
//       _cameras![newCameraIndex],
//       ResolutionPreset.medium,
//       enableAudio: false,
//       imageFormatGroup: ImageFormatGroup.yuv420,
//     );
//
//     await _cameraController!.initialize();
//     await _cameraController!.startImageStream(_processCameraImage);
//
//     if (mounted) {
//       setState(() {});
//     }
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _cameraController?.dispose();
//     _interpreter.close();
//     super.dispose();
//   }
// }
//
// // Custom painter specifically for camera view
// class CameraBoxPainter extends CustomPainter {
//   final List<Map<String, dynamic>> recognitions;
//   final Size previewSize;
//   final Size screenSize;
//
//   CameraBoxPainter({
//     required this.recognitions,
//     required this.previewSize,
//     required this.screenSize,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (recognitions.isEmpty) return;
//
//     // Calculate scale to convert from model coordinates to screen coordinates
//     final double scaleX = screenSize.width / previewSize.width;
//     final double scaleY = screenSize.height / previewSize.height;
//
//     for (final recognition in recognitions) {
//       try {
//         // Get detection data
//         final List<int> bbox = List<int>.from(recognition['bbox']);
//         final String label = recognition['label'] as String;
//         final double confidence = recognition['confidence'] as double;
//         final int classId = recognition['class'] as int;
//
//         // Scale to screen coordinates
//         final double left = bbox[0] * scaleX;
//         final double top = bbox[1] * scaleY;
//         final double right = bbox[2] * scaleX;
//         final double bottom = bbox[3] * scaleY;
//
//         // Colors and styles
//         final Color boxColor = Colors.primaries[classId % Colors.primaries.length];
//
//         // Draw the bounding box
//         final boxPaint = Paint()
//           ..color = boxColor
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 3.0;
//
//         canvas.drawRect(
//           Rect.fromLTRB(left, top, right, bottom),
//           boxPaint,
//         );
//
//         // Draw the label background
//         final labelBgPaint = Paint()
//           ..color = boxColor.withOpacity(0.8)
//           ..style = PaintingStyle.fill;
//
//         // Draw the text label
//         final textSpan = TextSpan(
//           text: '$label ${(confidence * 100).toStringAsFixed(0)}%',
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 16.0,
//             fontWeight: FontWeight.bold,
//           ),
//         );
//
//         final textPainter = TextPainter(
//           text: textSpan,
//           textDirection: TextDirection.ltr,
//         );
//
//         textPainter.layout();
//
//         // Draw label background
//         canvas.drawRect(
//           Rect.fromLTWH(left, top - 28, textPainter.width + 10, 28),
//           labelBgPaint,
//         );
//
//         // Draw label text
//         textPainter.paint(canvas, Offset(left + 5, top - 25));
//       } catch (e) {
//         print('Error drawing camera box: $e');
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(CameraBoxPainter oldDelegate) {
//     return recognitions != oldDelegate.recognitions;
//   }
// }

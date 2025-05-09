import 'dart:isolate';
import 'dart:math';
import 'package:seeable/views/object_detection/mobile/real_time_components/isolate_data.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import 'image_utils.dart';

class InferenceUtils {
  /// Calculate IoU (Intersection over Union) between two bounding boxes
  static double calculateIoU(List<int> box1, List<int> box2) {
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

    return unionArea <= 0 ? 0.0 : intersectionArea / unionArea;
  }

  /// Apply non-maximum suppression to filter out overlapping boxes
  static List<DetectionResult> nonMaxSuppression(
      List<DetectionResult> detections,
      double iouThreshold,
      ) {
    // Sort by confidence
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<DetectionResult> result = [];

    for (int i = 0; i < detections.length; i++) {
      bool shouldKeep = true;

      for (final kept in result) {
        final iou = calculateIoU(
          detections[i].bbox,
          kept.bbox,
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

  /// Process model outputs to get detection results
  static List<DetectionResult> processOutputs(
      List<dynamic> outputData,
      List<int> outputShape,
      int sourceWidth,
      int sourceHeight,
      List<String> labels,
      double confidenceThreshold,
      double iouThreshold,
      ) {
    List<DetectionResult> detections = [];

    try {
      // Limit to a maximum number of potential detections to process
      const int maxBoxesToProcess = 100;

      // Option 1: Transpose-style output (shape [1, 84, 8400])
      if (outputShape.length == 3 && outputShape[1] == 84) {
        final numClasses = min(outputShape[1] - 4, 80);
        final numBoxesToProcess = min(outputShape[2], maxBoxesToProcess);

        for (int i = 0; i < numBoxesToProcess; i++) {
          try {
            // Skip low-confidence detections at an early stage
            bool hasHighConfidence = false;
            for (int c = 0; c < numClasses; c++) {
              if (outputData[0][4 + c][i] > confidenceThreshold) {
                hasHighConfidence = true;
                break;
              }
            }

            if (!hasHighConfidence) continue;

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
              final label = classId < labels.length ? labels[classId] : 'Unknown';

              // Convert normalized coordinates to actual pixel values
              final xmin = ((x - w / 2) * sourceWidth).round();
              final ymin = ((y - h / 2) * sourceHeight).round();
              final xmax = ((x + w / 2) * sourceWidth).round();
              final ymax = ((y + h / 2) * sourceHeight).round();

              detections.add(DetectionResult(
                bbox: [xmin, ymin, xmax, ymax],
                confidence: maxConfidence,
                classId: classId,
                label: label,
              ));
            }
          } catch (e) {
            // Continue processing other detections
            continue;
          }
        }
      }
      // Option 2: Box-first output (shape [1, 8400, 84])
      else if (outputShape.length == 3 && outputShape[2] == 84) {
        final numBoxesToProcess = min(outputShape[1], maxBoxesToProcess);
        final numClasses = min(outputShape[2] - 4, 80);

        for (int i = 0; i < numBoxesToProcess; i++) {
          try {
            // Skip low-confidence detections at an early stage
            bool hasHighConfidence = false;
            for (int c = 0; c < numClasses; c++) {
              if (outputData[0][i][4 + c] > confidenceThreshold) {
                hasHighConfidence = true;
                break;
              }
            }

            if (!hasHighConfidence) continue;

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
              final label = classId < labels.length ? labels[classId] : 'Unknown';

              // Convert normalized coordinates to actual pixel values
              final xmin = ((x - w / 2) * sourceWidth).round();
              final ymin = ((y - h / 2) * sourceHeight).round();
              final xmax = ((x + w / 2) * sourceWidth).round();
              final ymax = ((y + h / 2) * sourceHeight).round();

              detections.add(DetectionResult(
                bbox: [xmin, ymin, xmax, ymax],
                confidence: maxConfidence,
                classId: classId,
                label: label,
              ));
            }
          } catch (e) {
            // Continue processing other detections
            continue;
          }
        }
      }
    } catch (e) {
      print('Error processing detections: $e');
    }

    // Limit the number of results for better performance
    if (detections.length > 10) {
      // Sort by confidence
      detections.sort((a, b) => b.confidence.compareTo(a.confidence));
      // Keep only top 10 detections
      detections = detections.sublist(0, 10);
    }

    // Apply non-maximum suppression
    final filteredDetections = nonMaxSuppression(detections, iouThreshold);

    return filteredDetections;
  }

  /// Background isolate entry point for processing images
  static void isolateEntryPoint(SendPort sendPort) {
    final ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    Interpreter? interpreter;

    receivePort.listen((message) async {
      if (message is IsolateData) {
        try {
          // Load interpreter in isolate if not loaded
          if (interpreter == null) {
            final interpreterOptions = InterpreterOptions()..threads = 4;
            interpreter = await Interpreter.fromAsset(
              'assets/yolov8_small/yolov8n.tflite',
              options: interpreterOptions,
            );
          }

          // Process image
          final img.Image? image = ImageUtils.convertYUV420ToImage(message.cameraImage);
          if (image == null) {
            message.responsePort.send(<DetectionResult>[]);
            return;
          }

          // Resize image
          final resizedImage = img.copyResize(
            image,
            width: message.inputSize,
            height: message.inputSize,
            interpolation: img.Interpolation.nearest, // Use faster interpolation
          );

          // Prepare input based on model format
          List<dynamic> inputData;
          if (message.interpreterInputShape[1] == 3) {
            // NCHW format
            inputData = ImageUtils.prepareInputNCHW(resizedImage, message.inputSize);
          } else {
            // NHWC format
            inputData = ImageUtils.prepareInputNHWC(resizedImage, message.inputSize);
          }

          // Create output container
          List<dynamic> outputData = [];

          if (message.interpreterOutputShape.length == 3) {
            if (message.interpreterOutputShape[1] == 84) {
              // Format [1, 84, 8400]
              var output = List.generate(
                message.interpreterOutputShape[0],
                    (_) => List.generate(
                  message.interpreterOutputShape[1],
                      (_) => List<double>.filled(message.interpreterOutputShape[2], 0.0),
                ),
              );
              outputData = output;
            } else if (message.interpreterOutputShape[2] == 84) {
              // Format [1, 8400, 84]
              var output = List.generate(
                message.interpreterOutputShape[0],
                    (_) => List.generate(
                  message.interpreterOutputShape[1],
                      (_) => List<double>.filled(message.interpreterOutputShape[2], 0.0),
                ),
              );
              outputData = output;
            }
          }

          // Run inference
          interpreter!.run(inputData, outputData);

          // Process detections
          final detections = processOutputs(
            outputData,
            message.interpreterOutputShape,
            image.width,
            image.height,
            message.labels,
            message.confidenceThreshold,
            message.iouThreshold,
          );

          // Send results back
          message.responsePort.send(detections);
        } catch (e) {
          print('Error in isolate: $e');
          message.responsePort.send(<DetectionResult>[]);
        }
      } else if (message == 'close') {
        // Clean up resources when isolate is closing
        interpreter?.close();
        interpreter = null;
      }
    });
  }

  /// Create output tensor for the model based on shape
  static List<dynamic> createOutputTensor(List<int> outputShape) {
    if (outputShape.length == 3) {
      if (outputShape[1] == 84) {
        // Format [1, 84, 8400]
        return List.generate(
          outputShape[0],
              (_) => List.generate(
            outputShape[1],
                (_) => List<double>.filled(outputShape[2], 0.0),
          ),
        );
      } else if (outputShape[2] == 84) {
        // Format [1, 8400, 84]
        return List.generate(
          outputShape[0],
              (_) => List.generate(
            outputShape[1],
                (_) => List<double>.filled(outputShape[2], 0.0),
          ),
        );
      }
    }

    // Fallback for unsupported shapes
    throw Exception('Unsupported output shape: $outputShape');
  }

  /// Helper method to normalize bounding box coordinates
  static List<double> normalizeBox(List<int> bbox, int imageWidth, int imageHeight) {
    return [
      bbox[0] / imageWidth,
      bbox[1] / imageHeight,
      bbox[2] / imageWidth,
      bbox[3] / imageHeight,
    ];
  }

  /// Helper method to denormalize bounding box coordinates
  static List<int> denormalizeBox(List<double> bbox, int imageWidth, int imageHeight) {
    return [
      (bbox[0] * imageWidth).round(),
      (bbox[1] * imageHeight).round(),
      (bbox[2] * imageWidth).round(),
      (bbox[3] * imageHeight).round(),
    ];
  }

  /// Convert x, y, w, h (center, dimensions) format to x1, y1, x2, y2 (corners) format
  static List<int> centerToCorners(double centerX, double centerY, double width, double height, int imageWidth, int imageHeight) {
    return [
      ((centerX - width / 2) * imageWidth).round(),
      ((centerY - height / 2) * imageHeight).round(),
      ((centerX + width / 2) * imageWidth).round(),
      ((centerY + height / 2) * imageHeight).round(),
    ];
  }

  /// Convert x1, y1, x2, y2 (corners) format to x, y, w, h (center, dimensions) format
  static List<double> cornersToCenter(List<int> box, int imageWidth, int imageHeight) {
    final width = (box[2] - box[0]) / imageWidth;
    final height = (box[3] - box[1]) / imageHeight;
    final centerX = (box[0] + box[2]) / (2 * imageWidth);
    final centerY = (box[1] + box[3]) / (2 * imageHeight);

    return [centerX, centerY, width, height];
  }

  /// Find the class with the highest confidence
  static (int, double) findBestClass(List<double> classScores, double threshold) {
    int bestClassId = 0;
    double bestConfidence = 0.0;

    for (int i = 0; i < classScores.length; i++) {
      if (classScores[i] > bestConfidence) {
        bestConfidence = classScores[i];
        bestClassId = i;
      }
    }

    return bestConfidence > threshold ? (bestClassId, bestConfidence) : (-1, 0.0);
  }

  /// Check if a detection has any class score above the threshold
  static bool hasHighConfidenceClass(List<double> classScores, double threshold) {
    for (final score in classScores) {
      if (score > threshold) return true;
    }
    return false;
  }

  /// Filter boxes by size to remove tiny or huge detections
  static bool isValidBoxSize(List<int> box, int minSize, int maxSize) {
    final width = box[2] - box[0];
    final height = box[3] - box[1];

    return width >= minSize &&
        height >= minSize &&
        width <= maxSize &&
        height <= maxSize;
  }

  /// Calculate area of a bounding box
  static int calculateBoxArea(List<int> box) {
    return (box[2] - box[0]) * (box[3] - box[1]);
  }

  /// Check if two boxes are overlapping
  static bool areBoxesOverlapping(List<int> box1, List<int> box2) {
    return !(box1[2] <= box2[0] || // box1 is to the left of box2
        box1[0] >= box2[2] || // box1 is to the right of box2
        box1[3] <= box2[1] || // box1 is above box2
        box1[1] >= box2[3]);  // box1 is below box2
  }

  /// Expand box by a scale factor
  static List<int> expandBox(List<int> box, double scale, int imageWidth, int imageHeight) {
    final centerX = (box[0] + box[2]) / 2;
    final centerY = (box[1] + box[3]) / 2;
    final width = (box[2] - box[0]) * scale;
    final height = (box[3] - box[1]) * scale;

    return [
      max(0, (centerX - width / 2).round()),
      max(0, (centerY - height / 2).round()),
      min(imageWidth, (centerX + width / 2).round()),
      min(imageHeight, (centerY + height / 2).round()),
    ];
  }

  /// Filter detections by confidence threshold and limit max number
  static List<DetectionResult> filterAndLimitDetections(
      List<DetectionResult> detections,
      double confidenceThreshold,
      int maxDetections,
      ) {
    // Filter by confidence
    final filtered = detections.where((d) => d.confidence >= confidenceThreshold).toList();

    // Sort by confidence (highest first)
    filtered.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Limit to max detections
    if (filtered.length > maxDetections) {
      return filtered.sublist(0, maxDetections);
    }

    return filtered;
  }
}
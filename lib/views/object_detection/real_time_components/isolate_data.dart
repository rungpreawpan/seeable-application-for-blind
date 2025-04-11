import 'dart:isolate';
import 'package:camera/camera.dart';

/// Data structure for passing image data to isolate
class IsolateData {
  final CameraImage cameraImage;
  final SendPort responsePort;
  final List<int> interpreterInputShape;
  final List<int> interpreterOutputShape;
  final int inputSize;
  final List<String> labels;
  final double confidenceThreshold;
  final double iouThreshold;

  IsolateData({
    required this.cameraImage,
    required this.responsePort,
    required this.interpreterInputShape,
    required this.interpreterOutputShape,
    required this.inputSize,
    required this.labels,
    required this.confidenceThreshold,
    required this.iouThreshold,
  });
}

/// Data structure for detection result
class DetectionResult {
  final List<int> bbox; // [xmin, ymin, xmax, ymax]
  final double confidence;
  final int classId;
  final String label;

  DetectionResult({
    required this.bbox,
    required this.confidence,
    required this.classId,
    required this.label,
  });

  // Factory method to create from raw detection map
  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    return DetectionResult(
      bbox: List<int>.from(map['bbox']),
      confidence: map['confidence'] as double,
      classId: map['class'] as int,
      label: map['label'] as String,
    );
  }

  // Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'bbox': bbox,
      'confidence': confidence,
      'class': classId,
      'label': label,
    };
  }
}

/// Data structure for image processing metadata
class ImageInfo {
  final int width;
  final int height;

  ImageInfo({
    required this.width,
    required this.height,
  });
}
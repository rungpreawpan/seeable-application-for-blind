import 'package:flutter/material.dart';
import 'package:seeable/views/object_detection/real_time_components/isolate_data.dart';

class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Size previewSize;
  final Size screenSize;

  // Cached paint objects to avoid recreation during painting
  final Map<int, Paint> _boxPaintCache = {};
  final Map<int, Paint> _bgPaintCache = {};
  final TextStyle _labelStyle = const TextStyle(
    color: Colors.white,
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
  );

  DetectionPainter({
    required this.detections,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    // Calculate scale to convert from model coordinates to screen coordinates
    final double scaleX = screenSize.width / previewSize.width;
    final double scaleY = screenSize.height / previewSize.height;

    for (final detection in detections) {
      try {
        // Get detection data
        final List<int> bbox = detection.bbox;
        final String label = detection.label;
        final double confidence = detection.confidence;
        final int classId = detection.classId;

        // Scale to screen coordinates
        final double left = bbox[0] * scaleX;
        final double top = bbox[1] * scaleY;
        final double right = bbox[2] * scaleX;
        final double bottom = bbox[3] * scaleY;

        // Skip if bounding box is outside the screen
        if (right < 0 || bottom < 0 || left > screenSize.width || top > screenSize.height) {
          continue;
        }

        // Get or create box paint
        final boxPaint = _boxPaintCache.putIfAbsent(
          classId,
              () => Paint()
            ..color = Colors.primaries[classId % Colors.primaries.length]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );

        // Draw the bounding box
        canvas.drawRect(
          Rect.fromLTRB(left, top, right, bottom),
          boxPaint,
        );

        // Get or create label background paint
        final labelBgPaint = _bgPaintCache.putIfAbsent(
          classId,
              () => Paint()
            ..color = Colors.primaries[classId % Colors.primaries.length].withOpacity(0.8)
            ..style = PaintingStyle.fill,
        );

        // Create the label text
        final textSpan = TextSpan(
          text: '$label ${(confidence * 100).toStringAsFixed(0)}%',
          style: _labelStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        // Draw label background (only if there's enough space)
        if (top >= 20) {
          canvas.drawRect(
            Rect.fromLTWH(left, top - 22, textPainter.width + 8, 22),
            labelBgPaint,
          );

          // Draw label text
          textPainter.paint(canvas, Offset(left + 4, top - 20));
        } else {
          // If not enough space above, draw below the box
          canvas.drawRect(
            Rect.fromLTWH(left, bottom, textPainter.width + 8, 22),
            labelBgPaint,
          );

          // Draw label text
          textPainter.paint(canvas, Offset(left + 4, bottom + 2));
        }
      } catch (e) {
        // Skip this detection and continue with others
        continue;
      }
    }
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    // Only repaint if the detections have changed
    if (oldDelegate.detections.length != detections.length) return true;

    // Compare all bounding boxes and confidence values
    for (int i = 0; i < detections.length; i++) {
      if (i >= oldDelegate.detections.length) return true;

      final oldBox = oldDelegate.detections[i].bbox;
      final newBox = detections[i].bbox;

      // Check if boxes are significantly different (more than 5 pixels)
      if ((oldBox[0] - newBox[0]).abs() > 5 ||
          (oldBox[1] - newBox[1]).abs() > 5 ||
          (oldBox[2] - newBox[2]).abs() > 5 ||
          (oldBox[3] - newBox[3]).abs() > 5) {
        return true;
      }

      // Check if class or confidence is different
      if (oldDelegate.detections[i].classId != detections[i].classId ||
          (oldDelegate.detections[i].confidence - detections[i].confidence).abs() > 0.05) {
        return true;
      }
    }

    return false;
  }
}
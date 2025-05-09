import 'dart:developer';
import 'dart:math' hide log;

import 'package:flutter/material.dart';

class CustomBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> recognitions;
  final double confidence;
  final int imageHeight;
  final int imageWidth;

  CustomBoxPainter({
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
        log('Error drawing box: $e');
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'dart:typed_data';
import 'package:camera/camera.dart';

/// ArucoDetector – wraps ML Kit (or native OpenCV via MethodChannel)
/// to detect ArUco markers from camera frames.
///
/// Strategy A (default): Use the aruco_opencv Flutter plugin (recommended).
/// Strategy B (fallback): Call native Android/iOS via MethodChannel.
///
/// This file shows Strategy B using a MethodChannel to call OpenCV on native.

import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class ArDetector {
  static const _channel = MethodChannel('com.example.aruco_scanner/detector');

  /// Detect ArUco marker from a CameraImage frame.
  /// Returns the marker ID, or null if none found.
  Future<int?> detectMarker(CameraImage image) async {
    try {
      // Convert YUV420 to bytes for native processing
      final bytes = _yuv420ToBytes(image);

      final result = await _channel.invokeMethod<int>('detectAruco', {
        'bytes': bytes,
        'width': image.width,
        'height': image.height,
        'format': 'yuv420',
        'dictionary': 'DICT_4X4_50', // adjust to your marker dictionary
      });

      return result;
    } on PlatformException catch (e) {
      // ignore frame errors, keep scanning
      print('Detection error: ${e.message}');
      return null;
    }
  }

  Uint8List _yuv420ToBytes(CameraImage image) {
    final planes = image.planes;
    final int totalBytes = planes.fold(0, (sum, p) => sum + p.bytes.length);
    final bytes = Uint8List(totalBytes);
    int offset = 0;
    for (final plane in planes) {
      bytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    return bytes;
  }
}
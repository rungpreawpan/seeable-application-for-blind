import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class ArucoDetector {
  static const _channel = MethodChannel('com.example.aruco_scanner/detector');

  Future<int?> detectMarker(CameraImage image) async {
    try {
      final bytes = _yuv420ToBytes(image);

      final result = await _channel.invokeMethod<int>('detectAruco', {
        'bytes': bytes,
        'width': image.width,
        'height': image.height,
        'format': 'yuv420',
        'dictionary': 'DICT_4X4_50',
      });

      return result;
    } on PlatformException catch (e) {
      log('Detection error: ${e.message}');
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
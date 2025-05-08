import 'dart:math';

import 'package:get/get.dart';
import 'package:seeable/views/navigation/ble_with_server/model/ble_model.dart';

class WeightCentroidController extends GetxController {
  int topLeftRssi = 0;
  int topRightRssi = 0;
  int bottomLeftRssi = 0;
  int bottomRightRssi = 0;

  List<int> topLeftRssiList = [];
  List<int> topRightRssiList = [];
  List<int> bottomLeftRssiList = [];
  List<int> bottomRightRssiList = [];

  double topLeftDistance = 0.0;
  double topRightDistance = 0.0;
  double bottomLeftDistance = 0.0;
  double bottomRightDistance = 0.0;

  double calculateX = 0.0;
  double calculateY = 0.0;

  void findPosition(List<BLEListModel> deviceList) {
    topLeftRssiList =
        deviceList.firstWhere((e) => e.name == 'Ruuvi 862F').rssiList ?? [];
    topRightRssiList =
        deviceList.firstWhere((e) => e.name == 'Ruuvi B69D').rssiList ?? [];
    bottomLeftRssiList =
        deviceList.firstWhere((e) => e.name == 'Ruuvi 2559').rssiList ?? [];
    bottomRightRssiList =
        deviceList.firstWhere((e) => e.name == 'Ruuvi BAAD').rssiList ?? [];

    topLeftRssi = getRssiAvg(topLeftRssiList);
    topRightRssi = getRssiAvg(topRightRssiList);
    bottomLeftRssi = getRssiAvg(bottomLeftRssiList);
    bottomRightRssi = getRssiAvg(bottomRightRssiList);

    List<Map<String, dynamic>> data = [
      {'x': 0.0, 'y': 2.4, 'rssi': topLeftRssi},
      {'x': 2.5, 'y': 2.4, 'rssi': topRightRssi},
      {'x': 0.0, 'y': 0.0, 'rssi': bottomLeftRssi},
      {'x': 2.5, 'y': 0.0, 'rssi': bottomRightRssi},
    ];
    print(data);

    final result = weightCentroid(data);
    calculateX = result['x']!;
    calculateY = result['y']!;
  }

  int getRssiAvg(List<int> rssiList) {
    if (rssiList.isEmpty) return -100;
    return (rssiList.reduce((a, b) => a + b) / rssiList.length).toInt();
  }

  Map<String, double> weightCentroid(List<Map<String, dynamic>> data) {
    double sumWeight = 0.0;
    double weightedX = 0.0;
    double weightedY = 0.0;

    for (var beacon in data) {
      final int rssi = beacon['rssi'];
      final double x = beacon['x'];
      final double y = beacon['y'];

      final double weight = 1 / pow(rssi.abs(), 2);

      weightedX += x * weight;
      weightedY += y * weight;
      sumWeight += weight;
    }

    if (sumWeight == 0.0) return {'x': 0.0, 'y': 0.0};

    // print(sumWeight);
    // print(weightedX);
    // print(weightedY);
    // print(sumWeight);

    print({
      'x': weightedX / sumWeight,
      'y': weightedY / sumWeight,
    });
    return {
      'x': weightedX / sumWeight,
      'y': weightedY / sumWeight,
    };
  }

  double calDistance(int rssi) {
    double distance = pow(10, (-60 - rssi) / (10 * 3)).toDouble();
    return double.parse(distance.toStringAsFixed(2));
  }
}
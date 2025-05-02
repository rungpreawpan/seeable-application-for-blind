import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seeable/views/navigation/ble_with_server/controller/navigation_controller.dart';
import 'package:seeable/views/navigation/ble_with_server/model/ble_model.dart';

class TestNavigationController extends GetxController {
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

  findPosition(List<BLEListModel> deviceList) {
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

    // print(topLeftRssi);
    // print(topRightRssi);
    // print(bottomLeftRssi);
    // print(bottomRightRssi);

    topLeftDistance = calDistance(topLeftRssi);
    topRightDistance = calDistance(topRightRssi);
    bottomLeftDistance = calDistance(bottomLeftRssi);
    bottomRightDistance = calDistance(bottomRightRssi);

    // print(topLeftDistance);
    // print(topRightDistance);
    // print(bottomLeftDistance);
    // print(bottomRightDistance);

    double x1 = 0.0, y1 = 0.0, d1 = bottomLeftDistance;
    double x2 = 3.6, y2 = 0.0, d2 = bottomRightDistance;
    double x3 = 0.0, y3 = 8.0, d3 = topLeftDistance;
    double x4 = 3.6, y4 = 8.0, d4 = topRightDistance;

    multilateration2D(
      x1: x1,
      x2: x2,
      x3: x3,
      x4: x4,
      y1: y1,
      y2: y2,
      y3: y3,
      y4: y4,
      d1: d1,
      d2: d2,
      d3: d3,
      d4: d4,
    );

    print('x: $calculateX, y: $calculateY');
    // String direction = getDirection(
    //     userX: calculateX, userY: calculateY, headingDegree: angle);
    // print(direction);
  }

  int getRssiAvg(List<int> rssiList) {
    int avg = rssiList.length > 1
        ? (rssiList.reduce((a, b) => a + b) / rssiList.length).toInt()
        : rssiList.first;

    return avg;
  }

  double calDistance(int rssi) {
    double distance = pow(10, (-60 - rssi) / (10 * 3)).toDouble();

    return double.parse(distance.toStringAsFixed(2));
  }

  multilateration2D({
    required double x1,
    required double x2,
    required double x3,
    required double x4,
    required double y1,
    required double y2,
    required double y3,
    required double y4,
    required double d1,
    required double d2,
    required double d3,
    required double d4,
  }) async {
    // if (deviceList.length < 4) {
    //   print('null1');
    //   return null;
    // }

    List<Anchor2D> anchors = [
      Anchor2D(x1, y1),
      Anchor2D(x2, y2),
      Anchor2D(x3, y3),
      Anchor2D(x4, y4),
    ];

    List<double> distances = [
      d1,
      d2,
      d3,
      d4,
    ];

    final int n = anchors.length;
    final Anchor2D refAnchor = anchors[n - 1];
    final double refDistance = distances[n - 1];

    // Matrix A, vector b
    List<List<double>> A = [];
    List<double> b = [];

    for (int i = 0; i < n - 1; i++) {
      final Anchor2D anchor = anchors[i];
      final double distance = distances[i];

      // linearization
      // A_i = -2 (x_i - x_n)
      // B_i = -2 (y_i - y_n)
      // C_i = d^2 - d_n^2 - (x_i^2 + y_i^2 - x_n^2 - y_n^2)
      double Ai = -2.0 * (anchor.x - refAnchor.x);
      double Bi = -2.0 * (anchor.y - refAnchor.y);
      double Ci = (pow(distance, 2) -
              pow(refDistance, 2) -
              (pow(anchor.x, 2) +
                  pow(anchor.y, 2) -
                  pow(refAnchor.x, 2) -
                  pow(refAnchor.y, 2)))
          .toDouble();

      A.add([Ai, Bi]);
      b.add(Ci);
    }

    // change A, b to Matrix
    // x = (A^T A)^{-1} A^T b
    final result = _solveLeastSquares(A, b);
    if (result == null) {
      print('null2');
      return null;
    }

    final double x = result[0];
    final double y = result[1];

    calculateX = x;
    calculateY = y;

    if (kDebugMode) {
      print('multilateration2D x:$x y:$y');
    }
  }

  // Least Squares x = (A^T A)^{-1} A^T b
  // A = m x 2, b = m x 1 (m >= 2)
  List<double>? _solveLeastSquares(List<List<double>> A, List<double> b) {
    final m = A.length; // equation length
    if (m == 0) {
      print('null3');
      return null;
    }

    final n = A[0].length; // = 2 (2D)

    // A^T A -> n x n (2 x 2)
    // A^T b -> n x 1 (2 x 1)
    // calculate A^T
    List<List<double>> AT = List.generate(n, (_) => List.filled(m, 0.0));
    for (int i = 0; i < m; i++) {
      for (int j = 0; j < n; j++) {
        AT[j][i] = A[i][j];
      }
    }

    // calculate A^T A (2 x 2)
    List<List<double>> ATA = List.generate(n, (_) => List.filled(n, 0.0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        double sum = 0.0;
        for (int k = 0; k < m; k++) {
          sum += AT[i][k] * A[k][j];
        }
        ATA[i][j] = sum;
      }
    }

    // calculate A^T b (2 x 1)
    List<double> ATb = List.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      double sum = 0.0;
      for (int k = 0; k < m; k++) {
        sum += AT[i][k] * b[k];
      }
      ATb[i] = sum;
    }

    // find (A^T A)^{-1} * (A^T b)
    // แต่ (A^T A) เป็น 2x2 => เราหาอินเวิร์สได้ง่ายโดยสูตรดีเทอร์มิแนนต์
    double det = ATA[0][0] * ATA[1][1] - ATA[0][1] * ATA[1][0];
    if (det.abs() < 1e-12) {
      // det is zero or near zero
      return null;
    }

    double inv00 = ATA[1][1] / det;
    double inv01 = -ATA[0][1] / det;
    double inv10 = -ATA[1][0] / det;
    double inv11 = ATA[0][0] / det;

    // (A^T A)^{-1} (A^T b) => 2x2 dot 2x1 => 2x1
    double x = inv00 * ATb[0] + inv01 * ATb[1];
    double y = inv10 * ATb[0] + inv11 * ATb[1];

    return [x, y];
  }

  String getDirection({
    required double userX,
    required double userY,
    required double headingDegree, // หัวกำลังหันไปองศาไหน (0° = แกน X+),
    double goalX = 0.0,
    double goalY = 0.0,
  }) {
    double dx = goalX - userX;
    double dy = goalY - userY;

    // คำนวณมุมของเวกเตอร์ (dx, dy)
    double radian = atan2(dy, dx); // ค่าที่ได้เป็นเรเดียน
    double degree = radian * 180 / pi; // แปลงเป็นองศา

    // คำนวณส่วนต่างระหว่างทิศที่ต้องไปถึง กับทิศที่หันอยู่
    double diff = degree - headingDegree;

    // normalize diff ให้อยู่ในช่วง -180 ถึง 180 เพื่อให้รู้ว่าเลี้ยวขวาหรือซ้ายระยะทางสั้นที่สุด
    while (diff > 180) {
      diff -= 360;
    }
    while (diff < -180) {
      diff += 360;
    }

    // ถ้า diff > 0 => หมายถึงเราต้องเลี้ยวซ้าย
    // ถ้า diff < 0 => หมายถึงเราต้องเลี้ยวขวา
    String turn;
    if (diff > 5) {
      // ใส่ threshold 5 องศา กันสั่น
      turn = 'เลี้ยวซ้าย';
    } else if (diff < -5) {
      turn = 'เลี้ยวขวา';
    } else {
      turn = 'ตรงไป';
    }

    // ส่วนจะเดินหน้า/ถอยหลัง => อาจพิจารณาระยะทางจากจุดหมาย
    double distance = sqrt(dx * dx + dy * dy);
    // สมมติระยะทาง > 0.2 => ให้เดินหน้า
    // (ขึ้นอยู่กับว่า headingDeg ตรงกับทิศที่เลี้ยวมาแล้วหรือไม่)
    if (distance > 0.2) {
      // เดินหน้า (กรณีเราจัดระเบียบให้หน้าของเราไปทาง alphaDeg เรียบร้อย)
      return '$turn และ เดินหน้า ($distance เมตร)';
    } else {
      return '$turn และ หยุด (ถึงที่หมาย)';
    }
  }

  List<int> kalmanFilter(List<int> rssiList) {
    double x = rssiList[0].toDouble(); // initial state
    double P = 1.0; // initial state variance
    double Q = 1e-5; // process variance
    double R = 1.0; // measurement variance

    List<int> result = [];

    for (int z in rssiList) {
      // Prediction step
      double xPrior = x;
      double PPrior = P + Q;

      // Update step
      double K = PPrior / (PPrior + R);
      x = xPrior + K * (z - xPrior);
      P = (1 - K) * PPrior;

      result.add(x.toInt());
    }

    return result;
  }
}

class Point2D {
  final double x;
  final double y;

  Point2D(
    this.x,
    this.y,
  );

  @override
  String toString() => '($x, $y)';
}

class Anchor2D {
  final double x;
  final double y;

  Anchor2D(
    this.x,
    this.y,
  );

  @override
  String toString() => '($x, $y)';
}

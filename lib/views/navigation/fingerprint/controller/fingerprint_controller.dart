import 'dart:developer';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class FingerprintController extends GetxController {
  var isScanning = false.obs;
  RxList<ScanResult> scanList = <ScanResult>[].obs;
  RxList<ScanResult> connectedList = <ScanResult>[].obs;

  RxMap<String, List<int>> rssiMap = <String, List<int>>{}.obs;

  bool _isCurrentlyScanning = false;

  final Set<String> allowedDeviceNames = {
    "Ruuvi AB5E",
    "Ruuvi 778D",
    "Ruuvi 5639",
    "Ruuvi 6D52",
    "Ruuvi BAAD",
  };

  scanDevices() async {
    if (_isCurrentlyScanning) {
      print("Scan already running, skip...");
      return;
    }

    _isCurrentlyScanning = true;
    print('start scan');
    isScanning.value = true;

    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          final filtered = results.where(
            (e) {
              final name = e.device.platformName.trim();
              final isAllowed = allowedDeviceNames.contains(name);
              if (isAllowed) {
                print('Allowed: ${e.device.remoteId} $name');
                return true;
              } else {
                return false;
              }
            },
          ).toList();

          scanList.value = filtered;

          final connectedNames =
              connectedList.map((c) => c.device.platformName.trim()).toSet();

          final newDevices = scanList.where(
            (scan) => !connectedNames.contains(scan.device.platformName.trim()),
          );

          for (var scan in newDevices) {
            connectDevice(scan.device);
            connectedList.add(scan);
          }
        }
      },
      onError: (e) {
        log('Scan error: $e');
        scanList.clear();
        connectedList.clear();
      },
    );

    FlutterBluePlus.cancelWhenScanComplete(subscription);

    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    isScanning.value = false;
    _isCurrentlyScanning = false;
    print('scan complete');
  }

  connectDevice(BluetoothDevice device) async {
    final name = device.platformName.trim();
    if (!allowedDeviceNames.contains(name)) {
      print('Not in allowed list, skip connect: $name');
      return;
    }

    try {
      var state = await device.connectionState.first;
      if (state == BluetoothConnectionState.connected) {
        print('$name already connected');
        return;
      }

      print('Connecting to $name...');
      await device.connect(timeout: const Duration(seconds: 5));
      print('Connected to $name');
    } catch (e) {
      print('Error connecting to $name: $e');
    }
  }

  readRssi() async {
    for (ScanResult connected in connectedList.toList()) {
      BluetoothDevice device = connected.device;

      try {
        var state = await device.connectionState.first;
        if (state == BluetoothConnectionState.connected) {
          int rssi = await device.readRssi();
          String deviceKey = device.platformName.trim();

          if (!rssiMap.containsKey(deviceKey)) {
            rssiMap[deviceKey] = [];
          }

          rssiMap[deviceKey]!.add(rssi);

          if (rssiMap[deviceKey]!.length > 100) {
            rssiMap[deviceKey]!.removeAt(0);
          }

          print('Updated RSSI for $deviceKey: $rssi');
          _printSummary(deviceKey, rssiMap[deviceKey]!);
        }
      } catch (e) {
        print('Error reading RSSI from ${device.platformName}: $e');
      }
    }
  }

  void _printSummary(String deviceKey, List<int> values) {
    if (values.isEmpty) return;

    final int minVal = values.reduce((a, b) => a < b ? a : b);
    final int maxVal = values.reduce((a, b) => a > b ? a : b);
    final double avgVal =
        values.reduce((a, b) => a + b) / values.length.toDouble();

    print("📊 SUMMARY [$deviceKey]");
    print("  Total values: ${values.length}");
    print("  Min RSSI: $minVal dBm");
    print("  Max RSSI: $maxVal dBm");
    print("  Avg RSSI: ${avgVal.toStringAsFixed(2)} dBm");
    print(values);
  }

  clearData() async {
    if (connectedList.isNotEmpty) {
      for (ScanResult connected in connectedList.toList()) {
        try {
          await connected.device.disconnect();
          print('Disconnected ${connected.device.platformName}');
        } catch (e) {
          print('Error disconnecting ${connected.device.platformName}: $e');
        }
      }
    }

    scanList.clear();
    connectedList.clear();
    rssiMap.clear();
  }
}

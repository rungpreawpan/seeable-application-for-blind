import 'dart:developer';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class TestBleController extends GetxController {
  var isScanning = false.obs;
  RxList<ScanResult> scanList = <ScanResult>[].obs;
  RxList<ScanResult> connectedList = <ScanResult>[].obs;

  RxMap<String, List<int>> rssiMap = <String, List<int>>{}.obs;

  scanDevices() async {
    print('start scan');

    isScanning.value = true;

    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          scanList.value = results
              .where((e) {
                e.device.platformName.contains('Ruuvi')
                    ? print('${e.device.remoteId} ${e.device.platformName}')
                    : null;

                return e.device.platformName.contains('Ruuvi');
              })
              .map((e) => e)
              .toList();

          if (connectedList.isEmpty) {
            for (ScanResult scan in scanList) {
              connectDevice(scan.device);
              connectedList.add(scan);
            }
          } else {
            for (ScanResult connected in connectedList) {
              for (ScanResult scan in scanList) {
                if (scan.device.platformName != connected.device.platformName) {
                  connectDevice(scan.device);
                  connectedList.add(scan);
                }
              }
            }
          }
        }
      },
      onError: (e) {
        log(e);
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

    print('scan complete');
  }

  connectDevice(BluetoothDevice device) async {
    await device.connect();

    print('Connected to ${device.platformName}');
  }

  readRssi() async {
    for (ScanResult connected in connectedList) {
      BluetoothDevice device = connected.device;

      try {
        var state = await device.connectionState.first;
        if (state == BluetoothConnectionState.connected) {
          int rssi = await device.readRssi();
          String deviceKey = device.platformName;

          if (!rssiMap.containsKey(deviceKey)) {
            rssiMap[deviceKey] = [];
          }

          rssiMap[deviceKey]!.add(rssi);

          if (rssiMap[deviceKey]!.length > 100) {
            rssiMap[deviceKey]!.removeAt(0);
          }

          print('Updated RSSI for $deviceKey: $rssi');
          print('All RSSI values for $deviceKey: ${rssiMap[deviceKey]}');
        }
      } catch (e) {
        print('Error reading RSSI from ${device.platformName}: $e');
      }
    }
  }

  clearData() {
    if (connectedList.isEmpty) {
      for (ScanResult connected in connectedList) {
        connected.device.disconnect();
      }
    }

    scanList.clear();
    connectedList.clear();
    rssiMap.clear();
  }
}

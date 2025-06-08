import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/navigation/fingerprint/model/fingerprint_model.dart';

class FingerprintController extends GetxController {
  var isLoading = false.obs;
  var isScanning = false.obs;

  RxList<ScanResult> scanList = <ScanResult>[].obs;

  RxMap<String, List<int>> rssiMap = <String, List<int>>{}.obs;

  FingerprintModel? position;

  scanDevices() async {
    if (kDebugMode) {
      print('start scan');
    }

    isScanning.value = true;

    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          scanList.value = results
              .where((e) {
                if (kDebugMode) {
                  e.device.platformName.contains('Ruuvi')
                      ? print('${e.device.remoteId} ${e.device.platformName}')
                      : null;
                }

                return e.device.platformName.contains('Ruuvi');
              })
              .map((e) => e)
              .toList();

          readRssi();
        }
      },
      onError: (e) {
        log(e);
      },
    );

    FlutterBluePlus.cancelWhenScanComplete(subscription);

    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));

    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    isScanning.value = false;

    if (kDebugMode) {
      print('scan complete');
    }
  }

  readRssi() async {
    for (var result in scanList) {
      int rssi = result.rssi;
      String deviceKey = result.device.platformName;

      if (!rssiMap.containsKey(deviceKey)) {
        rssiMap[deviceKey] = [];
      }

      rssiMap[deviceKey]!.add(rssi);

      if (rssiMap[deviceKey]!.length > 20) {
        rssiMap[deviceKey]!.removeAt(0);
      }

      if (kDebugMode) {
        print('Updated RSSI for $deviceKey: $rssi');
        print('All RSSI values for $deviceKey: ${rssiMap[deviceKey]}');
      }
    }
  }

  Map<String, List<int>> convertRssiMap(Map<String, List<int>> rssiMap) {
    Map<String, List<int>> transformed = {};

    rssiMap.forEach((key, values) {
      String newKey = key.replaceAll(' ', '_');
      transformed[newKey] = values;
    });

    return transformed;
  }


  sendRssi() async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('ไม่มีสัญญาณอินเตอร์เน็ต');
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/localize',
        method: HttpMethod.post,
        data: {
          'rssi_map': convertRssiMap(rssiMap),
        },
      );

      if (response != null && response.statusCode == 200) {
        var dataJSON = response.data;
        position = FingerprintModel.fromJSON(dataJSON);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

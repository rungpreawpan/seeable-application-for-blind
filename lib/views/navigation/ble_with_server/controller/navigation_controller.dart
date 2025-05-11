import 'dart:developer';

import 'package:get/get.dart';
import 'package:seeable/constant/environment.dart';
import 'package:seeable/controller/app_info_controller.dart';
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/navigation/ble_with_server/controller/test_navigation_controller.dart';
import 'package:seeable/views/navigation/ble_with_server/controller/weight_centroid_controller.dart';
import 'package:seeable/views/navigation/ble_with_server/model/ble_model.dart';
import 'package:seeable/views/navigation/ble_with_server/model/place_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class NavigationController extends GetxController {
  var isLoading = false.obs;

  TestNavigationController testNavigationController =
      Get.put(TestNavigationController());
  WeightCentroidController weightCentroidController =
      Get.put(WeightCentroidController());
  AppInfoController appInfoController = Get.find();
  List<PlaceModel> placeList = [];
  List<BLEListModel> bleDataList = [];

  late IO.Socket socket;

  getAllPlaces() async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('ไม่มีสัญญาณอินเตอร์เน็ต');
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/places',
        method: HttpMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        var dataJSON = response.data;
        placeList = dataJSON
            .map<PlaceModel>((json) => PlaceModel.fromJSON(json))
            .toList();
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  setFavorite({
    required int placeId,
    required bool isFavorite,
  }) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('ไม่มีสัญญาณอินเตอร์เน็ต');
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/places/$placeId/favorite',
        method: HttpMethod.put,
        data: {
          "is_favorite": isFavorite,
        },
      );

      if (response != null && response.statusCode == 200) {
        print(response);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  startNavigation(List bleNames) async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('ไม่มีสัญญาณอินเตอร์เน็ต');
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/navigation/start',
        method: HttpMethod.post,
        data: {
          'uuid': appInfoController.uuid.value,
          'ble_names': bleNames,
        },
      );

      if (response != null && response.statusCode == 200) {
        print(response);
        bleDataList.clear();
        connectSocket();
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  stopNavigation() async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('ไม่มีสัญญาณอินเตอร์เน็ต');
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/navigation/stop',
        method: HttpMethod.post,
        data: {
          'uuid': appInfoController.uuid.value,
        },
      );

      if (response != null && response.statusCode == 200) {
        print(response);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void connectSocket() {
    socket = IO.io(getBaseURL(), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      log('Socket connected');
    });

    socket.onDisconnect((_) {
      log('Socket disconnected');
    });

    socket.on('ble-data', (data) {
      final ble = BLEModel.fromJSON(data);

      final index = bleDataList.indexWhere((b) => b.mac == ble.mac);

      if (index != -1) {
        bleDataList[index].rssiList!.add(ble.rssi ?? 0);

        if (bleDataList[index].rssiList!.length > 20) {
          bleDataList[index].rssiList!.removeAt(0);
        }
      } else {
        BLEListModel receivedData = BLEListModel(
          uuid: ble.uuid,
          mac: ble.mac,
          name: ble.name,
          rssiList: [ble.rssi ?? 0],
        );

        bleDataList.add(receivedData);
      }

      // testNavigationController.findPosition(bleDataList); //TODO
      log('BLE ${ble.name} - RSSI ล่าสุด: ${ble.rssi}');
      weightCentroidController.findPosition(bleDataList);
    });
  }

  void disconnectSocket() {
    if (socket.connected) {
      socket.disconnect();
    }
  }
}

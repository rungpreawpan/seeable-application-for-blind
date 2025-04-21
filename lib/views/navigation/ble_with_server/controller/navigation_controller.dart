import 'dart:developer';

import 'package:get/get.dart';
import 'package:seeable/controller/app_info_controller.dart';
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/navigation/ble_with_server/model/place_model.dart';

class NavigationController extends GetxController {
  var isLoading = false.obs;

  AppInfoController appInfoController = Get.find();
  List<PlaceModel> placeList = [];

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

  setFavorite() async {
    //TODO
  }

  startNavigation() async {
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
}

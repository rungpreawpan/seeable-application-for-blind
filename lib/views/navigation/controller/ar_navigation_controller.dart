import 'dart:developer';

import 'package:get/get.dart';
import 'package:seeable/service/request_service.dart';
import 'package:seeable/utils/alert.dart';
import 'package:seeable/views/navigation/model/ar_markers_model.dart';

class ArNavigationController extends GetxController {
  var isLoading = false.obs;

  List<ArMarkersModel> markersList = [];
  ArMarkersModel? selectedMarker;

  getAllMarkers() async {
    bool isOnline = await RequestService().checkInternetConnection();

    if (!isOnline) {
      showAlert('no internet connection'.tr);
      isLoading.value = false;

      return;
    }

    try {
      isLoading.value = true;

      var response = await RequestService().request(
        '/ar-markers',
        method: HttpMethod.get,
      );

      if (response != null && response.statusCode == 200) {
        var dataJSON = response.data;
        markersList = dataJSON
            .map<ArMarkersModel>((json) => ArMarkersModel.fromJSON(json))
            .toList();
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  getMarkersById() async {
    isLoading.value = true;
  }
}

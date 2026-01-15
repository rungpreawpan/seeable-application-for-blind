import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/navigation/controller/navigation_controller.dart';
import 'package:seeable/widgets/navigation_main_template.dart';

class ArMarkerPlacePage extends StatefulWidget {
  const ArMarkerPlacePage({super.key});

  @override
  State<ArMarkerPlacePage> createState() => _ArMarkerPlacePageState();
}

class _ArMarkerPlacePageState extends State<ArMarkerPlacePage> {
  final NavigationController _navigationController = Get.put(NavigationController());

  @override
  void initState() {
    super.initState();
  }

  _prepareData() {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
    // return NavigationMainTemplate(itemWidget: itemWidget, items: items)
  }
}

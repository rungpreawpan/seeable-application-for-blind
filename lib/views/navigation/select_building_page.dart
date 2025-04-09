import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seeable/views/navigation/select_category_page.dart';
import 'package:seeable/widgets/listview_button.dart';
import 'package:seeable/widgets/navigation_main_template.dart';

class SelectBuildingPage extends StatefulWidget {
  const SelectBuildingPage({super.key});

  @override
  State<SelectBuildingPage> createState() => _SelectBuildingPageState();
}

class _SelectBuildingPageState extends State<SelectBuildingPage> {
  List buildingList = [
    {'title': 'building a'.tr},
    {'title': 'building b'.tr},
    {'title': 'building c'.tr},
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationMainTemplate(
      appBarTitle: 'navigation'.tr,
      items: buildingList,
      itemWidget: (context, index) {
        var item = buildingList[index];

        return ListViewButton(
          onTap: () {
            Get.to(
              () => SelectCategoryPage(appBarTitle: item['title']),
            );
          },
          iconPath: 'assets/icons/building_icon.svg',
          title: item['title'],
        );
      },
    );
  }
}

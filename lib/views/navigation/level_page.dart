import 'package:flutter/material.dart';
import 'package:seeable/widgets/listview_button.dart';
import 'package:seeable/widgets/navigation_main_template.dart';

class LevelPage extends StatelessWidget {
  final String appBarTitle;

  const LevelPage({
    super.key,
    required this.appBarTitle,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationMainTemplate(
      appBarTitle: appBarTitle,
      items: [],
      itemWidget: (context, index) {
        // var item = buildingList[index];

        //TODO:
        return ListViewButton(
          onTap: () {},
          iconPath: '',
          title: '',
        );
      },
    );
  }
}

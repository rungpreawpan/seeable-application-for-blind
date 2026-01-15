import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:seeable/views/settings/controller/settings_controller.dart';
import 'package:seeable/widgets/custom_back_button.dart';
import 'package:seeable/widgets/text_font_style.dart';

class MainTemplate extends StatefulWidget {
  final String appBarTitle;
  final bool showBackButton;
  final Function()? onBack;
  final List<Widget>? actions;
  final Widget? body;
  final Widget? floatingActionButton;

  const MainTemplate({
    super.key,
    this.appBarTitle = '',
    this.showBackButton = false,
    this.onBack,
    this.actions,
    this.body,
    this.floatingActionButton,
  });

  @override
  State<MainTemplate> createState() => _MainTemplateState();
}

class _MainTemplateState extends State<MainTemplate> {
  final SettingsController _settingsController = Get.find();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: widget.appBarTitle != ''
            ? TextFontStyle(
                widget.appBarTitle,
                style: theme.textTheme.titleLarge,
                align: TextAlign.center,
              )
            : SvgPicture.asset(
                _settingsController.themeMode.value == ThemeMode.light
                    ? 'assets/logo/seeable_logo.svg'
                    : 'assets/logo/seeable_logo_dark_theme.svg',
                height: 90.0,
              ),
        leading: Visibility(
          visible: widget.showBackButton,
          child: CustomBackButton(
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              }

              Get.back();
            },
          ),
        ),
        actions: widget.actions,
        centerTitle: true,
        toolbarHeight: 90.0,
        elevation: 0.0,
      ),
      body: SizedBox.expand(
        child: widget.body,
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

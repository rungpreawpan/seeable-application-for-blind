import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seeable/constant/value_constant.dart';
import 'package:seeable/firebase_options.dart';
import 'package:seeable/localization/localize.dart';
import 'package:seeable/views/splash_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'views/settings/controller/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    log('Failed to initailize Firebase: $e');
  }

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  Get.put(SettingsController());

  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  ).then((value) => runApp(const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Seeable - Application for Blind',
      translations: Translation(),
      locale: const Locale('th'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('th'),
        Locale('en'),
      ],
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      home: const SplashPage(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }

  ThemeData get _lightTheme => ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        primaryColor: primaryColor,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        textTheme: TextTheme(
          labelLarge: TextStyle(
            fontSize: fontSizeXL,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.kanit().fontFamily,
            letterSpacing: 0,
            color: Colors.black,
            overflow: TextOverflow.ellipsis,
          ),
          labelMedium: TextStyle(
            fontSize: fontSizeL,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.kanit().fontFamily,
            letterSpacing: 0,
            color: Colors.black,
          ),
          labelSmall: TextStyle(
            fontSize: fontSizeL,
            fontWeight: FontWeight.normal,
            fontFamily: GoogleFonts.kanit().fontFamily,
            letterSpacing: 0,
            color: Colors.black,
          ),
          titleLarge: TextStyle(
            fontSize: fontAppbar,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.kanit().fontFamily,
            letterSpacing: 0,
            color: primaryColor,
          ),
          displaySmall: TextStyle(
            fontSize: fontSizeM,
            fontWeight: FontWeight.normal,
            fontFamily: GoogleFonts.kanit().fontFamily,
            letterSpacing: 0,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 0.0,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: TextStyle(
            fontFamily: GoogleFonts.kanit().fontFamily,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: GoogleFonts.kanit().fontFamily,
          ),
        ),
      );

  ThemeData get _darkTheme => ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        primaryColor: Colors.grey,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        textTheme: TextTheme(
          labelLarge: TextStyle(
            fontSize: fontSizeXL,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.kanit().fontFamily,
            letterSpacing: 0,
            color: Colors.white,
            overflow: TextOverflow.ellipsis,
          ),
          labelMedium: TextStyle(
            fontSize: fontSizeL,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.kanit().fontFamily,
            letterSpacing: 0,
            color: Colors.white,
          ),
          labelSmall: TextStyle(
            fontSize: fontSizeL,
            fontWeight: FontWeight.normal,
            fontFamily: GoogleFonts.kanit().fontFamily,
            letterSpacing: 0,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: fontAppbar,
            fontWeight: FontWeight.bold,
            fontFamily: GoogleFonts.kanit().fontFamily,
            letterSpacing: 0,
            color: Colors.white,
          ),
          displaySmall: TextStyle(
            fontSize: fontSizeM,
            fontWeight: FontWeight.normal,
            fontFamily: GoogleFonts.kanit().fontFamily,
            letterSpacing: 0,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        scaffoldBackgroundColor: primaryDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryDark,
          foregroundColor: primaryDark,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 0.0,
          backgroundColor: secondaryDark,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white,
          selectedLabelStyle: TextStyle(
            fontFamily: GoogleFonts.kanit().fontFamily,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: GoogleFonts.kanit().fontFamily,
          ),
        ),
      );
}

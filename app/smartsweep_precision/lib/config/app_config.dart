import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SizeConfig {
  static MediaQueryData mediaQueryData = const MediaQueryData();
  static double screenWidth = 0;
  static double screenHeight = 0;
  static double defaultSize = 0;
  static double get defaultCircleAvatarRadius {
    return 20;
  }

  void initialize(BuildContext context) {
    mediaQueryData = MediaQuery.of(context);
    screenWidth = mediaQueryData.size.width;
    screenHeight = mediaQueryData.size.height;
    defaultSize = screenWidth * 0.024;
  }
}

class AppConfig {
  static String get appStoreListing {
    return "https://play.google.com/store/apps/details?id=$packageName";
  }

  static String get developerName {
    return "AppSolves";
  }

  static String get developerSite {
    return "https://play.google.com/store/apps/dev?id=6007461154397933888";
  }

  static String get legalese {
    final year = 2024 - DateTimeConfig.year == 0
        ? DateTimeConfig.year
        : "2024 - ${DateTimeConfig.year}";
    return "$appName\nPublished by $developerName\n\nCopyright \u{a9} $year by $developerName\n\nAll rights reserved.";
  }

  static String packageName = "";
  static String appName = "";
  static String version = "";

  void initialize() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    packageName = packageInfo.packageName;
    appName = packageInfo.appName;
    version = packageInfo.version;
  }
}

class DateTimeConfig {
  static int get year {
    return DateTime.now().year;
  }

  static Stream get onHourChange {
    return Stream.periodic(const Duration(seconds: 5), (_) {
      if (DateTime.now().minute == 0) return DateTime.now().hour;
    });
  }
}

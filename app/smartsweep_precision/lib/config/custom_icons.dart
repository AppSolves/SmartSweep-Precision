import 'package:flutter/material.dart';

class CustomIcons {
  CustomIcons._();

  static const _kFontFam = 'CustomIcons';

  // ignore: constant_identifier_names
  static const IconData custom_menu_icon =
      IconData(0xE800, fontFamily: _kFontFam);

  // Create a AppIcon method that gets the app icon png from assets and converts it to a iconData
  static Image appIcon({Size? size, Color? color}) {
    size ??= const Size(30, 30);
    return Image.asset(
      'assets/images/logo.png',
      width: size.width,
      height: size.height,
      color: color,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:smartsweep_precision/config/connection.dart';
import 'package:smartsweep_precision/config/themes.dart';
import 'package:smartsweep_precision/main.dart';

extension StringExtension on String {
  String correctEllipsis() {
    return replaceAll('', '\u200B');
  }

  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

extension ColorExtension on Color {
  Color lighter(int amount) {
    return Color.fromARGB(
      alpha,
      (red + amount).clamp(0, 255),
      (green + amount).clamp(0, 255),
      (blue + amount).clamp(0, 255),
    );
  }

  Color darker(int amount) {
    return Color.fromARGB(
      alpha,
      (red - amount).clamp(0, 255),
      (green - amount).clamp(0, 255),
      (blue - amount).clamp(0, 255),
    );
  }

  Color contrast(int amount) {
    final ThemeMode themeMode = MainAppState.themeModeNotifier.value;

    return themeMode == ThemeMode.dark
        ? lighter(amount)
        : themeMode == ThemeMode.light
            ? darker(amount)
            : Themes.platformBrightness == Brightness.dark
                ? lighter(amount)
                : darker(amount);
  }

  Color fromHex(String hex) {
    hex = hex.toUpperCase().replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

extension ControlButtonExtension on ControlButton {
  bool get isNone => this == ControlButton.none;
  bool get isNotNone => !isNone;
  bool get isMoveForward => this == ControlButton.moveForward;
  bool get isMoveBackward => this == ControlButton.moveBackward;
  bool get isTurnLeft => this == ControlButton.turnLeft;
  bool get isTurnRight => this == ControlButton.turnRight;
}

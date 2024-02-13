import 'package:flutter/material.dart';
import 'package:smartsweep_precision/config/connection.dart';

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
}

extension ControlButtonExtension on ControlButton {
  bool get isNone => this == ControlButton.none;
  bool get isNotNone => !isNone;
  bool get isMoveForward => this == ControlButton.moveForward;
  bool get isMoveBackward => this == ControlButton.moveBackward;
  bool get isTurnLeft => this == ControlButton.turnLeft;
  bool get isTurnRight => this == ControlButton.turnRight;
}

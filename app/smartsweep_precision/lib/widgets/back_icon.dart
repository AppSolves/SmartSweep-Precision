import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smartsweep_precision/config/app_config.dart';

class BackIcon extends StatelessWidget {
  const BackIcon({
    super.key,
    this.color,
    this.isReverse = false,
    this.offset = const Offset(0, 0),
    this.size,
  });

  final Color? color;
  final bool isReverse;
  final Offset offset;

  /// The size of the icon. If `null`, the default size is used. If `size < 0`, the parent's default size is used.
  final double? size;

  Transform _icon(BuildContext context) {
    final double? size = this.size == null
        ? SizeConfig.defaultSize * 3
        : this.size! < 0
            ? null
            : this.size;
    final Icon icon = Platform.isAndroid
        ? Icon(
            Icons.arrow_back_rounded,
            size: size,
            color: color ?? Theme.of(context).iconTheme.color,
          )
        : Icon(
            Icons.arrow_back_ios_new_rounded,
            size: size,
            color: color ?? Theme.of(context).iconTheme.color,
          );

    return Transform.translate(offset: offset, child: icon);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().initialize(context);
    return isReverse
        ? Transform.rotate(
            angle: math.pi,
            child: _icon(context),
          )
        : _icon(context);
  }
}

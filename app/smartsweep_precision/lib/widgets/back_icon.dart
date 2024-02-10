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
  });

  final Color? color;
  final bool isReverse;
  final Offset offset;

  Transform _icon(BuildContext context) {
    final Icon icon = Platform.isAndroid
        ? Icon(
            Icons.arrow_back_rounded,
            size: SizeConfig.defaultSize * 3,
            color: color ?? Theme.of(context).iconTheme.color,
          )
        : Icon(
            Icons.arrow_back_ios_new_rounded,
            size: SizeConfig.defaultSize * 3,
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

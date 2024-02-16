import 'package:flutter/material.dart';
import 'package:smartsweep_precision/config/themes.dart';

class _JumpingDot extends AnimatedWidget {
  final Color? color;
  final double? fontSize;

  const _JumpingDot({
    required Animation<double> animation,
    this.color,
    this.fontSize,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    return SizedBox(
      height: animation.value + fontSize! + 10,
      child: Text(
        '.',
        style: TextStyle(
          color: color ?? Themes.primaryColor,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

class JumpingDotsProgressIndicator extends StatefulWidget {
  final int numberOfDots;
  final double fontSize;
  final double dotSpacing;
  final Color? color;
  final int milliseconds;
  final double beginTweenValue = 0.0;
  final double endTweenValue = 8.0;
  final bool render;

  const JumpingDotsProgressIndicator({
    super.key,
    this.numberOfDots = 3,
    this.fontSize = 10.0,
    this.color,
    this.dotSpacing = 0.0,
    this.milliseconds = 250,
    this.render = true,
  });

  @override
  JumpingDotsProgressIndicatorState createState() =>
      JumpingDotsProgressIndicatorState();
}

class JumpingDotsProgressIndicatorState
    extends State<JumpingDotsProgressIndicator> with TickerProviderStateMixin {
  late int? numberOfDots;
  late int? milliseconds;
  late double? fontSize;
  late double? dotSpacing;
  late Color? color;
  List<AnimationController> controllers = <AnimationController>[];
  List<Animation<double>> animations = <Animation<double>>[];
  List<Widget> widgets = <Widget>[];

  @override
  void initState() {
    super.initState();

    numberOfDots = widget.numberOfDots;
    milliseconds = widget.milliseconds;
    fontSize = widget.fontSize;
    dotSpacing = widget.dotSpacing;
    color = widget.color;

    for (int i = 0; i < numberOfDots!; i++) {
      _addAnimationControllers();
      _buildAnimations(i);
      _addListOfDots(i);
    }

    controllers[0].forward();
  }

  void _addAnimationControllers() {
    controllers.add(
      AnimationController(
        duration: Duration(milliseconds: milliseconds!),
        vsync: this,
      ),
    );
  }

  void _addListOfDots(int index) {
    widgets.add(
      Padding(
        padding: EdgeInsets.only(right: dotSpacing!),
        child: _JumpingDot(
          animation: animations[index],
          fontSize: fontSize,
          color: color,
        ),
      ),
    );
  }

  void _buildAnimations(int index) {
    animations.add(
      Tween(begin: widget.beginTweenValue, end: widget.endTweenValue)
          .animate(controllers[index])
        ..addStatusListener(
          (AnimationStatus status) {
            if (status == AnimationStatus.completed) {
              controllers[index].reverse();
            }
            if (index == numberOfDots! - 1 &&
                status == AnimationStatus.dismissed) {
              controllers[0].forward();
            }
            if (animations[index].value > widget.endTweenValue / 2 &&
                index < numberOfDots! - 1) {
              controllers[index + 1].forward();
            }
          },
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: fontSize! + fontSize! * 0.5,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: widget.render
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: widgets,
              )
            : const SizedBox(),
      ),
    );
  }

  @override
  void dispose() {
    for (final AnimationController controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

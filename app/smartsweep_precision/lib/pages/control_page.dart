import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartsweep_precision/config/app_config.dart';
import 'package:smartsweep_precision/config/connection.dart';
import 'package:smartsweep_precision/config/extensions.dart';
import 'package:smartsweep_precision/config/prints.dart';
import 'package:smartsweep_precision/config/themes.dart';
import 'package:smartsweep_precision/widgets/back_icon.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({
    super.key,
    required this.device,
  });

  final BluetoothDevice device;

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  late final StreamSubscription<bool>? _connectionStateSubscription;
  late final StreamSubscription<bool> _bluetoothStateSubscription;
  late final StreamSubscription<Map<String, dynamic>>?
      _onValueArrivedSubscription;
  bool _disconnectedManually = false;
  bool _isCleaning = false;
  String? _firmwareVersion;
  bool _disableStartStopButton = false;
  final ValueNotifier<ControlButton> _currentControlButton =
      ValueNotifier<ControlButton>(ControlButton.none);
  double _speed = 45;
  bool _mainBrushEnabled = false;
  bool _sideBrushEnabled = false;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations(
      [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ],
    );
    toggleWakelock(true);
    _connectionStateSubscription =
        ConnectionManager.onConnectionStateChanged?.listen(
      (bool isConnected) {
        if (!isConnected && !_disconnectedManually && mounted) {
          showDisconnectionConfirmationDialog(
            context,
            widget.device.platformName,
            suddenDisconnection: true,
          );
        }
      },
    );
    _bluetoothStateSubscription =
        ConnectionManager.onBluetoothStateChanged.listen(
      (bool isBluetoothEnabled) {
        if (!isBluetoothEnabled && mounted) {
          showDisconnectionConfirmationDialog(
            context,
            widget.device.platformName,
            suddenDisconnection: true,
          );
        }
      },
    );
    _onValueArrivedSubscription = ConnectionManager.onValueArrived?.listen(
      handleData,
      cancelOnError: true,
    );
    ConnectionManager.write({"command": "set_speed", "speed": _speed.round()});
    ConnectionManager.write({"command": "request_initial_info"});
    super.initState();
  }

  void handleData(Map<String, dynamic> data) {
    printError(data);
    for (final String key in data.keys) {
      if (key == "firmware_version") {
        if (data["firmware_version"] != _firmwareVersion) {
          _firmwareVersion = data["firmware_version"];
        }
      } else if (key == "is_cleaning") {
        if (data["is_cleaning"] != _isCleaning) {
          _isCleaning = data["is_cleaning"];
        }
      } else if (key == "stopped") {
        _currentControlButton.value = ControlButton.none;
      } else if (key == "speed_set") {
        if (data["speed_set"] != _speed) {
          _speed = (data["speed_set"] as int).toDouble();
        }
      } else if (key == "brush_set") {
        final String brush = data["brush_set"]["brush"];
        if (brush == "main") {
          final bool value = data["brush_set"]["value"];
          if (value != _mainBrushEnabled) {
            _mainBrushEnabled = value;
          }
        } else if (brush == "side") {
          final bool value = data["brush_set"]["value"];
          if (value != _sideBrushEnabled) {
            _sideBrushEnabled = value;
          }
        } else if (brush == "both") {
          final List<bool> values =
              (data["brush_set"]["value"] as List<dynamic>).map((value) {
            return value as bool;
          }).toList();
          if (values[0] != _mainBrushEnabled) {
            _mainBrushEnabled = values[0];
          }
          if (values[1] != _sideBrushEnabled) {
            _sideBrushEnabled = values[1];
          }
        }
      } else {
        printError("Unknown key: $key");
      }
    }

    if (mounted) {
      setState(() {
        _disableStartStopButton = false;
      });
    }
  }

  @override
  void dispose() {
    toggleWakelock(false);
    _connectionStateSubscription?.cancel();
    _bluetoothStateSubscription.cancel();
    _onValueArrivedSubscription?.cancel();
    _currentControlButton.dispose();
    super.dispose();
  }

  void toggleWakelock(bool enable) async {
    await WakelockPlus.toggle(enable: enable);
  }

  void showDisconnectionConfirmationDialog(
    BuildContext context,
    String deviceName, {
    bool suddenDisconnection = false,
  }) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(suddenDisconnection ? 'Connection lost' : 'Disconnect'),
          content: Text(
            suddenDisconnection
                ? "Connection to '$deviceName' was lost. Please reconnect from the home page."
                : "Are you sure you want to disconnect from '$deviceName'?",
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!suddenDisconnection)
                    Themes.textButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Themes.textButton(
                      onPressed: () async {
                        if (!suddenDisconnection) {
                          ConnectionManager.disconnectAll();
                        }
                        await SystemChrome.setPreferredOrientations(
                          [DeviceOrientation.portraitUp],
                        );
                        if (!context.mounted) return;
                        Navigator.popUntil(
                          context,
                          (route) => route.isFirst,
                        );
                      },
                      child: Text(
                        suddenDisconnection ? 'OK' : 'Disconnect',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;

        setState(() {
          _disconnectedManually = true;
        });
        showDisconnectionConfirmationDialog(
          context,
          widget.device.platformName,
        );
      },
      child: OrientationBuilder(
        builder: (context, orientation) {
          final bool isPortrait =
              orientation == Orientation.portrait ? true : false;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.device.platformName,
              ),
              centerTitle: true,
              leading: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _disconnectedManually = true;
                    });

                    showDisconnectionConfirmationDialog(
                      context,
                      widget.device.platformName,
                    );
                  },
                  iconSize: isPortrait
                      ? SizeConfig.defaultSize * 3
                      : SizeConfig.defaultSize * 2,
                  tooltip: 'Back',
                  icon: BackIcon(
                    size: -1,
                    offset: isPortrait
                        ? const Offset(-2.5, 0)
                        : const Offset(-7.5, 0),
                  ),
                ),
              ),
            ),
            body: orientation == Orientation.landscape
                ? buildBodyLandscape(context)
                : buildBodyPortrait(context),
          );
        },
      ),
    );
  }

  Widget buildBodyLandscape(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _isCleaning
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 25,
                      right: 25,
                      bottom: 25,
                    ),
                    child: Text(
                      "Your SmartSweep robot is currently cleaning. In order to control it, please stop the cleaning process first.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                        Theme.of(context).primaryColor,
                      ),
                      foregroundColor: WidgetStateProperty.all<Color>(
                        Theme.of(context).scaffoldBackgroundColor,
                      ),
                      padding: WidgetStateProperty.all<EdgeInsets>(
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      ),
                      shape: WidgetStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (_disableStartStopButton) return;

                      ConnectionManager.write({"command": "stop_cleaning"});
                      setState(() {
                        _disableStartStopButton = true;
                      });
                    },
                    child: Text(
                      "Stop",
                      style: GoogleFonts.poppins(
                        fontSize: 17.5,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 25,
                          top: 65,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 75),
                              child: Text(
                                "Speed",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Transform.rotate(
                              angle: -90 * math.pi / 180,
                              child: Slider(
                                value: _speed,
                                label: "${_speed.round()}%",
                                min: 0,
                                max: 60,
                                onChanged: (speed) {
                                  setState(() {
                                    _speed = speed;
                                  });
                                },
                                onChangeEnd: (speed) {
                                  ConnectionManager.write({
                                    "command": "set_speed",
                                    "speed": speed.round(),
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(-50, 0),
                        child: ValueListenableBuilder<ControlButton>(
                          valueListenable: _currentControlButton,
                          builder: (context, currentControlButton, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTapDown: (_) {
                                    if (currentControlButton.isNotNone) return;

                                    ConnectionManager.write(
                                        {"command": "move_forward"});
                                    setState(() {
                                      _currentControlButton.value =
                                          ControlButton.moveForward;
                                    });
                                  },
                                  onTapUp: (_) {
                                    if (!currentControlButton.isMoveForward) {
                                      return;
                                    }

                                    ConnectionManager.write(
                                        {"command": "stop"});
                                  },
                                  onTapCancel: () {
                                    if (!currentControlButton.isMoveForward) {
                                      return;
                                    }

                                    ConnectionManager.write(
                                        {"command": "stop"});
                                  },
                                  child: Icon(
                                    CupertinoIcons.triangle,
                                    size: SizeConfig.defaultSize * 4,
                                    color: currentControlButton.isMoveForward
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).iconTheme.color,
                                  ),
                                ),
                                const SizedBox(
                                  height: 50,
                                ),
                                GestureDetector(
                                  onTapDown: (_) {
                                    if (currentControlButton.isNotNone) return;

                                    ConnectionManager.write(
                                        {"command": "move_backward"});
                                    setState(() {
                                      _currentControlButton.value =
                                          ControlButton.moveBackward;
                                    });
                                  },
                                  onTapUp: (_) {
                                    if (!currentControlButton.isMoveBackward) {
                                      return;
                                    }

                                    ConnectionManager.write(
                                        {"command": "stop"});
                                  },
                                  onTapCancel: () {
                                    if (!currentControlButton.isMoveBackward) {
                                      return;
                                    }

                                    ConnectionManager.write(
                                        {"command": "stop"});
                                  },
                                  child: Transform.rotate(
                                    angle: math.pi,
                                    child: Icon(
                                      CupertinoIcons.triangle,
                                      size: SizeConfig.defaultSize * 4,
                                      color: currentControlButton.isMoveBackward
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).iconTheme.color,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(right: 125),
                        child: ValueListenableBuilder<ControlButton>(
                          valueListenable: _currentControlButton,
                          builder: (context, currentControlButton, _) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTapDown: (_) {
                                    if (currentControlButton.isNotNone) return;

                                    ConnectionManager.write(
                                        {"command": "turn_left"});
                                    setState(() {
                                      _currentControlButton.value =
                                          ControlButton.turnLeft;
                                    });
                                  },
                                  onTapUp: (_) {
                                    if (!currentControlButton.isTurnLeft) {
                                      return;
                                    }

                                    ConnectionManager.write(
                                        {"command": "stop"});
                                  },
                                  onTapCancel: () {
                                    if (!currentControlButton.isTurnLeft) {
                                      return;
                                    }

                                    ConnectionManager.write(
                                        {"command": "stop"});
                                  },
                                  child: Transform.rotate(
                                    angle: -math.pi / 2,
                                    child: Icon(
                                      CupertinoIcons.triangle,
                                      size: SizeConfig.defaultSize * 4,
                                      color: currentControlButton.isTurnLeft
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).iconTheme.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 50,
                                ),
                                GestureDetector(
                                  onTapDown: (_) {
                                    if (currentControlButton.isNotNone) return;

                                    ConnectionManager.write(
                                        {"command": "turn_right"});
                                    setState(() {
                                      _currentControlButton.value =
                                          ControlButton.turnRight;
                                    });
                                  },
                                  onTapUp: (_) {
                                    if (!currentControlButton.isTurnRight) {
                                      return;
                                    }

                                    ConnectionManager.write(
                                        {"command": "stop"});
                                  },
                                  onTapCancel: () {
                                    if (!currentControlButton.isTurnRight) {
                                      return;
                                    }

                                    ConnectionManager.write(
                                        {"command": "stop"});
                                  },
                                  child: Transform.rotate(
                                    angle: math.pi / 2,
                                    child: Icon(
                                      CupertinoIcons.triangle,
                                      size: SizeConfig.defaultSize * 4,
                                      color: currentControlButton.isTurnRight
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).iconTheme.color,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 127.5, top: 25),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Main brush",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Tooltip(
                                showDuration: const Duration(
                                  seconds: 1,
                                  milliseconds: 500,
                                ),
                                message: "Toggle main brush",
                                child: Switch.adaptive(
                                  value: _mainBrushEnabled,
                                  onChanged: (enabled) {
                                    ConnectionManager.write({
                                      "command": "set_brush",
                                      "brush": "main",
                                      "value": enabled,
                                    });

                                    setState(() {
                                      _mainBrushEnabled = enabled;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 25),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Side brush",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Tooltip(
                                  showDuration: const Duration(
                                    seconds: 1,
                                    milliseconds: 500,
                                  ),
                                  message: "Toggle side brush",
                                  child: Switch.adaptive(
                                    value: _sideBrushEnabled,
                                    onChanged: (enabled) {
                                      ConnectionManager.write({
                                        "command": "set_brush",
                                        "brush": "side",
                                        "value": enabled,
                                      });

                                      setState(() {
                                        _sideBrushEnabled = enabled;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Padding buildBodyPortrait(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, left: 25, right: 25),
      child: Column(
        children: [
          Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: AnimatedSwitcher(
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    duration: const Duration(milliseconds: 300),
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: _isCleaning
                        ? const Text(
                            "Status: Cleaning",
                            key: ValueKey("cleaning"),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                            ),
                          )
                        : const Text(
                            "Status: Inactive",
                            key: ValueKey("inactive"),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedSize(
                  alignment: Alignment.centerRight,
                  duration: const Duration(milliseconds: 300),
                  reverseDuration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                        Theme.of(context).primaryColor,
                      ),
                      foregroundColor: WidgetStateProperty.all<Color>(
                        Theme.of(context).scaffoldBackgroundColor,
                      ),
                      padding: WidgetStateProperty.all<EdgeInsets>(
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      ),
                      shape: WidgetStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (_disableStartStopButton) return;

                      final String command =
                          _isCleaning ? "stop_cleaning" : "start_cleaning";
                      ConnectionManager.write({"command": command});
                      setState(() {
                        _disableStartStopButton = true;
                      });
                    },
                    child: Text(
                      _isCleaning ? "Stop" : "Start cleaning",
                      style: GoogleFonts.poppins(
                        fontSize: 17.5,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Align(
              alignment: Alignment.centerLeft,
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
                child: _firmwareVersion == null
                    ? const SizedBox(
                        width: 350,
                        key: ValueKey("loading"),
                        child: Text(
                          "Firmware version: Loading...",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      )
                    : SizedBox(
                        width: 350,
                        key: ValueKey(_firmwareVersion),
                        child: Text(
                          "Firmware version: $_firmwareVersion",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 25,
                      right: 25,
                      bottom: 25,
                    ),
                    child: Text(
                      "Rotate your device to landscape mode to control the SmartSweep robot.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Icon(
                    FontAwesomeIcons.rotate,
                    size: 50,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

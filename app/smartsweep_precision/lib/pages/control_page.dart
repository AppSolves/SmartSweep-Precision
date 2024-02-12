import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartsweep_precision/config/connection.dart';
import 'package:smartsweep_precision/config/prints.dart';
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
  late final StreamSubscription<bool?> _connectionStateSubscription;
  late final StreamSubscription<bool> _bluetoothStateSubscription;
  late final StreamSubscription<Map<String, dynamic>>?
      _onValueArrivedSubscription;
  bool disconnectedManually = false;
  bool _isCleaning = false;
  bool _disableButton = false;

  @override
  void initState() {
    toggleWakelock(true);
    _connectionStateSubscription =
        ConnectionManager.onConnectionStateChanged.listen(
      (bool? isConnected) {
        if (isConnected == false && !disconnectedManually) {
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
        if (!isBluetoothEnabled) {
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
    ConnectionManager.write({"command": "request_cleaning_status"});
    super.initState();
  }

  void handleData(Map<String, dynamic> data) {
    printError(data);
    for (final String key in data.keys) {
      if (key == "is_cleaning") {
        setState(() {
          _isCleaning = data["is_cleaning"];
          _disableButton = false;
        });
      }
    }
  }

  @override
  void dispose() {
    toggleWakelock(false);
    _connectionStateSubscription.cancel();
    _bluetoothStateSubscription.cancel();
    _onValueArrivedSubscription?.cancel();
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
            if (!suddenDisconnection)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            TextButton(
              onPressed: () {
                if (!suddenDisconnection) ConnectionManager.disconnectAll();
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              child: Text(suddenDisconnection ? 'OK' : 'Disconnect'),
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
      onPopInvoked: (didPop) {
        if (didPop) return;

        setState(() {
          disconnectedManually = true;
        });
        showDisconnectionConfirmationDialog(
          context,
          widget.device.platformName,
        );
      },
      child: Scaffold(
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
                  disconnectedManually = true;
                });

                showDisconnectionConfirmationDialog(
                  context,
                  widget.device.platformName,
                );
              },
              tooltip: 'Back',
              icon: const BackIcon(),
            ),
          ),
        ),
        body: Padding(
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
                          backgroundColor: MaterialStateProperty.all<Color>(
                            Theme.of(context).primaryColor,
                          ),
                          foregroundColor: MaterialStateProperty.all<Color>(
                            Theme.of(context).scaffoldBackgroundColor,
                          ),
                          padding: MaterialStateProperty.all<EdgeInsets>(
                            const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                          ),
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        onPressed: () {
                          if (_disableButton) return;

                          final String command =
                              _isCleaning ? "stop_cleaning" : "start_cleaning";
                          ConnectionManager.write({"command": command});
                          setState(() {
                            _disableButton = true;
                          });
                        },
                        child: Text(
                          _isCleaning ? "Stop" : "Start cleaning",
                          style: GoogleFonts.poppins(
                            fontSize: 17.5,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

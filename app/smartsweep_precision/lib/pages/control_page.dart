import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
  bool isCleaning = false;

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
    super.initState();
  }

  void handleData(Map<String, dynamic> data) {
    printError(data);
    if (data.keys.contains("is_cleaning")) {
      setState(() {
        isCleaning = data["is_cleaning"];
      });
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Control Page',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  ConnectionManager.writeCharacteristic(
                    {"command": "start_cleaning"},
                  );
                },
                icon: const Icon(Icons.bluetooth),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

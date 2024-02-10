import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smartsweep_precision/config/connection.dart';
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
  @override
  void initState() {
    toggleWakelock(true);
    super.initState();
  }

  @override
  void dispose() {
    toggleWakelock(false);
    super.dispose();
  }

  void toggleWakelock(bool enable) async {
    await WakelockPlus.toggle(enable: enable);
  }

  void showDisconnectionConfirmationDialog(
    BuildContext context,
    String deviceName,
  ) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Disconnect'),
          content:
              Text("Are you sure you want to disconnect from '$deviceName'?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ConnectionManager.disconnectAll();
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              child: const Text('Disconnect'),
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

        showDisconnectionConfirmationDialog(
            context, widget.device.platformName);
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
        body: const Center(
          child: Text('Control Page'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:smartsweep_precision/config/connection.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
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

        final String deviceName =
            ConnectionManager.connectedDevices.first.platformName;

        showDisconnectionConfirmationDialog(context, deviceName);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Control Page'),
          centerTitle: true,
          leading: BackButton(
            style: ButtonStyle(
              iconSize: MaterialStateProperty.all(30),
            ),
            onPressed: () {
              final String deviceName =
                  ConnectionManager.connectedDevices.first.platformName;

              showDisconnectionConfirmationDialog(context, deviceName);
            },
          ),
        ),
        body: const Center(
          child: Text('Control Page'),
        ),
      ),
    );
  }
}

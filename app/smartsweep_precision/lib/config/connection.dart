import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartsweep_precision/config/themes.dart';

class ConnectionManager {
  static final Guid _serviceUUID = Guid("57b83ac1-34d0-418a-bf25-bfacd5d9ac3a");

  static bool get isConnected {
    return connectedDevices.isNotEmpty;
  }

  static List<BluetoothDevice> get connectedDevices {
    return FlutterBluePlus.connectedDevices;
  }

  static Future<bool> get isSupported async {
    return await FlutterBluePlus.isSupported;
  }

  static Stream<bool> get isScanning {
    return FlutterBluePlus.isScanning;
  }

  static Stream<List<ScanResult>> get scanResults {
    return FlutterBluePlus.onScanResults;
  }

  static void startScan({bool debug = false}) async {
    if (!(await permissionGranted) || isConnected) return;

    if (Platform.isAndroid &&
        FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off) {
      await FlutterBluePlus.turnOn();
    }

    disconnectAll();

    await FlutterBluePlus.startScan(
      withServices: debug ? [] : [_serviceUUID],
      timeout: const Duration(seconds: 10),
    );
  }

  static void stopScan() async {
    if (!(await permissionGranted) || isConnected) return;

    if (Platform.isAndroid &&
        FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off) {
      await FlutterBluePlus.turnOn();
    }

    await FlutterBluePlus.stopScan();
  }

  static void disconnectAll() async {
    if (!(await permissionGranted) || !isConnected) return;

    if (Platform.isAndroid &&
        FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off) {
      await FlutterBluePlus.turnOn();
    }

    for (final BluetoothDevice element in FlutterBluePlus.connectedDevices) {
      await element.disconnect(timeout: 10);
    }
  }

  static Future<bool> connect(
    BluetoothDevice device, {
    VoidCallback? onEstablishingConnection,
  }) async {
    if (!(await permissionGranted) || isConnected) return false;

    try {
      if (Platform.isAndroid &&
          FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off) {
        await FlutterBluePlus.turnOn();
      }

      await FlutterBluePlus.stopScan();

      if (onEstablishingConnection != null) onEstablishingConnection();

      await device.connect(
        timeout: const Duration(seconds: 10),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> get permissionGranted async {
    return await Permission.bluetoothConnect.isGranted;
  }

  static void initialize() async {
    while (![PermissionStatus.granted, PermissionStatus.permanentlyDenied]
        .contains(await Permission.bluetoothConnect.status)) {
      await Permission.bluetoothConnect.request();
    }

    if (await Permission.bluetoothConnect.status ==
        PermissionStatus.permanentlyDenied) {
      await openAppSettings();
    }
  }

  static void showPermissionDialog(BuildContext context) async {
    await showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Bluetooth Error'),
        content: const Text(
          'Please grant the Bluetooth permission and pair with the device to use the app.',
          style: TextStyle(
            fontSize: 17.5,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              Navigator.pop(context, 'OK');
              await openAppSettings();
            },
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 17.5,
                color: Themes.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartsweep_precision/config/prints.dart';
import 'package:smartsweep_precision/config/themes.dart';

class ConnectionManager {
  static final Guid _serviceUUID = Guid("57b83ac1-34d0-418a-bf25-bfacd5d9ac3a");
  static final Guid _characteristicUUID =
      Guid("57b83ac2-34d0-418a-bf25-bfacd5d9ac3a");

  static bool get isBluetoothEnabled {
    return FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
  }

  static Stream<bool> get onBluetoothStateChanged {
    return FlutterBluePlus.adapterState.map(
      (event) => event == BluetoothAdapterState.on,
    );
  }

  static bool get isConnected {
    return connectedDevice != null;
  }

  static BluetoothDevice? get connectedDevice {
    return FlutterBluePlus.connectedDevices.firstOrNull;
  }

  static Future<bool> get isSupported async {
    return await FlutterBluePlus.isSupported;
  }

  static Stream<bool> get isScanning {
    return FlutterBluePlus.isScanning;
  }

  static Stream<Map<String, dynamic>>? get onValueArrived {
    return connectedDevice?.servicesList
        .firstWhere((service) => service.uuid == _serviceUUID)
        .characteristics
        .firstWhere(
            (characteristic) => characteristic.uuid == _characteristicUUID)
        .onValueReceived
        .map(
          (data) => jsonDecode(
            utf8.decode(data),
          ),
        );
  }

  static Stream<bool?> get onConnectionStateChanged {
    bool lastState = isConnected;
    return Stream.periodic(
      const Duration(milliseconds: 100),
      (_) {
        final bool newState = isConnected;
        if (lastState != newState) {
          lastState = newState;
          return newState;
        }
        return null;
      },
    );
  }

  static Stream<List<ScanResult>> get scanResults {
    return FlutterBluePlus.onScanResults;
  }

  static void write(Map<String, dynamic> jsonValue) async {
    if (!(await permissionGranted) || !isConnected) return;

    if (Platform.isAndroid &&
        FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off) {
      await FlutterBluePlus.turnOn();
    }

    final List<BluetoothService> services = connectedDevice!.servicesList;

    for (final BluetoothService service in services) {
      if (service.uuid == _serviceUUID) {
        final List<BluetoothCharacteristic> characteristics =
            service.characteristics;
        for (final BluetoothCharacteristic characteristic in characteristics) {
          if (characteristic.uuid == _characteristicUUID) {
            final List<int> encoded =
                utf8.encode(jsonEncode(jsonValue)).toList();
            try {
              printError("Writing: '$encoded'");
              await characteristic.write(encoded);
            } catch (e) {
              printError(e);
            }
          }
        }
      }
    }
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
    int retries = 2,
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

      await device.discoverServices();
      device.onServicesReset.listen((_) async {
        await device.discoverServices();
      });

      final List<BluetoothService> services = device.servicesList;
      for (final BluetoothService service in services) {
        if (service.uuid == _serviceUUID) {
          final List<BluetoothCharacteristic> characteristics =
              service.characteristics;
          for (final BluetoothCharacteristic characteristic
              in characteristics) {
            if (characteristic.uuid == _characteristicUUID) {
              await characteristic.setNotifyValue(true);
            }
          }
        }
      }

      return true;
    } catch (_) {
      if (retries > 0) {
        return await connect(
          device,
          onEstablishingConnection: onEstablishingConnection,
          retries: retries - 1,
        );
      }
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

enum ControlButton {
  moveForward,
  moveBackward,
  turnLeft,
  turnRight,
  none,
}

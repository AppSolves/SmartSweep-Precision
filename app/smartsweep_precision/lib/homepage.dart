import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartsweep_precision/config/app_config.dart';
import 'package:smartsweep_precision/config/connection.dart';
import 'package:smartsweep_precision/config/custom_icons.dart';
import 'package:smartsweep_precision/config/themes.dart';
import 'package:smartsweep_precision/pages/control_page.dart';
import 'package:smartsweep_precision/widgets/jumping_dot_progress_indicator.dart';
import 'package:smartsweep_precision/widgets/navigation_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.poppedOnBoardingScreen,
  });

  final bool poppedOnBoardingScreen;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ScanResult> _scannedDevices = [];
  bool _isSupported = false;
  bool _isScanning = false;
  Map<String, dynamic> _connecting = {};
  bool _bluetoothActivated = ConnectionManager.isBluetoothEnabled;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<bool>? _bluetoothStateSubscription;

  @override
  void initState() {
    _configureConnection();

    if (!widget.poppedOnBoardingScreen) {
      FlutterNativeSplash.remove();
    }

    super.initState();
  }

  void _configureConnection() async {
    _isSupported = await ConnectionManager.isSupported;
    if (_isSupported) {
      _scanSubscription = ConnectionManager.scanResults.listen((results) {
        setState(() {
          _scannedDevices = results;
        });
      });
      _isScanningSubscription =
          ConnectionManager.isScanning.listen((isScanning) {
        setState(() {
          _isScanning = isScanning;
        });
      });
      _bluetoothStateSubscription =
          ConnectionManager.onBluetoothStateChanged.listen(
        (bool isBluetoothEnabled) {
          setState(() {
            _bluetoothActivated = isBluetoothEnabled;
          });
        },
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _bluetoothStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().initialize(context);
    return Scaffold(
      drawer: const NavigationDrawerWidget(),
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 5,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Text(
            "SmartSweep Precision",
            style: GoogleFonts.poppins(
              fontSize: 22.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return Themes.iconToIconButton(
              context,
              CustomIcons.custom_menu_icon,
              size: 30,
              offset: const Offset(10, 0),
              tooltip: "Menu",
              onPressed: Scaffold.of(context).openDrawer,
            );
          },
        ),
      ),
      body: Center(
        child: Stack(
          children: [
            if (_isSupported && _bluetoothActivated)
              Padding(
                padding: const EdgeInsets.only(right: 15, top: 10, bottom: 15),
                child: Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: 125,
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
                            vertical: 5,
                          ),
                        ),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      onPressed: () {
                        if (_isScanning) {
                          ConnectionManager.stopScan();
                        } else {
                          ConnectionManager.startScan();
                        }
                        setState(() {});
                      },
                      child: Text(
                        _isScanning ? "Stop" : "Scan",
                        style: GoogleFonts.poppins(
                          fontSize: 22.5,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            _isSupported && _bluetoothActivated
                ? _scannedDevices.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: ListView.builder(
                          itemCount: _scannedDevices.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.5),
                              child: ListTile(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(25),
                                  ),
                                ),
                                onTap: () async {
                                  final bool connected =
                                      await ConnectionManager.connect(
                                    _scannedDevices[index].device,
                                    onEstablishingConnection: () {
                                      setState(() {
                                        _connecting = {
                                          "device":
                                              _scannedDevices[index].device,
                                          "status": true,
                                        };
                                      });
                                    },
                                  );

                                  if (connected && mounted) {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ControlPage(
                                          device: _scannedDevices[index].device,
                                        ),
                                      ),
                                    );
                                  }

                                  setState(() {
                                    _connecting = {};
                                  });
                                },
                                title: Text(
                                  _scannedDevices[index].device.platformName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  _scannedDevices[index].device.remoteId.str,
                                  style: GoogleFonts.poppins(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                trailing: _connecting.isNotEmpty &&
                                        _connecting["device"] ==
                                            _scannedDevices[index].device
                                    ? SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: Transform.translate(
                                          offset: const Offset(0, -15),
                                          child: JumpingDotsProgressIndicator(
                                            color: Theme.of(context)
                                                .iconTheme
                                                .color,
                                            fontSize: 35,
                                          ),
                                        ),
                                      )
                                    : Transform.translate(
                                        offset: const Offset(10, 0),
                                        child: const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 25,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      )
                    : !_isScanning
                        ? Align(
                            alignment: Alignment.center,
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
                                    "Connect to your SmartSweep device by tapping the scan button.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.bluetooth_rounded,
                                  size: 50,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          )
                        : Container()
                : Align(
                    alignment: Alignment.center,
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
                            !_isSupported
                                ? "Bluetooth is not supported on this device."
                                : "Bluetooth is disabled.\nPlease enable it to use the app.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Icon(
                          Icons.bluetooth_disabled_rounded,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

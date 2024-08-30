import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartsweep_precision/config/app_config.dart';
import 'package:smartsweep_precision/config/connection.dart';
import 'package:smartsweep_precision/config/custom_icons.dart';
import 'package:smartsweep_precision/config/extensions.dart';
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
    _configureConnection().whenComplete(
      () {
        if (!widget.poppedOnBoardingScreen) {
          FlutterNativeSplash.remove();
        }
      },
    );

    super.initState();
  }

  Future<void> _configureConnection() async {
    _isSupported = await ConnectionManager.isSupported;
    if (_isSupported && mounted) {
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
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 500));
    }
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
        title: Text(
          "SmartSweep Precision",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) {
            return Themes.iconToIconButton(
              context,
              CustomIcons.custom_menu_icon,
              size: 30,
              backgroundColor: Colors.transparent,
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: _isSupported && _bluetoothActivated
                  ? Padding(
                      padding:
                          const EdgeInsets.only(right: 15, top: 10, bottom: 15),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: SizedBox(
                          width: 125,
                          child: TextButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Theme.of(context).primaryColor,
                              ),
                              foregroundColor: WidgetStateProperty.all<Color>(
                                Theme.of(context).scaffoldBackgroundColor,
                              ),
                              padding: WidgetStateProperty.all<EdgeInsets>(
                                const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                              ),
                              shape: WidgetStateProperty.all<OutlinedBorder>(
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
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeInOut,
                              switchOutCurve: Curves.easeInOut,
                              child: _isScanning
                                  ? Text(
                                      "Stop",
                                      key: const ValueKey("stop"),
                                      style: GoogleFonts.poppins(
                                        fontSize: 22.5,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : Text(
                                      "Scan",
                                      key: const ValueKey("scan"),
                                      style: GoogleFonts.poppins(
                                        fontSize: 22.5,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                if (child.key == const ValueKey("devices")) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: const Offset(0, 0),
                    ).animate(animation),
                    child: child,
                  );
                }

                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _isSupported && _bluetoothActivated
                  ? _scannedDevices.isNotEmpty
                      ? Padding(
                          key: const ValueKey("devices"),
                          padding: const EdgeInsets.only(top: 85),
                          child: PhysicalShape(
                            color: Theme.of(context)
                                .scaffoldBackgroundColor
                                .contrast(50),
                            clipper: ShapeBorderClipper(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 25,
                                    right: 25,
                                    top: 5,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${_scannedDevices.length} ${_scannedDevices.length == 1 ? "Device Found" : "Devices Found"}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: const Offset(0, -25),
                                        child: JumpingDotsProgressIndicator(
                                          color:
                                              Theme.of(context).iconTheme.color,
                                          fontSize: 50,
                                          render: _isScanning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -10),
                                  child: const Divider(
                                    color: Colors.grey,
                                    height: 20,
                                    thickness: 1.5,
                                    indent: 25,
                                    endIndent: 25,
                                  ),
                                ),
                                Expanded(
                                  child: Transform.translate(
                                    offset: const Offset(0, -10),
                                    child: ListView.builder(
                                      itemCount: _scannedDevices.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12.5,
                                          ),
                                          child: ListTile(
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(25),
                                              ),
                                            ),
                                            onTap: () async {
                                              final bool connected =
                                                  await ConnectionManager
                                                      .connect(
                                                _scannedDevices[index].device,
                                                onEstablishingConnection: () {
                                                  setState(() {
                                                    _connecting = {
                                                      "device":
                                                          _scannedDevices[index]
                                                              .device,
                                                      "status": true,
                                                    };
                                                  });
                                                },
                                              );

                                              if (connected &&
                                                  context.mounted) {
                                                await Navigator.of(context)
                                                    .push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ControlPage(
                                                      device:
                                                          _scannedDevices[index]
                                                              .device,
                                                    ),
                                                  ),
                                                );
                                              }

                                              setState(() {
                                                _connecting = {};
                                              });
                                            },
                                            title: Text(
                                              _scannedDevices[index]
                                                  .device
                                                  .platformName,
                                              style: GoogleFonts.poppins(
                                                fontSize: 22.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              "Address: ${_scannedDevices[index].device.remoteId.str}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 17.5,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            trailing: AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              switchInCurve: Curves.easeInOut,
                                              switchOutCurve: Curves.easeInOut,
                                              transitionBuilder:
                                                  (child, animation) {
                                                return ScaleTransition(
                                                  scale: animation,
                                                  child: child,
                                                );
                                              },
                                              child: _connecting.isNotEmpty &&
                                                      _connecting["device"] ==
                                                          _scannedDevices[index]
                                                              .device
                                                  ? SizedBox(
                                                      key: const ValueKey(
                                                          "connecting"),
                                                      width: 50,
                                                      height: 50,
                                                      child:
                                                          Transform.translate(
                                                        offset: const Offset(
                                                          10,
                                                          -15,
                                                        ),
                                                        child:
                                                            JumpingDotsProgressIndicator(
                                                          color:
                                                              Theme.of(context)
                                                                  .iconTheme
                                                                  .color,
                                                          fontSize: 35,
                                                        ),
                                                      ),
                                                    )
                                                  : SizedBox(
                                                      key: const ValueKey(
                                                          "arrow"),
                                                      width: 50,
                                                      height: 50,
                                                      child:
                                                          Transform.translate(
                                                        offset:
                                                            const Offset(15, 0),
                                                        child: const Icon(
                                                          Icons
                                                              .arrow_forward_ios_rounded,
                                                          size: 25,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : !_isScanning
                          ? Align(
                              key: const ValueKey("empty"),
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
                      key: const ValueKey("unsupported"),
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
            ),
          ],
        ),
      ),
    );
  }
}

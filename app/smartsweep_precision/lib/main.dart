import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:smartsweep_precision/config/app_config.dart';
import 'package:smartsweep_precision/config/connection.dart';
import 'package:smartsweep_precision/config/themes.dart';
import 'package:smartsweep_precision/homepage.dart';
import 'package:smartsweep_precision/pages/on_boarding_screen.dart';

void main() async {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  AppConfig().initialize();
  ConnectionManager.initialize();
  ConnectionManager.disconnectAll();
  Themes.initialize();
  final ThemeMode themeMode = await Themes.themeMode;
  Themes.setSystemUIOverlayStyle(themeMode: themeMode);
  final bool showOnboardingScreen =
      await OnBoardingScreenManager.showOnBoardingScreen;
  runApp(
    MainApp(
      showHome: !showOnboardingScreen,
      themeMode: themeMode,
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
    required this.showHome,
    required this.themeMode,
  });

  final bool showHome;
  final ThemeMode themeMode;

  @override
  State<MainApp> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  static late final ValueNotifier<ThemeMode> themeModeNotifier;

  @override
  void initState() {
    themeModeNotifier = ValueNotifier<ThemeMode>(widget.themeMode);
    super.initState();
  }

  @override
  void dispose() {
    themeModeNotifier.dispose();
    super.dispose();
  }

  Widget buildHome() {
    if (widget.showHome) {
      return const HomePage(poppedOnBoardingScreen: false);
    }

    return const OnBoardingScreen(firstTime: true);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          title: 'SmartSweep Precision',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: Themes.lightTheme,
          darkTheme: Themes.darkTheme,
          home: buildHome(),
        );
      },
    );
  }
}

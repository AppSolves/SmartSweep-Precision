import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:smartsweep_precision/config/app_config.dart';
import 'package:smartsweep_precision/config/connection.dart';
import 'package:smartsweep_precision/config/themes.dart';
import 'package:smartsweep_precision/homepage.dart';
import 'package:smartsweep_precision/pages/control_page.dart';

void main() {
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  ConnectionManager.initialize();
  AppConfig().initialize();
  Themes.initialize();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSweep Precision',
      debugShowCheckedModeBanner: false,
      theme: Themes.lightTheme,
      darkTheme: Themes.darkTheme,
      routes: {
        '/': (context) => const HomePage(),
        '/control': (context) => const ControlPage(),
      },
    );
  }
}

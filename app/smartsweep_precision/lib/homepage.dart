import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartsweep_precision/config/custom_icons.dart';
import 'package:smartsweep_precision/config/themes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    FlutterNativeSplash.remove();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 5,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "SmartSweep Precision",
          style: GoogleFonts.poppins(
            fontSize: 22.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Builder(
          builder: (context) {
            return Themes.iconToIconButton(
              context,
              CustomIcons.custom_menu_icon,
              size: 40,
              iconOffset: const Offset(-1, 1),
              offset: const Offset(15, 0),
              tooltip: "Menu",
              onPressed: Scaffold.of(context).openDrawer,
            );
          },
        ),
      ),
      body: const Center(
        child: Column(
          children: [],
        ),
      ),
    );
  }
}

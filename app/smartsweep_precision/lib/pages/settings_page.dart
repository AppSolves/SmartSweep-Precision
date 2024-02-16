import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartsweep_precision/config/extensions.dart';
import 'package:smartsweep_precision/config/themes.dart';
import 'package:smartsweep_precision/main.dart';
import 'package:smartsweep_precision/widgets/back_icon.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Padding buildSettingsTile({
    String title = "Settings",
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Align(
        alignment: Alignment.center,
        child: ListTile(
          onTap: onTap,
          leading: leading,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(25),
            ),
          ),
          title: Text(
            title,
            textAlign: TextAlign.start,
            style: GoogleFonts.poppins(
              fontSize: 17.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: trailing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
            icon: const BackIcon(
              offset: Offset(-2.5, 0),
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Column(
            children: <Widget>[
              ValueListenableBuilder<ThemeMode>(
                valueListenable: MainAppState.themeModeNotifier,
                builder: (context, themeMode, _) {
                  return buildSettingsTile(
                    title: "Theme",
                    leading: Icon(
                      themeMode == ThemeMode.system
                          ? Themes.platformBrightness == Brightness.light
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined
                          : themeMode == ThemeMode.light
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                    ),
                    trailing: Text(
                      themeMode.name.capitalize(),
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Themes.showThemeSelectionDialog(context),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

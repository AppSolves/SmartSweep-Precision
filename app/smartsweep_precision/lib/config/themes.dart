import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartsweep_precision/config/extensions.dart';
import 'package:smartsweep_precision/config/settings_manager.dart';
import 'package:smartsweep_precision/main.dart';
import 'package:smartsweep_precision/pages/on_boarding_screen.dart';

class Themes {
  static void initialize() {
    PlatformDispatcher.instance.onPlatformBrightnessChanged =
        setSystemUIOverlayStyle;
  }

  static const darkModeColor = Color(0xFF121212);
  static const lightModeColor = Colors.white;
  static const primaryColor = Color.fromARGB(255, 120, 70, 255);
  static const textFieldBorderColor = primaryColor;
  static Color get contrastBackgroundColor {
    return platformBrightness == Brightness.dark
        ? darkModeColor.lighter(25)
        : lightModeColor.darker(25);
  }

  static Color get reverseTextAndIconColor {
    return platformBrightness == Brightness.dark ? Colors.black : Colors.white;
  }

  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: darkModeColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      tabBarTheme: TabBarTheme(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: primaryColor,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.2),
        thickness: 1.5,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF161616),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        displayMedium: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF161616),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: GoogleFonts.poppins(
            color: primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkModeColor,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.white,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: lightModeColor,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(),
      iconTheme: const IconThemeData(
        color: Colors.black,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      tabBarTheme: TabBarTheme(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: primaryColor,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withOpacity(0.2),
        thickness: 1.5,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        displayMedium: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 26,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: GoogleFonts.poppins(
            color: primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightModeColor,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.black,
      ),
    );
  }

  static Size textSize(Text text) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text.data, style: text.style),
        maxLines: text.maxLines ?? 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  static Size widgetSize(Widget widget) {
    if (widget.key == null) {
      return Size.zero;
    }

    if (widget.key is! GlobalKey) {
      return Size.zero;
    }

    if ((widget.key! as GlobalKey).currentContext == null) {
      return Size.zero;
    }

    final RenderBox renderBox = (widget.key! as GlobalKey)
        .currentContext!
        .findRenderObject() as RenderBox;
    return renderBox.size;
  }

  static Color hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  static Transform iconToText(
    BuildContext context,
    IconData icon, {
    Color? color,
    double? size,
    Offset offset = const Offset(0, 0),
  }) {
    return Transform.translate(
      offset: offset,
      child: Text(
        String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
          inherit: false,
          fontSize: size ?? 25,
          fontWeight: FontWeight.w600,
          fontFamily: icon.fontFamily,
        ),
      ),
    );
  }

  static Transform iconToIconButton(
    BuildContext context,
    dynamic icon, {
    Key? key,
    AlignmentGeometry? alignment,
    double? size,
    double? iconButtonSize,
    Color? backgroundColor,
    Offset? iconOffset,
    Offset? offset,
    EdgeInsetsGeometry? padding,
    String? tooltip,
    required void Function()? onPressed,
  }) {
    assert(icon is IconData || icon is Widget);
    assert(iconButtonSize == null || iconButtonSize >= 0);
    assert(size == null || size >= 0);
    return Transform.translate(
      key: key,
      offset: offset ?? const Offset(0, 0),
      child: Align(
        alignment: alignment ?? Alignment.center,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(0),
          child: IconButton(
            iconSize: iconButtonSize ?? 40,
            icon: CircleAvatar(
              radius: iconButtonSize != null ? iconButtonSize / 2 : 20,
              backgroundColor: backgroundColor ??
                  (platformBrightness == Brightness.dark
                      ? Colors.white24
                      : Colors.black26),
              child: Transform.translate(
                offset: iconOffset ?? const Offset(0, 0),
                child: (icon is IconData
                    ? iconToText(context, icon,
                        size: size ?? (iconButtonSize ?? 40) / 1.75)
                    : icon),
              ),
            ),
            splashRadius: 25,
            tooltip: tooltip,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  static Transform textButton({
    Key? key,
    Widget? child,
    AlignmentGeometry? alignment,
    ButtonStyle? style,
    MaterialStateProperty<OutlinedBorder?>? shape,
    Offset? childOffset,
    Offset? offset,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? childPadding,
    String? tooltip,
    bool expand = false,
    required void Function()? onPressed,
    void Function()? onLongPress,
  }) {
    final TextButton button = TextButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: style ??
          ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
              primaryColor,
            ),
            shape: shape ??
                MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
          ),
      child: Transform.translate(
        offset: childOffset ?? const Offset(0, 0),
        child: Padding(
          padding: childPadding ?? const EdgeInsets.all(0),
          child: child,
        ),
      ),
    );

    final buttonChild = onLongPress == null && tooltip != null
        ? Tooltip(
            message: tooltip,
            child: button,
          )
        : button;

    return Transform.translate(
      key: key,
      offset: offset ?? const Offset(0, 0),
      child: Align(
        alignment: alignment ?? Alignment.center,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(0),
          child: expand
              ? SizedBox.expand(
                  child: buttonChild,
                )
              : buttonChild,
        ),
      ),
    );
  }

  static Brightness get platformBrightness {
    return PlatformDispatcher.instance.platformBrightness;
  }

  static void changeThemeMode(ThemeMode themeMode) async {
    MainAppState.themeModeNotifier.value = themeMode;
    final File file = await SettingsManager.settingsFile;
    final bool showOnBoardingScreenNextTimeAgain =
        await OnBoardingScreenManager.showOnBoardingScreen;
    final String data = jsonEncode(
      {
        "showOnBoardingScreenNextTimeAgain": showOnBoardingScreenNextTimeAgain,
        "themeMode": (themeMode == ThemeMode.dark
            ? "dark"
            : themeMode == ThemeMode.light
                ? "light"
                : "system"),
      },
    );
    file.writeAsStringSync(data);

    setSystemUIOverlayStyle(themeMode: themeMode);
  }

  static void setSystemUIOverlayStyle({ThemeMode? themeMode}) {
    final ThemeMode appThemeMode =
        themeMode ?? MainAppState.themeModeNotifier.value;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: appThemeMode == ThemeMode.dark
            ? darkModeColor
            : appThemeMode == ThemeMode.light
                ? Colors.white
                : platformBrightness == Brightness.dark
                    ? darkModeColor
                    : Colors.white,
        systemNavigationBarIconBrightness: appThemeMode == ThemeMode.dark
            ? Brightness.light
            : appThemeMode == ThemeMode.light
                ? Brightness.dark
                : platformBrightness == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark,
      ),
    );
  }

  static Future<ThemeMode> get themeMode async {
    final File file = await SettingsManager.settingsFile;
    final String contents = file.readAsStringSync();
    try {
      final dynamic jsonResponse = jsonDecode(contents);

      if (jsonResponse["themeMode"] == "dark") {
        return ThemeMode.dark;
      }
      if (jsonResponse["themeMode"] == "light") {
        return ThemeMode.light;
      }
      return ThemeMode.system;
    } catch (_) {
      return ThemeMode.system;
    }
  }

  static void showThemeSelectionDialog(BuildContext context) {
    final ThemeMode themeMode = MainAppState.themeModeNotifier.value;
    if (!context.mounted) return;

    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Select theme'),
        content: null,
        actions: <Widget>[
          SimpleDialogOption(
            onPressed: () {
              changeThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                if (themeMode == ThemeMode.light)
                  iconToText(
                    context,
                    Icons.check,
                    color: Colors.green,
                    offset: const Offset(-10, 0),
                  ),
                const Spacer(),
                const Text(
                  "Light",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              changeThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                if (themeMode == ThemeMode.dark)
                  iconToText(
                    context,
                    Icons.check,
                    color: Colors.green,
                    offset: const Offset(-10, 0),
                  ),
                const Spacer(),
                const Text(
                  "Dark",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              changeThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                if (themeMode == ThemeMode.system)
                  iconToText(
                    context,
                    Icons.check,
                    color: Colors.green,
                    offset: const Offset(-10, 0),
                  ),
                const Spacer(),
                const Text(
                  "System",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          textButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.only(top: 30),
          ),
        ],
      ),
    );
  }
}

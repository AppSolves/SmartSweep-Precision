import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lottie/lottie.dart';
import 'package:smartsweep_precision/config/app_config.dart';
import 'package:smartsweep_precision/config/connection.dart';
import 'package:smartsweep_precision/config/settings_manager.dart';
import 'package:smartsweep_precision/config/themes.dart';
import 'package:smartsweep_precision/homepage.dart';
import 'package:smartsweep_precision/main.dart';
import 'package:smartsweep_precision/widgets/back_icon.dart';
import 'package:smartsweep_precision/widgets/page_dot_indicator.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({
    super.key,
  });

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController(
    initialPage: 0,
  );
  int _pageIndex = 0;

  final List<_OnBoard> data = [
    _OnBoard(
      animation: "assets/anims/welcome.json",
      title: "Welcome!",
      scale: 1.25,
      description:
          "Welcome to SmartSweep Precision, where innovation meets cleanliness!\n\nJoin us on this journey towards a smarter, cleaner world.",
    ),
    _OnBoard(
      animation: "assets/anims/introduction.json",
      title: "Introduction",
      scale: 1.175,
      description:
          "Experience the future of automated cleaning with our Arduino Giga-powered robot and the cutting-edge technology of SmartSweep Precision.",
    ),
    _OnBoard(
      animation: "assets/anims/connection.json",
      title: "Establish connection",
      scale: 1.175,
      description:
          "Establish a seamless connection between your device and SmartSweep Precision. Follow the simple steps to ensure a smooth and efficient cleaning experience.",
    ),
    _OnBoard(
      animation: "assets/anims/features.json",
      title: "Features",
      scale: 1.175,
      description:
          "Explore precision navigation, remote control, status tracking and more - all within the grasp of our powerful feature set.",
    ),
    _OnBoard(
      animation: "assets/anims/ready.json",
      title: "Ready to clean?",
      scale: 1.175,
      description:
          "Congratulations! Your SmartSweep Precision is now ready to embark on its cleaning mission. Sit back, relax, and let the intelligent cleaning prowess take over.",
    ),
  ];

  bool get isLastPage {
    return data.length == _pageIndex + 1;
  }

  bool get isFirstPage {
    return _pageIndex == 0;
  }

  int get getLastPageIndex {
    return data.length - 1;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (!await ConnectionManager.permissionGranted && mounted) {
        ConnectionManager.showPermissionDialog(context);
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    FlutterNativeSplash.remove();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildBody(),
    );
  }

  int get indexDifference {
    return getLastPageIndex - _pageIndex;
  }

  Duration get animateToLastPage {
    return Duration(
      milliseconds: 300 * indexDifference,
    );
  }

  SafeArea buildBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildSkipButton(),
            buildPageView(),
            buildButtonsWithDotIndicator(),
          ],
        ),
      ),
    );
  }

  Padding buildSkipButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              getLastPageIndex,
              duration: animateToLastPage,
              curve: Curves.easeInOut,
            );
          },
          child: const Text(
            "Skip",
            style: TextStyle(
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Expanded buildPageView() {
    return Expanded(
      child: PageView.builder(
        itemCount: data.length,
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        itemBuilder: (context, index) => _OnBoardContent(
          animation: data[index].animation,
          title: data[index].title,
          description: data[index].description,
          pageIndex: index,
          scale: data[index].scale,
        ),
      ),
    );
  }

  Row buildButtonsWithDotIndicator() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: SizedBox(
            height: 60,
            width: 60,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: isFirstPage
                  ? null
                  : SizedBox(
                      width: 60,
                      height: 60,
                      child: _OnBoardingButton(
                        pageController: _pageController,
                        isForwardButton: false,
                        isLastPage: isLastPage,
                      ),
                    ),
            ),
          ),
        ),
        const Spacer(),
        ...List<Padding>.generate(
          data.length,
          (index) => Padding(
            padding: const EdgeInsets.only(
              right: 4,
            ),
            child: PageDotIndicator(
              isActive: index == _pageIndex,
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SizedBox(
            height: 60,
            width: isLastPage ? 125 : 60,
            child: _OnBoardingButton(
              pageController: _pageController,
              isForwardButton: true,
              isLastPage: isLastPage,
            ),
          ),
        ),
      ],
    );
  }
}

class _OnBoardingButton extends StatelessWidget {
  const _OnBoardingButton({
    required PageController pageController,
    required this.isForwardButton,
    required this.isLastPage,
  }) : _pageController = pageController;

  final PageController _pageController;
  final bool isForwardButton;
  final bool isLastPage;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 200,
      ),
      curve: Curves.easeInOut,
      height: 60,
      width: isForwardButton
          ? isLastPage
              ? 125
              : 60
          : 60,
      child: ElevatedButton(
        onPressed: () {
          if (isForwardButton) {
            if (!isLastPage) {
              _pageController.nextPage(
                duration: const Duration(
                  milliseconds: 300,
                ),
                curve: Curves.easeInOut,
              );
            } else {
              OnBoardingScreenManager.writeToFile();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomePage(
                    poppedOnBoardingScreen: true,
                  ),
                ),
              );
            }
          } else {
            _pageController.previousPage(
              duration: const Duration(
                milliseconds: 300,
              ),
              curve: Curves.easeInOut,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Themes.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              16,
            ),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 300,
          ),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: isForwardButton
              ? isLastPage
                  ? Text(
                      "Get Started",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13 * (SizeConfig.defaultSize / 10.5),
                          fontWeight: FontWeight.w800),
                    )
                  : BackIcon(
                      isReverse: isForwardButton,
                      offset: const Offset(-10, 0),
                    )
              : BackIcon(
                  isReverse: isForwardButton,
                  offset: const Offset(-10, 0),
                ),
        ),
      ),
    );
  }
}

class _OnBoard {
  _OnBoard({
    required this.animation,
    required this.title,
    required this.description,
    this.scale = 1.0,
  });

  final String animation, title, description;
  final double scale;
}

class _OnBoardContent extends StatelessWidget {
  const _OnBoardContent({
    required this.animation,
    required this.title,
    required this.description,
    required this.pageIndex,
    this.scale = 1.0,
  });

  final String animation, title, description;
  final int pageIndex;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(
          flex: 2,
        ),
        Center(
          child: Lottie.asset(
            animation,
            repeat: true,
            height: 300 * scale,
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pageIndex == 4 ? 20 : 40),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22.5,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        const Spacer(
          flex: 2,
        ),
      ],
    );
  }
}

class OnBoardingScreenManager {
  static Future<bool> get showOnBoardingScreen async {
    final file = await SettingsManager.settingsFile;
    String contents = await file.readAsString();
    try {
      var jsonResponse = jsonDecode(contents);

      return jsonResponse["showOnBoardingScreenNextTimeAgain"];
    } catch (_) {
      return true;
    }
  }

  static void writeToFile({
    bool showOnboardingScreenNextTimeAgain = false,
  }) async {
    final ThemeMode themeMode = MainAppState.themeModeNotifier.value;
    final File file = await SettingsManager.settingsFile;
    final String data = jsonEncode(
      {
        "showOnBoardingScreenNextTimeAgain": showOnboardingScreenNextTimeAgain,
        "themeMode": themeMode == ThemeMode.dark
            ? "dark"
            : themeMode == ThemeMode.light
                ? "light"
                : "system",
      },
    );
    file.writeAsStringSync(data);
  }
}

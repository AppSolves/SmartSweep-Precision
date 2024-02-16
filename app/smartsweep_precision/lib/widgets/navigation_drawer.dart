import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartsweep_precision/config/app_config.dart';
import 'package:smartsweep_precision/config/custom_icons.dart';
import 'package:smartsweep_precision/config/extensions.dart';
import 'package:smartsweep_precision/config/themes.dart';
import 'package:smartsweep_precision/pages/on_boarding_screen.dart';
import 'package:smartsweep_precision/pages/privacy_policy.dart';
import 'package:smartsweep_precision/pages/settings_page.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationDrawerWidget extends StatefulWidget {
  const NavigationDrawerWidget({
    super.key,
  });

  @override
  State<NavigationDrawerWidget> createState() => _NavigationDrawerState();
}

class _NavigationDrawerState extends State<NavigationDrawerWidget> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().initialize(context);
    return Drawer(
      width: SizeConfig.screenWidth * 0.8,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 45),
          ListTile(
            title: Text(
              'General',
              textAlign: TextAlign.start,
              style: GoogleFonts.poppins(
                fontSize: 17.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Transform.translate(
              offset: const Offset(20, 0),
              child: IconButton(
                tooltip: "Close",
                icon: Icon(
                  Icons.close_rounded,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          const Divider(),
          const SizedBox(height: 10),
          buildMenuItem(
            heading: "Settings",
            icon: const Icon(
              Icons.settings_outlined,
              size: 25,
            ),
            text: 'Configure the app',
            onClicked: () => selectedItem(context, 0),
          ),
          const SizedBox(height: 10),
          buildMenuItem(
            heading: "Product Page",
            icon: const Icon(FontAwesomeIcons.productHunt),
            text: 'View product page',
            onClicked: () => selectedItem(context, 1),
          ),
          const SizedBox(height: 10),
          buildMenuItem(
            heading: "Onboarding",
            icon: const Icon(FontAwesomeIcons.user),
            text: 'Show onboarding screen',
            onClicked: () => selectedItem(context, 2),
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          buildMenuItem(
            heading: "Privacy Policy",
            text: "Privacy Policy and Terms & Conditions",
            icon: const Icon(
              Icons.privacy_tip_outlined,
              size: 27.5,
            ),
            onClicked: () => selectedItem(context, 3),
          ),
          const SizedBox(height: 10),
          buildMenuItem(
            heading: "About",
            text: AppConfig.appName,
            icon: const Icon(
              Icons.info_outline_rounded,
              size: 27.5,
            ),
            onClicked: () => selectedItem(context, 4),
          ),
        ],
      ),
    );
  }

  ListTile buildMenuItem({
    required String heading,
    Icon? icon,
    Widget? leading,
    Widget? trailing,
    String? text,
    VoidCallback? onClicked,
    bool isAccountItem = false,
  }) {
    return ListTile(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(25),
        ),
      ),
      trailing: trailing,
      leading: icon ??
          Transform.translate(
            offset: const Offset(-7.5, 0),
            child: leading,
          ),
      title: Text(
        isAccountItem ? heading.correctEllipsis() : heading,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 17.5,
            ),
      ),
      subtitle: text != null
          ? Text(
              isAccountItem ? text.correctEllipsis() : text,
              maxLines: isAccountItem ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 15,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(
                          0.6,
                        ),
                  ),
            )
          : null,
      onTap: onClicked,
    );
  }

  void selectedItem(
    BuildContext context,
    int index,
  ) async {
    Navigator.of(context).pop();

    switch (index) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => const SettingsPage(),
          ),
        );
        break;
      case 1:
        if (await canLaunchUrl(AppConfig.productPageUrl)) {
          await launchUrl(AppConfig.productPageUrl);
        }

        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => const OnBoardingScreen(),
          ),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => const PrivacyPolicyPage(),
          ),
        );
        break;
      case 4:
        showCustomAboutDialog();
        break;
    }
  }

  void showCustomAboutDialog() {
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => CustomInfoDialog(
        icon: CustomIcons.appIcon(
          size: const Size(45, 45),
          color: Theme.of(context).iconTheme.color,
        ),
        name: AppConfig.appName,
        version: "v${AppConfig.version}",
        applicationLegalese: AppConfig.legalese,
      ),
    );
  }
}

class CustomInfoDialog extends StatelessWidget {
  const CustomInfoDialog({
    super.key,
    required this.icon,
    required this.name,
    required this.version,
    required this.applicationLegalese,
  });

  final Widget icon;
  final String name;
  final String version;
  final String applicationLegalese;

  static const double _textVerticalSeparation = 18.0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: ListBody(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Transform.translate(
                  offset: const Offset(0, 10),
                  child: icon,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 25,
                    ),
                    child: ListBody(
                      children: <Widget>[
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          version,
                        ),
                        const SizedBox(height: _textVerticalSeparation),
                        Text(
                          applicationLegalese,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          Themes.textButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Close',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.only(top: 30),
          ),
        ],
        scrollable: true,
      ),
    );
  }
}

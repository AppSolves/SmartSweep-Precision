import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:smartsweep_precision/config/app_config.dart';
import 'package:smartsweep_precision/config/extensions.dart';
import 'package:smartsweep_precision/config/themes.dart';
import 'package:smartsweep_precision/widgets/back_icon.dart';
import 'package:smartsweep_precision/widgets/jumping_dot_progress_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({
    super.key,
  });

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().initialize(context);
    TextStyle? linkStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Themes.primaryColor, fontSize: 20);
    return Scaffold(
      appBar: buildAppBar(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Icon(
                Icons.privacy_tip_outlined,
                size: SizeConfig.defaultSize * 15,
                color: Themes.primaryColor,
              ),
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 20,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'By using this app, you agree to the\n',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 20),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return showText(
                              context,
                              "privacy_policy.md",
                            );
                          },
                        );
                      },
                  ),
                  TextSpan(
                    text: ' and to the\n',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 20),
                  ),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return showText(
                              context,
                              "tac.md",
                            );
                          },
                        );
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: IconButton(
          tooltip: 'Back',
          icon: const BackIcon(
            size: -1,
            offset: Offset(-2.5, 0),
          ),
          iconSize: SizeConfig.defaultSize * 3,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      title: Text(
        "Privacy Policy and T&C".correctEllipsis(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Dialog showText(BuildContext context, String name) {
    return Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 10, top: 10),
              child: IconButton(
                tooltip: 'Close',
                icon:
                    Icon(Icons.close_rounded, size: SizeConfig.defaultSize * 3),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: rootBundle.loadString('assets/files/$name'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Markdown(
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(
                      p: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: 15.0,
                            fontWeight: FontWeight.normal,
                          ),
                      listBullet:
                          Theme.of(context).textTheme.bodyLarge!.copyWith(
                                fontSize: 15.0,
                                fontWeight: FontWeight.normal,
                              ),
                    ),
                    data: snapshot.data.toString(),
                    onTapLink: (text, url, title) async {
                      final Uri uri = Uri.parse(url!);

                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  );
                }
                return const Center(
                  child: JumpingDotsProgressIndicator(
                    fontSize: 50,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

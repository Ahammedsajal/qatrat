import 'dart:async';
import 'package:customer/Helper/Color.dart';
import 'package:customer/Helper/Session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Helper/String.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/SimpleAppBar.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';
import '../app/api_language.dart';

class PrivacyScreen extends StatefulWidget {
  final String? title;
  final String contentType;

  const PrivacyScreen({super.key, this.title, required this.contentType});

  static Route route(RouteSettings settings) {
    final Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) => PrivacyScreen(
        title: arguments?['title'],
        contentType: arguments?['type'],
      ),
    );
  }

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isNetworkAvail = true;
  String? content;
  AnimationController? buttonController;
  Animation? buttonSqueezeanimation;

  @override
  void initState() {
    super.initState();
    getSetting();

    buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController!,
        curve: const Interval(0.0, 0.150),
      ),
    );
  }

  Future<void> getSetting() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        final parameter = {TYPE: widget.contentType};
        final getdata = await apiBaseHelper.postAPICall(getSettingApi, parameter);
        final bool error = getdata["error"];
        if (!error) {
          String rawContent = getdata["data"][widget.contentType][0].toString();

          Locale currentLocale = Localizations.localeOf(context);
          if (currentLocale.languageCode != 'en') {
            rawContent = await translateDynamicText(rawContent, currentLocale.languageCode);
          }

          content = rawContent;
        } else {
          setSnackbar(getdata["message"], context);
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {
      return;
    }
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();
              Future.delayed(const Duration(seconds: 2)).then((_) async {
                _isNetworkAvail = await isNetworkAvailable();
                if (_isNetworkAvail) {
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(builder: (BuildContext context) => super.widget),
                  );
                } else {
                  await buttonController!.reverse();
                  if (mounted) {
                    setState(() {
                      getSetting();
                    });
                  }
                }
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    buttonController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultTitle = getTranslated(context, 'PRIVACY') ?? 'Privacy Policy';

    return _isLoading
        ? Scaffold(
            appBar: getSimpleAppBar(widget.title ?? defaultTitle, context),
            body: getProgress(context),
          )
        : _isNetworkAvail
            ? Scaffold(
                appBar: getSimpleAppBar(widget.title ?? defaultTitle, context),
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: HtmlWidget(
                      content ?? "",
                      onTapUrl: (url) async {
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                          return true;
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                      onErrorBuilder: (context, element, error) =>
                          Text('$element error: $error'),
                      onLoadingBuilder: (context, element, loadingProgress) =>
                          showCircularProgress(context, true, Theme.of(context).primaryColor),
                      textStyle: TextStyle(color: Theme.of(context).colorScheme.fontColor),
                    ),
                  ),
                ),
              )
            : Scaffold(
                appBar: getSimpleAppBar(widget.title ?? defaultTitle, context),
                body: noInternet(context),
              );
  }
}

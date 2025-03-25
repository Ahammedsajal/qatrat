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

class AboutUs extends StatefulWidget {
  final String? title;

  const AboutUs({Key? key, this.title}) : super(key: key);

  @override
  State<AboutUs> createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? content;

  @override
  void initState() {
    super.initState();
    getSetting();
  }

  Future<void> getSetting() async {
  final parameter = {TYPE: ABOUT_US};
  try {
    final getdata = await apiBaseHelper.postAPICall(getSettingApi, parameter);
    final bool error = getdata["error"];
    if (!error) {
      // Declare and initialize the rawContent variable.
      String rawContent = getdata["data"][ABOUT_US][0].toString();

      // Get the current locale from the context.
      Locale currentLocale = Localizations.localeOf(context);

      // Check if translation is necessary (assuming the API data is in English).
      if (currentLocale.languageCode != 'en') {
        rawContent = await translateDynamicText(rawContent, currentLocale.languageCode);
      }
      content = rawContent;
    } else {
      setSnackbar(getdata["message"], context);
    }
  } catch (error) {
    setSnackbar(error.toString(), context);
  }
  if (mounted) {
    setState(() {
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Build a custom app bar without the back button.
        automaticallyImplyLeading: false,
        title: Text(widget.title ?? getTranslated(context, 'ABOUT_LBL')!),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: HtmlWidget(
                  content ?? "",
                  onTapUrl: (url) async {
                    if (await canLaunchUrl(Uri.parse(url!))) {
                      await launchUrl(Uri.parse(url));
                      return true;
                    } else {
                      throw 'Could not launch $url';
                    }
                  },
                  onErrorBuilder: (context, element, error) => Text('$element error: $error'),
                  onLoadingBuilder: (context, element, loadingProgress) =>
                      showCircularProgress(context, true, Theme.of(context).primaryColor),
                  textStyle: TextStyle(color: Theme.of(context).colorScheme.fontColor),
                ),
              ),
            ),
    );
  }
}

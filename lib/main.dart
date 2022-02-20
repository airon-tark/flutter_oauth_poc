import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'log.dart';
import 'dart:io' show HttpServer;

/// Github oauth documentation is here
/// https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps

/// Client if from the github settings
/// You need to take it from your oauth provider
const clientId = 'cfef6067d4a97abb7ed1';

/// Client secret from the github settings
/// You need to take it from your oauth provider
const clientSecret = 'a30d729ce83b7d662ade840677258e267a24ba6f';

/// The first word in your redirect url,
/// If your redirect url looks like "foo://bar",
/// then schema should be called "foo". So this is the word before "://"
/// Right now we are using "tark" for the demonstration purposes
const callbackUrlScheme = 'tark';

/// Redirect url set in the github oauth settings
/// you can use whatever schema your want, for example foobar://anything
/// The main point is to set the first word of this uri to the AndroidManifest file
///
/// The schema better to be unique, for example "com.example" to prevent overlapping
/// with any application installed on the user device.
/// Redirect url should be set in the settings of your oauth provider
const redirectUri = '$callbackUrlScheme://callback';

/// The url of your web app login page.
/// The structure of the url will vary from provider to provider.
/// The current structure comes from the github rules
const githubAuthUrl = 'https://github.com/login/oauth/authorize'
    '?client_id=$clientId'
    '&redirect_uri=$redirectUri';

/// The url of your web app to get the token
/// The structure of the url will vary from provider to provider.
/// The current structure comes from the github rules
const githubTokenUrl = 'https://github.com/login/oauth/access_token'
    '?client_id=$clientId'
    '&client_secret=$clientSecret'
    '&code=';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'OAuth POC',
      home: MyHomePage(
        title: 'OAuth POC',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _result,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                child: const Text('Login with inner WebView'),
                onPressed: () => onAuthPressed(
                  innerWebView: true,
                ),
              ),
            ),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                child: const Text('Login with external browser'),
                onPressed: () => onAuthPressed(
                  innerWebView: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opening the auth web screen and pass inner/external browser parameter
  /// there.
  onAuthPressed({required bool innerWebView}) async {
    // we open the web sreen and awaiting for this answer
    // the web screen handle auth logic inside and return here
    // the answer in the unified format {code: xxx} or {error: xxx}
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => WebScreen(
          innerWebView: innerWebView,
        ),
      ),
    );

    // This happens if user press back button on the web screen
    // the returned object is null then
    if (result == null) {
      setState(() => _result = 'Authorization declined');
      return;
    }

    // if we have an error - show it
    if (result['error'] != null) {
      setState(() => _result = 'Error:\n${result['error']}');
      return;
    }

    // if we have a code - let's get the token then
    // the code mean authorization is successful and now
    // we need to get a token to work with API
    if (result['code'] != null) {
      final code = result['code'];

      // show everything is ok here
      setState(() {
        _result = 'Auth code:\n$code\ngetting token....';
      });

      // this is an artificial delay so you can see the difference
      // between "got code" and "got token" events
      // todo remove in production
      await Future.delayed(const Duration(seconds: 2));

      // getting the access token by sending the auth code
      // to the github API. This link will have another format
      // for your oauth provider
      final response = await http.get(
        Uri.parse('$githubTokenUrl$code'),
        headers: {
          'Accept': 'application/json',
        },
      );

      // parse the token
      final token = jsonDecode(response.body)['access_token'];

      // show it
      setState(() => _result = 'Token:\n$token');

      l('build', 'token', token);
    }
  }
}

/// Web screen that handles both inner web view and the opening of external browser
/// Using stateful widget, because we are opening the new screen in the init state
class WebScreen extends StatefulWidget {
  /// If false, we will open the external browser
  /// If true, the inner webview will be opened
  final bool innerWebView;

  const WebScreen({
    Key? key,
    this.innerWebView = true,
  }) : super(key: key);

  @override
  _WebScreenState createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  @override
  void initState() {
    if (!widget.innerWebView) {
      // if it set to use external browser, we open it right on screen start
      _authWithExternalWebView();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.innerWebView) {
      return Container(
        color: Colors.white,
      );
    }
    return RawKeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKey: (key) {
        // the proof that you can listen for the keyboard keys while user
        // using the inner web view.
        l('build', 'onKey', key);
      },
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.only(top: 48),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: WebView(
            initialUrl: githubAuthUrl,
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (NavigationRequest request) {
              // The way webview listening the URL changed (redirection)
              l('build', 'onUrlChange', request.url);

              // if the redirection url is our url, we then handle the response
              // which can be success or error
              if (request.url.startsWith(redirectUri)) {
                _handleAuthResponse(request.url);
                return NavigationDecision.prevent;
              }

              //Any other url works
              return NavigationDecision.navigate;
            },
          ),
        ),
      ),
    );
  }

  //

  _authWithExternalWebView() async {
    try {
      // auth with external browser performs by the 3rd party library
      // it has different way for Android and iOS
      // the library is https://pub.dev/packages/flutter_web_auth
      final result = await FlutterWebAuth.authenticate(
        url: githubAuthUrl,
        callbackUrlScheme: callbackUrlScheme,
      );
      _handleAuthResponse(result);
    } on PlatformException catch (e) {
      // If auth is cancelled or any other error - the library
      // throw the exception. We catch it and return the error
      // in a standard way for us. So the root screen has the error answer
      // in the same format both for inner and external browsers
      Navigator.of(context).pop({
        'error': e,
      });
    }
  }

  _handleAuthResponse(String response) {
    if (response.contains('?code=')) {
      // parsing the auth code from the response
      // the response structure can be different for different providers
      // so this parsing logic should be adjusted for your provider
      final code = response.split('=')[1];
      l('build', 'code', code);
      Navigator.of(context).pop({
        'code': code,
      });
      return NavigationDecision.prevent;
    }

    if (response.contains('?error=')) {
      // the error response is also specific for the Github oauth way
      // below is the redirect url structure for the github
      // tark://callback?error=access_denied&error_description=The+user+has+denied+your+application+access.&error_uri=https%3A%2F%2Fdocs.github.com%2Fapps%2Fmanaging-oauth-apps%2Ftroubleshooting-authorization-request-errors%2F%23access-denied
      // your provider can have another url structure, so this  parsing logic should be
      // adjusted
      final error = response.split('=')[1].split('&')[0];
      l('build', 'error', error);
      Navigator.of(context).pop({
        'error': error,
      });
    }
  }
}

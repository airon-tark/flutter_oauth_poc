import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'log.dart';
import 'dart:io' show HttpServer;

const clientId = 'cfef6067d4a97abb7ed1';
const clientSecret = 'a30d729ce83b7d662ade840677258e267a24ba6f';
//const redirectUri = 'https://tark.pro/callback';
const redirectUri = 'tark://callback';
const githubAuthUrl = 'https://github.com/login/oauth/authorize'
    '?client_id=$clientId'
    '&redirect_uri=$redirectUri';
const callbackUrlScheme = 'tark';

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

  onAuthPressed({required bool innerWebView}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (c) => WebScreen(
          innerWebView: innerWebView,
        ),
      ),
    );

    if (result == null) {
      setState(() => _result = 'Authorization declined');
      return;
    }

    if (result['error'] != null) {
      setState(() => _result = 'Error:\n${result['error']}');
      return;
    }

    if (result['code'] != null) {
      final code = result['code'];
      setState(() {
        _result = 'Auth code:\n$code\ngetting token....';
      });

      await Future.delayed(const Duration(seconds: 2));

      final response = await http.get(
        Uri.parse(
          'https://github.com/login/oauth/access_token'
          '?client_id=$clientId'
          '&client_secret=$clientSecret'
          '&code=$code',
        ),
        headers: {
          'Accept': 'application/json',
        },
      );

      final responseObject = jsonDecode(response.body);
      final token = responseObject['access_token'];

      setState(() => _result = 'Token:\n$token');

      l('build', 'token', token);
    }
  }
}

class WebScreen extends StatefulWidget {
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
      authWithExternalWebView();
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
              l('build', 'onUrlChange', request.url);

              if (request.url.startsWith(redirectUri)) {
                handleAuthResponse(request.url);
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

  authWithExternalWebView() async {
    try {
      final result = await FlutterWebAuth.authenticate(
        url: githubAuthUrl,
        callbackUrlScheme: callbackUrlScheme,
      );
      handleAuthResponse(result);
    } on PlatformException catch (e) {
      Navigator.of(context).pop({
        'error': e,
      });
    }
  }

  handleAuthResponse(String response) {
    if (response.contains('?code=')) {
      final code = response.split('=')[1];
      l('build', 'code', code);
      Navigator.of(context).pop({
        'code': code,
      });
      return NavigationDecision.prevent;
    }

    if (response.contains('?error=')) {
      //  tark://callback?error=access_denied&error_description=The+user+has+denied+your+application+access.&error_uri=https%3A%2F%2Fdocs.github.com%2Fapps%2Fmanaging-oauth-apps%2Ftroubleshooting-authorization-request-errors%2F%23access-denied
      final error = response.split('=')[1].split('&')[0];
      l('build', 'error', error);
      Navigator.of(context).pop({
        'error': error,
      });
    }
  }
}

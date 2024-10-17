import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'constants.dart';
import 'hero.dart';
import 'user.dart';

class ExampleApp extends StatefulWidget {
  final Auth0? auth0;
  const ExampleApp({this.auth0, final Key? key}) : super(key: key);

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  UserProfile? _user;

  late Auth0 auth0;
  late Auth0Web auth0Web;

  // @override
  // void initState() {
  //   super.initState();
  //   auth0 = widget.auth0 ??
  //       Auth0(dotenv.env['dev-3apiuihwn3qay2lf.us.auth0.com']!, dotenv.env['Vlf07In0kzteVH9UyTjlEVYMrjp4rsGv']!);
  //   auth0Web =
  //       Auth0Web(dotenv.env['dev-3apiuihwn3qay2lf.us.auth0.com']!, dotenv.env['Vlf07In0kzteVH9UyTjlEVYMrjp4rsGv']!);

  //   if (kIsWeb) {
  //     auth0Web.onLoad().then((final credentials) => setState(() {
  //           _user = credentials?.user;
  //         }));
  //   }
  // }

  // Future<void> login() async {
  //   try {
  //     if (kIsWeb) {
  //       return auth0Web.loginWithRedirect(redirectUrl: 'http://localhost:3000');
  //     }

  //     var credentials = await auth0
  //         .webAuthentication(scheme: dotenv.env['com.auth0.sample'])
  //         // Use a Universal Link callback URL on iOS 17.4+ / macOS 14.4+
  //         // useHTTPS is ignored on Android
  //         .login(useHTTPS: true);

  //     setState(() {
  //       _user = credentials.user;
  //     });
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  // Future<void> logout() async {
  //   try {
  //     if (kIsWeb) {
  //       await auth0Web.logout(returnToUrl: 'http://localhost:3000');
  //     } else {
  //       await auth0
  //           .webAuthentication(scheme: dotenv.env['com.auth0.sample'])
  //           // Use a Universal Link logout URL on iOS 17.4+ / macOS 14.4+
  //           // useHTTPS is ignored on Android
  //           .logout(useHTTPS: true);
  //       setState(() {
  //         _user = null;
  //       });
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  @override
void initState() {
  super.initState();

  final String? domain = dotenv.env['AUTH0_DOMAIN'];
  final String? clientId = dotenv.env['AUTH0_CLIENT_ID'];

  if (domain == null || clientId == null) {
    print('Error: AUTH0_DOMAIN or AUTH0_CLIENT_ID not found in .env file');
    return;
  }

  auth0 = widget.auth0 ?? Auth0(domain, clientId);
  auth0Web = Auth0Web(domain, clientId);

  if (kIsWeb) {
    auth0Web.onLoad().then((credentials) {
      if (mounted) {
        setState(() {
          _user = credentials?.user;
        });
      }
    });
  }
}

  Future<void> login() async {
  try {
    if (kIsWeb) {
      return auth0Web.loginWithRedirect(redirectUrl: 'https://hjsg6z4hj9.execute-api.us-east-2.amazonaws.com/Stage/posts');
    }

    var credentials = await auth0
        .webAuthentication(scheme: dotenv.env['AUTH0_CUSTOM_SCHEME'])
        .login(useHTTPS: true);

    setState(() {
      _user = credentials.user;
    });
  } catch (e) {
    print(e);
  }
}

Future<void> logout() async {
  try {
    if (kIsWeb) {
      await auth0Web.logout(returnToUrl: 'https://hjsg6z4hj9.execute-api.us-east-2.amazonaws.com/Stage/posts');
    } else {
      await auth0
          .webAuthentication(scheme: dotenv.env['AUTH0_CUSTOM_SCHEME'])
          .logout(useHTTPS: true);
      setState(() {
        _user = null;
      });
    }
  } catch (e) {
    print(e);
  }
}

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: Padding(
        padding: const EdgeInsets.only(
          top: padding,
          bottom: padding,
          left: padding / 2,
          right: padding / 2,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
              child: Row(children: [
            _user != null
                ? Expanded(child: UserWidget(user: _user))
                : const Expanded(child: HeroWidget())
          ])),
          _user != null
              ? ElevatedButton(
                  onPressed: logout,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.black),
                  ),
                  child: const Text('Logout'),
                )
              : ElevatedButton(
                  onPressed: login,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.black),
                  ),
                  child: const Text('Login'),
                )
        ]),
      )),
    );
  }
}

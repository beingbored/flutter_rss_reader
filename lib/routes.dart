import 'package:flutter/material.dart';
import 'package:flutter_rss_reader/pages/home.dart';
import 'package:flutter_rss_reader/pages/setting.dart';
import 'package:flutter_rss_reader/pages/splash.dart';

class Routes {
  static const SplashPage = "splash";
  static const HomePage = "home";
  static const LoginPage = "login";
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final routeName = settings.name;

    switch(routeName) {
      case Routes.SplashPage:
        return _simpleRoute(SplashPage());
      case Routes.HomePage:
        return _simpleRoute(HomePage());
      case Routes.HomePage:
        return _simpleRoute(SettingPage());
    }
  }

  static Route<dynamic> _simpleRoute(StatefulWidget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
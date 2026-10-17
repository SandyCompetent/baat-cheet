import 'package:chatbud/main.dart';
import 'package:chatbud/src/auth/unified_auth_screen.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
import 'package:chatbud/src/screen/splash_screen.dart';
import 'package:flutter/material.dart';

const String splashRoute = '/Splash';
const String loginRoute  = '/Login';
const String homeRoute   = '/Home';
const String converRoute = '/Conversation';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case loginRoute:
        return MaterialPageRoute(builder: (_) => const UnifiedAuthScreen());

      case homeRoute:
        return MaterialPageRoute(builder: (_) => const MyHomePage());

      case converRoute:
        return MaterialPageRoute(builder: (_) => const ConversationScreen());

      default:
        return MaterialPageRoute(
            builder: (_) => const Scaffold(body: SizedBox.shrink()));
    }
  }
}

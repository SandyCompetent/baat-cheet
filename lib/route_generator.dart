import 'package:chatbud/main.dart';
import 'package:chatbud/src/auth/unified_auth_screen.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
import 'package:chatbud/src/screen/persona_hub_screen.dart';
import 'package:chatbud/src/screen/splash_screen.dart';
import 'package:flutter/material.dart';

const String splashRoute = '/Splash';
const String loginRoute = '/Login';
const String homeRoute = '/Home';
const String converRoute = '/Conversation';
const String personaHubRoute = '/PersonaHub';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final rawName = settings.name ?? '/';
    final normalizedPath = Uri.tryParse(rawName)?.path ?? rawName;

    switch (normalizedPath) {
      case '/':
      case '':
      case '/index.html':
      case homeRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MyHomePage(),
        );

      case splashRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );

      case loginRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const UnifiedAuthScreen(),
        );

      case converRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ConversationScreen(),
        );

      case personaHubRoute:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PersonaHubScreen(),
        );

      default:
        // Never return an empty SizedBox.shrink() screen on Web when a browser
        // URL includes an unexpected path or subpath; fall back to MyHomePage.
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MyHomePage(),
        );
    }
  }
}

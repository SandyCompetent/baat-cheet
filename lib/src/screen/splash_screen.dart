import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../project_meta_data.dart';
import '../../route_generator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(homeRoute, (Route<dynamic> route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(appName, style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(
              height: 20,
            ),
            Text(appVersion, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(
              height: 40,
            ),
            const Image(
                image: AssetImage(appLogo),
                width: 128,
                height: 128,
                fit: BoxFit.cover),
            const SizedBox(
              height: 40,
            ),
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.secondary))
          ],
        ),
      ),
    );
  }
}

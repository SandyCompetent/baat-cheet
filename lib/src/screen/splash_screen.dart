import 'dart:async';
import 'package:chatbud/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../project_meta_data.dart';
import '../../route_generator.dart';

class SplashScreen extends StatefulWidget {
  final Duration redirectDelay;

  const SplashScreen({
    super.key,
    this.redirectDelay = const Duration(milliseconds: 1500),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    _timer = Timer(widget.redirectDelay, () {
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(homeRoute, (Route<dynamic> route) => false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    return Scaffold(
      backgroundColor: context.bgCanvas,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: context.accentSubtle,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    appLogo,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.chat_bubble_rounded,
                      color: context.accent,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                appName,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                appVersion,
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

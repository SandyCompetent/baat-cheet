import 'dart:async';
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
      duration: widget.redirectDelay,
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    _timer = Timer(widget.redirectDelay, () {
      if (!mounted) return;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      backgroundColor: const Color(0xFF0B101A),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Color(0xFF1A2235),
              Color(0xFF0B101A),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 5),
              Image.asset(
                appLogo,
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.blueAccent,
                  size: 80,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Chat",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFFFF7170)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                    child: const Text(
                      "Bud",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "THE MULTI-AGENT AI WORKSPACE",
                style: TextStyle(
                  color: Color(0xFF8A92A6),
                  fontSize: 12,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 4),
              const Text(
                "Initializing workspace...",
                style: TextStyle(
                  color: Color(0xFF8A92A6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      width: 200,
                      height: 4,
                      alignment: Alignment.centerLeft,
                      color: const Color(0xFF1E2841),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _ctrl.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C6FF), Color(0xFF9D50BB), Color(0xFFFF7170)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

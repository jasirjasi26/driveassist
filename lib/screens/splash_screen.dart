import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_theme.dart';
import '../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAppAndNavigate();
  }

  Future<void> _initAppAndNavigate() async {
    // 1. Initialise local storage & preferences
    await StorageService().init();

    // 2. Add visual delay for splash readability
    await Future.delayed(const Duration(milliseconds: 2800));

    // 3. Check critical camera & location permission states
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;

    if (!mounted) return;

    if (cameraStatus.isGranted && locationStatus.isGranted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/permissions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient glowing background orb
            Positioned(
              top: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  //shape: BoxShape.circle,
                  color: AppTheme.electricTeal.withOpacity(0.08),
                  borderRadius:
                      BorderRadius.all(Radius.circular(100)), // standard glow
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // High tech ADAS icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.electricTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppTheme.electricTeal, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.electricTeal.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.radar,
                      size: 48,
                      color: AppTheme.electricTeal,
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.3, 0.3),
                      )
                      .then()
                      .shake(hz: 2, duration: 1200.ms),
                  const SizedBox(height: 24),
                  // Title text
                  Text(
                    'DRIVEASSIST',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3.0,
                      shadows: [
                        Shadow(
                          color: AppTheme.electricTeal.withOpacity(0.6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0.0),
                  const SizedBox(height: 8),
                  // Subtitle text
                  Text(
                    'ADVANCED COGNITIVE ADAS ENGINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.4),
                      letterSpacing: 2.0,
                    ),
                  ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
                ],
              ),
            ),
            // Bottom loading indicator
            Positioned(
              bottom: 80,
              child: Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppTheme.electricTeal,
                      strokeWidth: 3,
                      backgroundColor: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'INITIALIZING SYSTEM CORRIDORS...',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.4),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1000.ms),
            ),
          ],
        ),
      ),
    );
  }
}

extension on BoxDecoration {
  // Simple fake extension to allow compilation of blurRadius on container or handle cleanly
  // Actually BoxShadow provides blurRadius. We set it in BoxShadow.
}

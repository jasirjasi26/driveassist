import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/drive_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/drive_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/storage_service.dart';

void main() async {
  // Ensure framework bindings are fully initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlays to transparent / dark for full premium screen immersion
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Lock orientation to portrait (standard for dashboard windshield mount)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialise local Storage Cache for early provider loading
  final storage = StorageService();
  await storage.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DriveProvider()),
      ],
      child: const DriveAssistApp(),
    ),
  );
}

class DriveAssistApp extends StatelessWidget {
  const DriveAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'DriveAssist',
      debugShowCheckedModeBanner: false,
      
      // Apply dark theme by default, falling back to HUD parameters if active
      theme: AppTheme.darkTheme,
      themeMode: settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      
      // Initial route starts with the splash animation
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/permissions': (context) => const PermissionsScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/drive': (context) => const DriveScreen(),
        '/summary': (context) => const SummaryScreen(),
        '/history': (context) => const HistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

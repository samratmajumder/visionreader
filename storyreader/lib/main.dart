import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'business_logic/providers/story_provider.dart';
import 'business_logic/providers/layout_provider.dart';
import 'business_logic/providers/media_provider.dart';
import 'business_logic/providers/settings_provider.dart';
import 'presentation/screens/main_screen.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Desktop window configuration
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  runApp(const StoryReaderApp());
}

class StoryReaderApp extends StatelessWidget {
  const StoryReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => LayoutProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
              fontFamily: settings.fontFamily,
            ),
            home: const MainScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
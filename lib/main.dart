import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app/theme/app_theme.dart';
import 'app/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for safety — HUD is designed for portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI to match asphalt theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // TODO: Initialize Firebase when configured
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(
    const ProviderScope(
      child: ProjectHUDApp(),
    ),
  );
}

class ProjectHUDApp extends StatelessWidget {
  const ProjectHUDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ProjectHUD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}

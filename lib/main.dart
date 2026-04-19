import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/fpl_provider.dart';
import 'providers/user_teams_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.secondary,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const FplAnalyticsApp());
}

class FplAnalyticsApp extends StatelessWidget {
  const FplAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FplProvider()),
        ChangeNotifierProvider(create: (_) => UserTeamsProvider()),
      ],
      child: MaterialApp(
        title: 'FPL Analytics',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}

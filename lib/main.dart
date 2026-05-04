import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/fpl_provider.dart';
import 'providers/fpl_entry_provider.dart';
import 'providers/user_teams_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const FplAnalyticsApp());
}

class FplAnalyticsApp extends StatelessWidget {
  const FplAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FplProvider()),
        ChangeNotifierProvider(create: (_) => FplEntryProvider()),
        ChangeNotifierProvider(create: (_) => UserTeamsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final isDark = themeProvider.isDark;
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ));
          return MaterialApp(
            title: 'FPL Analytics',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const _AppRoot(),
          );
        },
      ),
    );
  }
}

/// Root widget that initialises providers and decides whether to show
/// the onboarding screen or the main navigation.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FplProvider>().loadAllData();
      context.read<UserTeamsProvider>().loadTeams();
      context.read<FplEntryProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FplEntryProvider>(
      builder: (context, entryProvider, _) {
        // Still initialising — show a minimal splash
        if (!entryProvider.initDone) {
          return const _SplashScreen();
        }
        // First launch with no saved entry and user hasn't skipped yet
        if (!entryProvider.hasEntry && !entryProvider.skippedOnboarding) {
          return const OnboardingScreen();
        }
        return const MainNavigationScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

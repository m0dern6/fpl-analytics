import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fpl_provider.dart';
import '../providers/user_teams_provider.dart';
import '../utils/constants.dart';
import 'dashboard_screen.dart';
import 'players_screen.dart';
import 'my_teams_screen.dart';
import 'ai_picks_screen.dart';
import 'more_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    PlayersScreen(),
    MyTeamsScreen(),
    AiPicksScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FplProvider>().loadAllData();
      context.read<UserTeamsProvider>().loadTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(102),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Players',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined),
                activeIcon: Icon(Icons.group),
                label: 'My Teams',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome),
                label: 'AI Picks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

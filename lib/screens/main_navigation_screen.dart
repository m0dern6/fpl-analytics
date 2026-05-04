import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'dashboard_screen.dart';
import 'players_screen.dart';
import 'transfer_planner_screen.dart';
import 'live_screen.dart';
import 'leagues_screen.dart';

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
    TransferPlannerScreen(),
    LiveScreen(),
    LeaguesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Note: FplProvider.loadAllData, UserTeamsProvider.loadTeams, and
    // FplEntryProvider.init are called from _AppRoot before this screen is shown.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Navigation bar ─────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavDest(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavDest(Icons.people_rounded, Icons.people_outline_rounded, 'Players'),
    _NavDest(Icons.swap_horiz_rounded, Icons.swap_horiz_outlined, 'Plan'),
    _NavDest(Icons.live_tv_rounded, Icons.live_tv_outlined, 'Live'),
    _NavDest(Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Leagues'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).navBar,
        border: Border(
          top: BorderSide(color: AppColors.of(context).divider, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              return _NavItem(
                dest: _items[i],
                index: i,
                currentIndex: currentIndex,
                onTap: onTap,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavDest {
  final IconData filledIcon;
  final IconData outlinedIcon;
  final String label;
  const _NavDest(this.filledIcon, this.outlinedIcon, this.label);
}

class _NavItem extends StatelessWidget {
  final _NavDest dest;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.dest,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.of(context).primary.withAlpha(28)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                isSelected ? dest.filledIcon : dest.outlinedIcon,
                color: isSelected ? AppColors.of(context).primary : AppColors.of(context).textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                color: isSelected ? AppColors.of(context).primary : AppColors.of(context).textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: isSelected ? 0.1 : 0,
              ),
              child: Text(dest.label),
            ),
          ],
        ),
      ),
    );
  }
}


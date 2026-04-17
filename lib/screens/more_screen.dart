import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'fixture_difficulty_screen.dart';
import 'stats_leaders_screen.dart';
import 'compare_screen.dart';
import 'teams_screen.dart';
import 'fixtures_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MoreItem(
        'Fixture Difficulty',
        'FDR matrix for all teams',
        Icons.grid_on,
        [const Color(0xFF1a3a5c), const Color(0xFF0d2137)],
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FixtureDifficultyScreen())),
      ),
      _MoreItem(
        'Stats Leaders',
        'Top scorers, assists & more',
        Icons.leaderboard,
        [const Color(0xFF1a3a2a), const Color(0xFF0d2a1a)],
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsLeadersScreen())),
      ),
      _MoreItem(
        'Compare Players',
        'Side-by-side comparison',
        Icons.compare_arrows,
        [const Color(0xFF2a1a4c), const Color(0xFF1a0d37)],
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen())),
      ),
      _MoreItem(
        'Teams',
        'All 20 Premier League teams',
        Icons.shield,
        [const Color(0xFF3a1a1a), const Color(0xFF2a0d0d)],
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamsScreen())),
      ),
      _MoreItem(
        'All Fixtures',
        'Season fixture list',
        Icons.sports_soccer,
        [const Color(0xFF1a2a3a), const Color(0xFF0d1a2a)],
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FixturesScreen())),
      ),
      _MoreItem(
        'Team Strength',
        'Attack & defence ratings',
        Icons.bar_chart,
        [const Color(0xFF1a3a1a), const Color(0xFF0d2a0d)],
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamsScreen())),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: AppColors.secondary,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i]),
      ),
    );
  }

  Widget _buildCard(_MoreItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item.colors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(77),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(item.subtitle, style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _MoreItem(this.title, this.subtitle, this.icon, this.colors, this.onTap);
}

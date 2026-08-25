import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/theme_provider.dart';
import 'fixture_difficulty_screen.dart';
import 'stats_leaders_screen.dart';
import 'compare_screen.dart';
import 'teams_screen.dart';
import 'fixtures_screen.dart';
import 'gameweeks_screen.dart';
import 'my_teams_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ExploreItem(
        title: 'My Teams',
        subtitle: 'Manage your custom FPL squads',
        icon: Icons.person_rounded,
        iconColor: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyTeamsScreen()),
        ),
      ),
      _ExploreItem(
        title: 'Gameweeks',
        subtitle: 'History & live scores',
        icon: Icons.calendar_month_rounded,
        iconColor: AppColors.of(context).accent,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameweeksScreen()),
        ),
      ),
      _ExploreItem(
        title: 'Fixture Difficulty',
        subtitle: 'FDR matrix for all teams',
        icon: Icons.grid_4x4_rounded,
        iconColor: AppColors.of(context).primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FixtureDifficultyScreen()),
        ),
      ),
      _ExploreItem(
        title: 'Stats Leaders',
        subtitle: 'Top scorers, assists & more',
        icon: Icons.leaderboard_rounded,
        iconColor: const Color(0xFFF97316),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatsLeadersScreen()),
        ),
      ),
      _ExploreItem(
        title: 'Compare Players',
        subtitle: 'Side-by-side comparison',
        icon: Icons.compare_arrows_rounded,
        iconColor: const Color(0xFFA78BFA),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompareScreen()),
        ),
      ),
      _ExploreItem(
        title: 'Teams',
        subtitle: 'All 20 Premier League clubs',
        icon: Icons.shield_rounded,
        iconColor: const Color(0xFF34D399),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeamsScreen()),
        ),
      ),
      _ExploreItem(
        title: 'All Fixtures',
        subtitle: 'Full season fixture list',
        icon: Icons.sports_soccer_rounded,
        iconColor: const Color(0xFF60A5FA),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FixturesScreen()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: AppColors.of(context).secondary,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              icon: Icon(
                themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () => context.read<ThemeProvider>().toggle(),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _ExploreCard(item: items[i]),
      ),
    );
  }
}

class _ExploreItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ExploreItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}

class _ExploreCard extends StatelessWidget {
  final _ExploreItem item;
  const _ExploreCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.of(context).cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.of(context).divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: item.iconColor.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 22),
            ),
            const Spacer(),
            Text(
              item.title,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.subtitle,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/fixture.dart';
import '../models/team.dart';
import '../providers/fpl_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/difficulty_badge.dart';
import 'fixture_detail_screen.dart';

class TeamFixturesScreen extends StatefulWidget {
  final Team team;

  const TeamFixturesScreen({super.key, required this.team});

  @override
  State<TeamFixturesScreen> createState() => _TeamFixturesScreenState();
}

class _TeamFixturesScreenState extends State<TeamFixturesScreen> {
  bool _showLatestFirst = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FplProvider>();
    final fixtures =
        List<Fixture>.from(provider.getFixturesForTeam(widget.team.id))..sort((
          a,
          b,
        ) {
          final aKey = a.kickoffTime ?? '';
          final bKey = b.kickoffTime ?? '';
          return _showLatestFirst ? bKey.compareTo(aKey) : aKey.compareTo(bKey);
        });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.team.name),
        backgroundColor: AppColors.secondary,
        actions: [
          IconButton(
            tooltip: _showLatestFirst
                ? 'Show earliest first'
                : 'Show latest first',
            onPressed: () =>
                setState(() => _showLatestFirst = !_showLatestFirst),
            icon: Icon(
              _showLatestFirst
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.purpleGradient(),
            child: Row(
              children: [
                CachedNetworkImage(
                  imageUrl: widget.team.badgeUrl,
                  width: 54,
                  height: 54,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(width: 54, height: 54),
                  errorWidget: (_, __, ___) =>
                      const SizedBox(width: 54, height: 54),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.team.shortName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _showLatestFirst
                            ? 'Latest fixtures first'
                            : 'Earliest fixtures first',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...fixtures.map((fixture) {
            final home = provider.getTeamById(fixture.homeTeamId);
            final away = provider.getTeamById(fixture.awayTeamId);
            final isHome = fixture.homeTeamId == widget.team.id;
            final opponent = isHome ? away : home;
            final difficulty = isHome
                ? fixture.teamHDifficulty
                : fixture.teamADifficulty;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FixtureDetailScreen(
                      fixture: fixture,
                      homeTeam: home,
                      awayTeam: away,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.gradientCard(),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isHome
                              ? AppColors.primary.withAlpha(24)
                              : AppColors.accent.withAlpha(24),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isHome ? 'Home' : 'Away',
                          style: TextStyle(
                            color: isHome
                                ? AppColors.primary
                                : AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            if (opponent != null) ...[
                              CachedNetworkImage(
                                imageUrl: opponent.badgeUrl,
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                                placeholder: (_, __) =>
                                    const SizedBox(width: 24, height: 24),
                                errorWidget: (_, __, ___) =>
                                    const SizedBox(width: 24, height: 24),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                opponent?.name ?? '?',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        fixture.kickoffTime != null
                            ? formatDateShort(fixture.kickoffTime)
                            : 'TBD',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      DifficultyBadge(difficulty: difficulty),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

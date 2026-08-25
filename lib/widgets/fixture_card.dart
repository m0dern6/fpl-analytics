import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/fixture.dart';
import '../models/team.dart';
import '../providers/fpl_provider.dart';
import '../screens/fixture_detail_screen.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'difficulty_badge.dart';

class FixtureCard extends StatelessWidget {
  final Fixture fixture;
  final FplProvider provider;
  final bool compact;

  const FixtureCard({
    super.key,
    required this.fixture,
    required this.provider,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final home = provider.getTeamById(fixture.homeTeamId);
    final away = provider.getTeamById(fixture.awayTeamId);

    return GestureDetector(
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
        padding: EdgeInsets.all(compact ? 10 : 14),
        decoration: AppTheme.gradientCard(context: context),
        child: compact
            ? _compactLayout(context, home, away)
            : _fullLayout(context, home, away),
      ),
    );
  }

  Widget _fullLayout(BuildContext context, Team? home, Team? away) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _teamDisplay(context, home, fixture.teamHDifficulty, true),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.of(context).cardMedium,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.of(context).divider),
              ),
              child: fixture.hasResult
                  ? Text(
                      '${fixture.homeTeamScore} - ${fixture.awayTeamScore}',
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    )
                  : Column(
                      children: [
                        Text(
                          fixture.kickoffTime != null
                              ? formatDateShort(fixture.kickoffTime)
                              : 'TBC',
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          fixture.kickoffTime != null
                              ? _extractTime(fixture.kickoffTime!)
                              : '',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: _teamDisplay(
                context,
                away,
                fixture.teamADifficulty,
                false,
              ),
            ),
          ],
        ),
        if (!fixture.finished && fixture.kickoffTime != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                color: AppColors.of(context).textSecondary,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                formatDateTime(fixture.kickoffTime),
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _compactLayout(BuildContext context, Team? home, Team? away) {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  home?.shortName ?? '?',
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (home != null)
                CachedNetworkImage(
                  imageUrl: home.badgeUrl,
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(width: 26, height: 26),
                  errorWidget: (_, __, ___) =>
                      const SizedBox(width: 26, height: 26),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.of(context).cardMedium,
            borderRadius: BorderRadius.circular(8),
          ),
          child: fixture.hasResult
              ? Text(
                  '${fixture.homeTeamScore} - ${fixture.awayTeamScore}',
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                )
              : Text(
                  _formatTimeShort(fixture.kickoffTime),
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 12,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              if (away != null)
                CachedNetworkImage(
                  imageUrl: away.badgeUrl,
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(width: 26, height: 26),
                  errorWidget: (_, __, ___) =>
                      const SizedBox(width: 26, height: 26),
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  away?.shortName ?? '?',
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _teamDisplay(
    BuildContext context,
    Team? team,
    int difficulty,
    bool isHome,
  ) {
    final badge = CachedNetworkImage(
      imageUrl: team?.badgeUrl ?? '',
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      placeholder: (_, __) => const SizedBox(width: 32, height: 32),
      errorWidget: (_, __, ___) => const SizedBox(width: 32, height: 32),
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: isHome
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: isHome
              ? [
                  Text(
                    team?.shortName ?? '?',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  badge,
                ]
              : [
                  badge,
                  const SizedBox(width: 6),
                  Text(
                    team?.shortName ?? '?',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: isHome
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            DifficultyBadge(difficulty: difficulty, size: 24),
            const SizedBox(width: 4),
            Text(
              isHome ? 'H' : 'A',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _extractTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  String _formatTimeShort(String? timeStr) {
    if (timeStr == null) return '';
    try {
      final time = DateTime.parse(timeStr).toLocal();
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }
}

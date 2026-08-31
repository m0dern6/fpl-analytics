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

    final isLive = fixture.isLive;
    final isFinished = fixture.isFinished;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    BoxDecoration decoration;
    if (isLive) {
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withAlpha(90),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (isFinished) {
      decoration = BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
          width: 1,
        ),
      );
    } else {
      decoration = AppTheme.gradientCard(context: context);
    }

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
        decoration: decoration,
        child: compact
            ? _compactLayout(context, home, away, isLive, isFinished)
            : _fullLayout(context, home, away, isLive, isFinished),
      ),
    );
  }

  Widget _fullLayout(
    BuildContext context,
    Team? home,
    Team? away,
    bool isLive,
    bool isFinished,
  ) {
    final textColor = isLive
        ? Colors.white
        : AppColors.of(context).textPrimary;
    final subtextColor = isLive
        ? Colors.white.withAlpha(200)
        : AppColors.of(context).textSecondary;

    return Column(
      children: [
        if (isLive) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: Color(0xFFE91E63), size: 7),
                const SizedBox(width: 4),
                Text(
                  'LIVE • ${_formatLiveMinute(fixture)}',
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: _teamDisplay(
                context,
                home,
                fixture.teamHDifficulty,
                true,
                isLive: isLive,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isLive
                    ? Colors.black.withAlpha(50)
                    : (isFinished
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withAlpha(70)
                            : Colors.white.withAlpha(160))
                        : AppColors.of(context).cardMedium),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLive
                      ? Colors.white.withAlpha(60)
                      : AppColors.of(context).divider,
                ),
              ),
              child: (isLive || isFinished || fixture.hasResult)
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${fixture.homeTeamScore ?? 0} - ${fixture.awayTeamScore ?? 0}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        if (isFinished)
                          Text(
                            'FT',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    )
                  : Column(
                      children: [
                        Text(
                          fixture.kickoffTime != null
                              ? formatDateShort(fixture.kickoffTime)
                              : 'TBC',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          fixture.kickoffTime != null
                              ? formatTimeShort(fixture.kickoffTime)
                              : '',
                          style: TextStyle(
                            color: subtextColor,
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
                isLive: isLive,
              ),
            ),
          ],
        ),
        if (!fixture.finished &&
            !fixture.finishedProvisional &&
            !isLive &&
            fixture.kickoffTime != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                color: subtextColor,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                formatDateTime(fixture.kickoffTime),
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _compactLayout(
    BuildContext context,
    Team? home,
    Team? away,
    bool isLive,
    bool isFinished,
  ) {
    final textColor = isLive
        ? Colors.white
        : AppColors.of(context).textPrimary;
    final subtextColor = isLive
        ? Colors.white.withAlpha(200)
        : AppColors.of(context).textSecondary;

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
                    color: textColor,
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
                  placeholder: (_, _) => const SizedBox(width: 26, height: 26),
                  errorWidget: (_, _, _) =>
                      const SizedBox(width: 26, height: 26),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isLive
                ? Colors.black.withAlpha(60)
                : (isFinished
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withAlpha(70)
                        : Colors.white.withAlpha(160))
                    : AppColors.of(context).cardMedium),
            borderRadius: BorderRadius.circular(8),
          ),
          child: (isLive || isFinished || fixture.hasResult)
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              color: Color(0xFFE91E63),
                              size: 4,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatLiveMinute(fixture),
                              style: const TextStyle(
                                color: Color(0xFFE91E63),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Text(
                      '${fixture.homeTeamScore ?? 0} - ${fixture.awayTeamScore ?? 0}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : Text(
                  formatTimeShort(fixture.kickoffTime),
                  style: TextStyle(
                    color: subtextColor,
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
                  placeholder: (_, _) => const SizedBox(width: 26, height: 26),
                  errorWidget: (_, _, _) =>
                      const SizedBox(width: 26, height: 26),
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  away?.shortName ?? '?',
                  style: TextStyle(
                    color: textColor,
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
    bool isHome, {
    bool isLive = false,
  }) {
    final textColor = isLive
        ? Colors.white
        : AppColors.of(context).textPrimary;
    final subtextColor = isLive
        ? Colors.white.withAlpha(200)
        : AppColors.of(context).textSecondary;

    final badge = CachedNetworkImage(
      imageUrl: team?.badgeUrl ?? '',
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      placeholder: (_, _) => const SizedBox(width: 32, height: 32),
      errorWidget: (_, _, _) => const SizedBox(width: 32, height: 32),
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: isHome
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: isHome
              ? [
                  Flexible(
                    child: Text(
                      team?.shortName ?? '?',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  badge,
                ]
              : [
                  badge,
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      team?.shortName ?? '?',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                color: subtextColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatLiveMinute(Fixture fixture) {
    if (fixture.minutes != null && fixture.minutes! > 0) {
      if (fixture.minutes == 45) return 'HT';
      if (fixture.minutes! > 90) return '90+\'';
      return '${fixture.minutes}\'';
    }
    if (fixture.kickoffDateTime != null) {
      final elapsed = DateTime.now()
          .toUtc()
          .difference(fixture.kickoffDateTime!.toUtc())
          .inMinutes;
      if (elapsed <= 0) return '1\'';
      if (elapsed <= 45) return '$elapsed\'';
      if (elapsed <= 60) return 'HT';
      final secondHalfMin = (elapsed - 15).clamp(46, 90);
      return '$secondHalfMin\'';
    }
    return 'LIVE';
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/fixture.dart';
import '../models/team.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/difficulty_badge.dart';

class FixtureDetailScreen extends StatelessWidget {
  final Fixture fixture;
  final Team? homeTeam;
  final Team? awayTeam;

  const FixtureDetailScreen({
    super.key,
    required this.fixture,
    this.homeTeam,
    this.awayTeam,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(fixture.event != null ? 'Gameweek ${fixture.event}' : 'Fixture'),
        backgroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMatchCard(context),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildDifficultyCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.purpleGradient(),
      child: Column(
        children: [
          if (fixture.event != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: Text(
                'Gameweek ${fixture.event}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(child: _teamColumn(homeTeam, isHome: true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: fixture.hasResult
                    ? Column(
                        children: [
                          Text(
                            '${fixture.homeTeamScore}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            '–',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            '${fixture.awayTeamScore}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          const Text(
                            'VS',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          if (fixture.kickoffTime != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _extractTime(fixture.kickoffTime!),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              Expanded(child: _teamColumn(awayTeam, isHome: false)),
            ],
          ).animate().fadeIn(duration: 400.ms),
          if (fixture.finished) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Full Time',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else if (fixture.started == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Live',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _teamColumn(Team? team, {required bool isHome}) {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: team?.badgeUrl ?? '',
          width: 64,
          height: 64,
          fit: BoxFit.contain,
          placeholder: (_, __) => Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.cardMedium,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield, color: AppColors.textSecondary, size: 32),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.cardMedium,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                team?.shortName ?? '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          team?.shortName ?? '?',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          team?.name ?? '',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isHome
                ? AppColors.primary.withAlpha(24)
                : AppColors.accent.withAlpha(24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHome
                  ? AppColors.primary.withAlpha(80)
                  : AppColors.accent.withAlpha(80),
            ),
          ),
          child: Text(
            isHome ? 'Home' : 'Away',
            style: TextStyle(
              color: isHome ? AppColors.primary : AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Details',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (fixture.kickoffTime != null) ...[
            _detailRow(
              Icons.calendar_today_rounded,
              'Date',
              formatDateTime(fixture.kickoffTime),
            ),
            const SizedBox(height: 10),
            _detailRow(
              Icons.access_time_rounded,
              'Kick-off',
              _extractTime(fixture.kickoffTime!),
            ),
            const SizedBox(height: 10),
          ],
          if (fixture.event != null)
            _detailRow(
              Icons.sports_soccer_rounded,
              'Gameweek',
              'GW${fixture.event}',
            ),
          if (fixture.finished && fixture.minutes != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              Icons.timer_rounded,
              'Minutes Played',
              '${fixture.minutes}\'',
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 14),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fixture Difficulty',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _difficultyRow(
                  homeTeam?.shortName ?? 'Home',
                  fixture.teamHDifficulty,
                  isHome: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _difficultyRow(
                  awayTeam?.shortName ?? 'Away',
                  fixture.teamADifficulty,
                  isHome: false,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _difficultyRow(String teamName, int difficulty, {required bool isHome}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            teamName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isHome ? 'Home' : 'Away',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 8),
          DifficultyBadge(difficulty: difficulty, size: 32),
          const SizedBox(height: 4),
          Text(
            getDifficultyLabel(difficulty),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _extractTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

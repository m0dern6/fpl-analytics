import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/fixture.dart';
import '../models/team.dart';
import '../providers/fpl_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/difficulty_badge.dart';
import 'player_detail_screen.dart';

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
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(
          fixture.event != null ? 'Gameweek ${fixture.event}' : 'Fixture',
        ),
        backgroundColor: AppColors.of(context).secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMatchCard(context),
            const SizedBox(height: 16),
            _buildDetailsCard(context),
            if (fixture.finished && fixture.stats.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMatchEventsCard(context),
            ],
            const SizedBox(height: 16),
            _buildDifficultyCard(context),
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
                color: AppColors.of(context).primary.withAlpha(24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.of(context).primary.withAlpha(80),
                ),
              ),
              child: Text(
                'Gameweek ${fixture.event}',
                style: TextStyle(
                  color: AppColors.of(context).primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(child: _teamColumn(context, homeTeam, isHome: true)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: fixture.hasResult
                    ? Column(
                        children: [
                          Text(
                            '${fixture.homeTeamScore}',
                            style: TextStyle(
                              color: AppColors.of(context).textPrimary,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '–',
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            '${fixture.awayTeamScore}',
                            style: TextStyle(
                              color: AppColors.of(context).textPrimary,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Text(
                            'VS',
                            style: TextStyle(
                              color: AppColors.of(context).textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          if (fixture.kickoffTime != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _extractTime(fixture.kickoffTime!),
                              style: TextStyle(
                                color: AppColors.of(context).primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              Expanded(child: _teamColumn(context, awayTeam, isHome: false)),
            ],
          ).animate().fadeIn(duration: 400.ms),
          if (fixture.finished) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Full Time',
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
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
                color: AppColors.of(context).primary.withAlpha(24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.of(context).primary.withAlpha(80),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.of(context).primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live',
                    style: TextStyle(
                      color: AppColors.of(context).primary,
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

  Widget _teamColumn(BuildContext context, Team? team, {required bool isHome}) {
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
              color: AppColors.of(context).cardMedium,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shield,
              color: AppColors.of(context).textSecondary,
              size: 32,
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.of(context).cardMedium,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                team?.shortName ?? '?',
                style: TextStyle(
                  color: AppColors.of(context).primary,
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
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          team?.name ?? '',
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: isHome
                ? AppColors.of(context).primary.withAlpha(24)
                : AppColors.of(context).accent.withAlpha(24),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHome
                  ? AppColors.of(context).primary.withAlpha(80)
                  : AppColors.of(context).accent.withAlpha(80),
            ),
          ),
          child: Text(
            isHome ? 'Home' : 'Away',
            style: TextStyle(
              color: isHome
                  ? AppColors.of(context).primary
                  : AppColors.of(context).accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Details',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          if (fixture.kickoffTime != null) ...[
            _detailRow(
              context,
              Icons.calendar_today_rounded,
              'Date',
              formatDateTime(fixture.kickoffTime),
            ),
            const SizedBox(height: 10),
            _detailRow(
              context,
              Icons.access_time_rounded,
              'Kick-off',
              _extractTime(fixture.kickoffTime!),
            ),
            const SizedBox(height: 10),
          ],
          if (fixture.event != null)
            _detailRow(
              context,
              Icons.sports_soccer_rounded,
              'Gameweek',
              'GW${fixture.event}',
            ),
          if (fixture.finished && fixture.minutes != null) ...[
            const SizedBox(height: 10),
            _detailRow(
              context,
              Icons.timer_rounded,
              'Minutes Played',
              '${fixture.minutes}\'',
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.of(context).primary.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.of(context).primary, size: 14),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Match Events ────────────────────────────────────────────────────────────

  Widget _buildMatchEventsCard(BuildContext context) {
    return Consumer<FplProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.gradientCard(context: context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Match Events',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              ...fixture.stats
                  .where((s) => s.home.isNotEmpty || s.away.isNotEmpty)
                  .map((stat) => _buildStatSection(context, provider, stat)),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms);
      },
    );
  }

  Widget _buildStatSection(
    BuildContext context,
    FplProvider provider,
    FixtureStat stat,
  ) {
    final info = _statInfo(context, stat.identifier);
    if (info == null) return const SizedBox.shrink();

    final allEntries = [
      ...stat.home.map((e) => _StatDisplayEntry(e, isHome: true)),
      ...stat.away.map((e) => _StatDisplayEntry(e, isHome: false)),
    ];

    if (allEntries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(info.icon, color: info.color, size: 16),
              const SizedBox(width: 8),
              Text(
                info.label,
                style: TextStyle(
                  color: info.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ...allEntries.map(
          (entry) => _buildPlayerEventRow(context, provider, entry, info),
        ),
        Divider(color: AppColors.of(context).divider, height: 16),
      ],
    );
  }

  Widget _buildPlayerEventRow(
    BuildContext context,
    FplProvider provider,
    _StatDisplayEntry entry,
    _StatMeta info,
  ) {
    final player = provider.getPlayerById(entry.stat.element);
    final teamName = entry.isHome
        ? (homeTeam?.shortName ?? 'H')
        : (awayTeam?.shortName ?? 'A');
    final teamColor = entry.isHome
        ? AppColors.of(context).primary
        : AppColors.of(context).accent;

    return InkWell(
      onTap: player != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerDetailScreen(player: player),
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Player photo
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.of(context).cardMedium,
                shape: BoxShape.circle,
                border: Border.all(color: teamColor.withAlpha(100)),
              ),
              clipBehavior: Clip.antiAlias,
              child: player != null
                  ? CachedNetworkImage(
                      imageUrl: player.photoUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      placeholder: (_, __) => Icon(
                        Icons.person,
                        color: AppColors.of(context).textSecondary,
                        size: 18,
                      ),
                      errorWidget: (_, __, ___) => Icon(
                        Icons.person,
                        color: AppColors.of(context).textSecondary,
                        size: 18,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: AppColors.of(context).textSecondary,
                      size: 18,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player?.webName ?? 'Player #${entry.stat.element}',
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    teamName,
                    style: TextStyle(color: teamColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            // Value badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: info.color.withAlpha(24),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: info.color.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(info.icon, color: info.color, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    _formatValue(entry.stat),
                    style: TextStyle(
                      color: info.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Points badge (if applicable)
            if (info.pointsEach != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.of(context).warning.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.of(context).warning.withAlpha(80),
                  ),
                ),
                child: Text(
                  '${entry.stat.value * info.pointsEach! > 0 ? '+' : ''}${entry.stat.value * info.pointsEach!} pts',
                  style: TextStyle(
                    color: AppColors.of(context).warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatValue(FixtureStatEntry stat) {
    if (stat.value == 1) return '×1';
    return '×${stat.value}';
  }

  _StatMeta? _statInfo(BuildContext context, String identifier) {
    switch (identifier) {
      case 'goals_scored':
        return _StatMeta(
          label: 'Goals Scored',
          icon: Icons.sports_soccer_rounded,
          color: AppColors.of(context).primary,
          pointsEach: 4, // approximate (varies by position)
        );
      case 'assists':
        return _StatMeta(
          label: 'Assists',
          icon: Icons.sports_rounded,
          color: AppColors.of(context).accent,
          pointsEach: 3,
        );
      case 'own_goals':
        return _StatMeta(
          label: 'Own Goals',
          icon: Icons.sports_soccer_outlined,
          color: AppColors.of(context).error,
          pointsEach: -2,
        );
      case 'penalties_saved':
        return _StatMeta(
          label: 'Penalties Saved',
          icon: Icons.back_hand_outlined,
          color: const Color(0xFF34D399),
          pointsEach: 5,
        );
      case 'penalties_missed':
        return _StatMeta(
          label: 'Penalties Missed',
          icon: Icons.block_rounded,
          color: AppColors.of(context).error,
          pointsEach: -2,
        );
      case 'yellow_cards':
        return _StatMeta(
          label: 'Yellow Cards',
          icon: Icons.square_rounded,
          color: AppColors.of(context).warning,
          pointsEach: -1,
        );
      case 'red_cards':
        return _StatMeta(
          label: 'Red Cards',
          icon: Icons.square_rounded,
          color: AppColors.of(context).error,
          pointsEach: -3,
        );
      case 'saves':
        return _StatMeta(
          label: 'Saves',
          icon: Icons.back_hand_rounded,
          color: const Color(0xFF60A5FA),
          pointsEach: null, // saves give 1pt per 3 saves
        );
      case 'bonus':
        return _StatMeta(
          label: 'Bonus Points',
          icon: Icons.add_circle_rounded,
          color: const Color(0xFFFBBF24),
          pointsEach: 1,
        );
      case 'bps':
        return _StatMeta(
          label: 'Bonus Point System',
          icon: Icons.bar_chart_rounded,
          color: AppColors.of(context).textSecondary,
          pointsEach: null,
        );
      default:
        return null;
    }
  }

  Widget _buildDifficultyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientCard(context: context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fixture Difficulty',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _difficultyRow(
                  context,
                  homeTeam?.shortName ?? 'Home',
                  fixture.teamHDifficulty,
                  isHome: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _difficultyRow(
                  context,
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

  Widget _difficultyRow(
    BuildContext context,
    String teamName,
    int difficulty, {
    required bool isHome,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            teamName,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isHome ? 'Home' : 'Away',
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          DifficultyBadge(difficulty: difficulty, size: 32),
          const SizedBox(height: 4),
          Text(
            getDifficultyLabel(difficulty),
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
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

class _StatMeta {
  final String label;
  final IconData icon;
  final Color color;
  final int? pointsEach;

  const _StatMeta({
    required this.label,
    required this.icon,
    required this.color,
    this.pointsEach,
  });
}

class _StatDisplayEntry {
  final FixtureStatEntry stat;
  final bool isHome;
  const _StatDisplayEntry(this.stat, {required this.isHome});
}

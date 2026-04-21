import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/gameweek.dart';
import '../providers/fpl_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'player_detail_screen.dart';

class GameweekDetailScreen extends StatelessWidget {
  final Gameweek gw;
  final FplProvider provider;

  const GameweekDetailScreen({
    super.key,
    required this.gw,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final topPlayer =
        gw.topElement != null ? provider.getPlayerById(gw.topElement!) : null;
    final topPlayerTeam =
        topPlayer != null ? provider.getTeamById(topPlayer.teamId) : null;
    final mostTransferredPlayer = gw.mostTransferredIn != null
        ? provider.getPlayerById(gw.mostTransferredIn!)
        : null;
    final mostCaptainedPlayer = gw.mostCaptained != null
        ? provider.getPlayerById(gw.mostCaptained!)
        : null;
    final mostSelectedPlayer = gw.mostSelected != null
        ? provider.getPlayerById(gw.mostSelected!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(gw.name),
        backgroundColor: AppColors.secondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildScoreCards(),
            if (topPlayer != null) ...[
              const SizedBox(height: 20),
              AppTheme.sectionTitle(context, 'Top Player This Gameweek'),
              const SizedBox(height: 12),
              _buildPlayerHighlight(
                context,
                topPlayer,
                topPlayerTeam,
                gw.topElement != null ? provider.getPlayerById(gw.topElement!) : null,
                subtitle: 'Highest Scoring Player',
                color: AppColors.warning,
                icon: Icons.emoji_events_rounded,
              ),
            ],
            if (mostCaptainedPlayer != null) ...[
              const SizedBox(height: 16),
              _buildPlayerHighlight(
                context,
                mostCaptainedPlayer,
                provider.getTeamById(mostCaptainedPlayer.teamId),
                null,
                subtitle: 'Most Captained',
                color: AppColors.primary,
                icon: Icons.shield_rounded,
              ),
            ],
            if (mostTransferredPlayer != null) ...[
              const SizedBox(height: 16),
              _buildPlayerHighlight(
                context,
                mostTransferredPlayer,
                provider.getTeamById(mostTransferredPlayer.teamId),
                null,
                subtitle: 'Most Transferred In',
                color: AppColors.accent,
                icon: Icons.trending_up_rounded,
              ),
            ],
            if (mostSelectedPlayer != null) ...[
              const SizedBox(height: 16),
              _buildPlayerHighlight(
                context,
                mostSelectedPlayer,
                provider.getTeamById(mostSelectedPlayer.teamId),
                null,
                subtitle: 'Most Selected',
                color: const Color(0xFFB388FF),
                icon: Icons.people_rounded,
              ),
            ],
            const SizedBox(height: 20),
            AppTheme.sectionTitle(context, 'Top Performers'),
            const SizedBox(height: 12),
            _buildTopPerformers(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    Color statusColor;
    String statusText;
    if (gw.finished) {
      statusColor = AppColors.textSecondary;
      statusText = 'Finished';
    } else if (gw.isCurrent) {
      statusColor = AppColors.primary;
      statusText = 'Live';
    } else if (gw.isNext) {
      statusColor = AppColors.accent;
      statusText = 'Next';
    } else {
      statusColor = AppColors.warning;
      statusText = 'Upcoming';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.purpleGradient(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gw.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Deadline: ${formatDateTime(gw.deadlineTime)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withAlpha(120)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildScoreCards() {
    return Row(
      children: [
        if (gw.averageEntryScore != null)
          Expanded(
            child: _statTile(
              'Avg Score',
              '${gw.averageEntryScore} pts',
              Icons.show_chart_rounded,
              AppColors.accent,
            ),
          ),
        if (gw.averageEntryScore != null && gw.highestScore != null)
          const SizedBox(width: 10),
        if (gw.highestScore != null)
          Expanded(
            child: _statTile(
              'High Score',
              '${gw.highestScore} pts',
              Icons.emoji_events_rounded,
              AppColors.warning,
            ),
          ),
        if ((gw.averageEntryScore != null || gw.highestScore != null) &&
            gw.transfersMade > 0)
          const SizedBox(width: 10),
        if (gw.transfersMade > 0)
          Expanded(
            child: _statTile(
              'Transfers',
              _fmt(gw.transfersMade),
              Icons.swap_horiz_rounded,
              AppColors.primary,
            ),
          ),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.gradientCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildPlayerHighlight(
    BuildContext context,
    dynamic player,
    dynamic team,
    dynamic _ignored, {
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerDetailScreen(player: player),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.gradientCard(),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.cardMedium,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(100)),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: player.photoUrl as String,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const Icon(Icons.person, color: AppColors.textSecondary, size: 32),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.person, color: AppColors.textSecondary, size: 32),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: color.withAlpha(24),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(icon, color: color, size: 13),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    player.webName as String,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${team?.name ?? ''} · ${getPositionShort(player.elementType as int)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${player.totalPoints}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'pts',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildTopPerformers(BuildContext context) {
    final top = provider.getTopScorersByPoints(limit: 10);
    return Container(
      decoration: AppTheme.gradientCard(),
      child: Column(
        children: top.asMap().entries.map((entry) {
          final idx = entry.key;
          final player = entry.value;
          final team = provider.getTeamById(player.teamId);
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerDetailScreen(player: player),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider,
                    width: idx < top.length - 1 ? 1 : 0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${idx + 1}',
                      style: TextStyle(
                        color: idx == 0 ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: idx == 0 ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cardMedium,
                      border: Border.all(
                        color: getPositionColor(player.elementType),
                        width: 1.5,
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: player.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Icon(Icons.person, color: AppColors.textSecondary, size: 18),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.person, color: AppColors.textSecondary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.webName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${team?.shortName ?? ''} · ${getPositionShort(player.elementType)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${player.totalPoints} pts',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '$n';
  }
}

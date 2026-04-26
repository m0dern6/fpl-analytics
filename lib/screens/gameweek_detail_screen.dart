import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/gameweek.dart';
import '../models/player.dart';
import '../providers/fpl_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'player_detail_screen.dart';
import '../widgets/pitch_view.dart';

class GameweekDetailScreen extends StatefulWidget {
  final Gameweek gw;
  final FplProvider provider;

  const GameweekDetailScreen({
    super.key,
    required this.gw,
    required this.provider,
  });

  @override
  State<GameweekDetailScreen> createState() => _GameweekDetailScreenState();
}

class _GameweekDetailScreenState extends State<GameweekDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.provider.loadDreamTeam(widget.gw.id);
      widget.provider.loadLiveGwData(widget.gw.id);
      if (widget.gw.highestScoringEntry != null) {
        widget.provider.loadManagerTeam(
          widget.gw.highestScoringEntry!,
          widget.gw.id,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final gw = widget.gw;
    final provider = widget.provider;
    final topPlayer = gw.topElement != null
        ? provider.getPlayerById(gw.topElement!)
        : null;
    final topPlayerTeam = topPlayer != null
        ? provider.getTeamById(topPlayer.teamId)
        : null;
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
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'DREAM TEAM',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDreamTeamPitch(context),
            if (gw.highestScoringEntry != null) ...[
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'HIGHEST SCORING MANAGER',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildManagerTeamPitch(context),
            ],
            if (topPlayer != null) ...[
              const SizedBox(height: 20),
              AppTheme.sectionTitle(context, 'Top Player This Gameweek'),
              const SizedBox(height: 12),
              _buildPlayerHighlight(
                context,
                topPlayer,
                topPlayerTeam,
                subtitle: 'Highest Scoring Player',
                color: AppColors.warning,
                icon: Icons.emoji_events_rounded,
                gwPoints:
                    provider.getDreamTeamPlayerPoints(gw.id, topPlayer.id) > 0
                    ? provider.getDreamTeamPlayerPoints(gw.id, topPlayer.id)
                    : topPlayer.eventPoints,
                isDouble: false,
              ),
            ],
            if (mostCaptainedPlayer != null) ...[
              const SizedBox(height: 16),
              _buildPlayerHighlight(
                context,
                mostCaptainedPlayer,
                provider.getTeamById(mostCaptainedPlayer.teamId),
                subtitle: 'Most Captained',
                color: AppColors.primary,
                icon: Icons.shield_rounded,
                gwPoints: mostCaptainedPlayer.eventPoints,
                isDouble: true,
              ),
            ],
            if (mostTransferredPlayer != null) ...[
              const SizedBox(height: 16),
              _buildPlayerHighlight(
                context,
                mostTransferredPlayer,
                provider.getTeamById(mostTransferredPlayer.teamId),
                subtitle: 'Most Transferred In',
                color: AppColors.accent,
                icon: Icons.trending_up_rounded,
                gwPoints: mostTransferredPlayer.eventPoints,
                isDouble: false,
              ),
            ],
            if (mostSelectedPlayer != null) ...[
              const SizedBox(height: 16),
              _buildPlayerHighlight(
                context,
                mostSelectedPlayer,
                provider.getTeamById(mostSelectedPlayer.teamId),
                subtitle: 'Most Selected',
                color: const Color(0xFFB388FF),
                icon: Icons.people_rounded,
                gwPoints: mostSelectedPlayer.eventPoints,
                isDouble: false,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final gw = widget.gw;
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
    final gw = widget.gw;
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
    Player player,
    dynamic team, {
    required String subtitle,
    required Color color,
    required IconData icon,
    required int gwPoints,
    required bool isDouble,
  }) {
    final displayPoints = isDouble ? gwPoints * 2 : gwPoints;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
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
                imageUrl: player.photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 32,
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 32,
                ),
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
                      if (isDouble) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.warning.withAlpha(100),
                            ),
                          ),
                          child: const Text(
                            '2×',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    player.webName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${team?.name ?? ''} · ${getPositionShort(player.elementType)}',
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
                  '$displayPoints',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isDouble ? 'pts (×2)' : 'pts',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  // ── Dream Team Pitch Layout ───────────────────────────────────────────────

  Widget _buildDreamTeamPitch(BuildContext context) {
    final squad = widget.provider.getDreamTeam(widget.gw.id);

    if (squad.isEmpty) {
      final isLoading = widget.provider.isDreamTeamLoading(widget.gw.id);
      return _buildLoadingOrEmptyPitch(isLoading);
    }

    final pointsMap = <int, int>{};
    int totalPoints = 0;
    for (final p in squad) {
      final pts = widget.provider.getDreamTeamPlayerPoints(widget.gw.id, p.id);
      pointsMap[p.id] = pts;
      totalPoints += pts;
    }

    // Map players to pick format for PitchView
    final dreamPicks = squad.asMap().entries.map((entry) {
      final p = entry.value;
      return {
        'element': p.id,
        'position': entry.key + 1, // 1-11
        'multiplier': 1,
        'is_captain': p.id == widget.gw.mostCaptained,
        'is_vice_captain': false,
      };
    }).toList();

    return Column(
      children: [
        _buildTotalPointsContainer(totalPoints),
        const SizedBox(height: 16),
        PitchView(
          picks: dreamPicks,
          provider: widget.provider,
          gwId: widget.gw.id,
          isDreamTeam: true,
          pointsMap: pointsMap,
          onPlayerTap: (pick) => _showPlayerDetail(pick['element'] as int),
        ),
      ],
    );
  }

  Widget _buildManagerTeamPitch(BuildContext context) {
    final managerTeam = widget.provider.getManagerTeam(
      widget.gw.highestScoringEntry!,
      widget.gw.id,
    );

    if (managerTeam == null) {
      return _buildLoadingOrEmptyPitch(true);
    }

    final picks = (managerTeam['picks'] as List).map((p) => p as Map<String, dynamic>).toList();
    final totalPoints = managerTeam['entry_history']?['points'] as int? ?? 0;

    return Column(
      children: [
        _buildTotalPointsContainer(totalPoints),
        const SizedBox(height: 16),
        PitchView(
          picks: picks,
          provider: widget.provider,
          gwId: widget.gw.id,
          activeChip: managerTeam['active_chip'] as String?,
          onPlayerTap: (pick) => _showPlayerDetail(pick['element'] as int),
        ),
      ],
    );
  }

  Widget _buildTotalPointsContainer(int points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF34D399).withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF34D399).withAlpha(100), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$points',
            style: const TextStyle(
              color: Color(0xFF34D399),
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          Text(
            'GW${widget.gw.id} PTS',
            style: const TextStyle(
              color: Color(0xFF34D399),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOrEmptyPitch(bool isLoading) {
    return Container(
      height: 200,
      decoration: AppTheme.gradientCard(),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: AppColors.primary)
            : const Text(
                'Data unavailable for this gameweek',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
      ),
    );
  }

  void _showPlayerDetail(int playerId) {
    final player = widget.provider.getPlayerById(playerId);
    if (player != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
      );
    }
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '$n';
  }
}

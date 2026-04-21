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
    });
  }

  @override
  Widget build(BuildContext context) {
    final gw = widget.gw;
    final provider = widget.provider;
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
            const SizedBox(height: 20),
            AppTheme.sectionTitle(context, 'Highest Scoring Team'),
            const SizedBox(height: 12),
            _buildDreamTeamPitch(context),
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
                gwPoints: provider.getDreamTeamPlayerPoints(gw.id, topPlayer.id) > 0
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
                imageUrl: player.photoUrl,
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
                      if (isDouble) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.warning.withAlpha(100)),
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
                      color: AppColors.textSecondary, fontSize: 11),
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
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.gradientCard(),
        child: Center(
          child: widget.gw.finished
              ? const CircularProgressIndicator(color: AppColors.primary)
              : const Text(
                  'Dream team will be available after GW completion',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
        ),
      );
    }

    // Group players by position
    final gks = squad.where((p) => p.elementType == 1).toList();
    final defs = squad.where((p) => p.elementType == 2).toList();
    final mids = squad.where((p) => p.elementType == 3).toList();
    final fwds = squad.where((p) => p.elementType == 4).toList();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.pitchGreen, AppColors.pitchGreenDark],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Stack(
        children: [
          // Pitch markings
          Positioned.fill(child: _buildPitchMarkings()),
          // Players
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                if (fwds.isNotEmpty) _buildPitchRow(context, fwds),
                if (fwds.isNotEmpty) const SizedBox(height: 14),
                if (mids.isNotEmpty) _buildPitchRow(context, mids),
                if (mids.isNotEmpty) const SizedBox(height: 14),
                if (defs.isNotEmpty) _buildPitchRow(context, defs),
                if (defs.isNotEmpty) const SizedBox(height: 14),
                if (gks.isNotEmpty) _buildPitchRow(context, gks),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms);
  }

  Widget _buildPitchMarkings() {
    return CustomPaint(painter: _PitchMarkingsPainter());
  }

  Widget _buildPitchRow(BuildContext context, List<Player> players) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: players.map((p) => _buildPitchPlayer(context, p)).toList(),
    );
  }

  Widget _buildPitchPlayer(BuildContext context, Player player) {
    final gwPoints = widget.provider
        .getDreamTeamPlayerPoints(widget.gw.id, player.id);
    final displayPoints = gwPoints > 0 ? gwPoints : player.eventPoints;
    final posColor = getPositionColor(player.elementType);
    final isCaptain = player.id == widget.gw.mostCaptained;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerDetailScreen(player: player)),
      ),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark.withAlpha(180),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: posColor.withAlpha(180),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: player.photoUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (_, __) => Center(
                      child: Icon(Icons.person, color: posColor, size: 26),
                    ),
                    errorWidget: (_, __, ___) => Center(
                      child: Icon(Icons.person, color: posColor, size: 26),
                    ),
                  ),
                ),
                if (isCaptain)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.pitchGreen,
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'C',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Container(
              constraints: const BoxConstraints(maxWidth: 62),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(150),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                player.webName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: posColor.withAlpha(230),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$displayPoints',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '$n';
  }
}

class _PitchMarkingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Centre circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.15,
      paint,
    );
    // Centre line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    // Outer border
    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      paint,
    );
    // Top penalty area
    final penW = size.width * 0.5;
    final penH = size.height * 0.15;
    canvas.drawRect(
      Rect.fromLTWH(
          (size.width - penW) / 2, 8, penW, penH),
      paint,
    );
    // Bottom penalty area
    canvas.drawRect(
      Rect.fromLTWH(
          (size.width - penW) / 2,
          size.height - 8 - penH,
          penW,
          penH),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

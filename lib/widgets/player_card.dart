import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final Team? team;
  final VoidCallback? onTap;
  final bool compact;

  const PlayerCard({
    super.key,
    required this.player,
    this.team,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final posColor = getPositionColor(player.elementType);
    final posShort = getPositionShort(player.elementType);

    return GestureDetector(
      onTap: onTap,
      child: compact
          ? _buildCompact(posColor, posShort)
          : _buildFull(posColor, posShort),
    );
  }

  // ── Compact (e.g. leaderboard rows) ──────────────────────────────────────

  Widget _buildCompact(Color posColor, String posShort) {
    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            // Position accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: posColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildPhoto(size: 38),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      player.webName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _posTag(posShort, posColor),
                        const SizedBox(width: 5),
                        Text(
                          team?.shortName ?? '',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${player.totalPoints}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    formatPrice(player.nowCost),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Full card ─────────────────────────────────────────────────────────────

  Widget _buildFull(Color posColor, String posShort) {
    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            // Position colour bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: posColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildPhoto(size: 54),
            const SizedBox(width: 12),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.webName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.news.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.warning_amber_rounded,
                                color: AppColors.warning, size: 15),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _posTag(posShort, posColor),
                        const SizedBox(width: 6),
                        Text(
                          team?.name ?? '',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _miniStat('Form', formatForm(player.form), AppColors.accent),
                        const SizedBox(width: 14),
                        _miniStat('ICT',
                            formatDouble(player.ictIndex, decimals: 1),
                            AppColors.warning),
                        const SizedBox(width: 14),
                        _miniStat('Sel%',
                            formatPercent(player.selectedByPercent),
                            AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Right: Points + Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primary.withAlpha(70), width: 1),
                    ),
                    child: Text(
                      '${player.totalPoints}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPrice(player.nowCost),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'pts',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared sub-widgets ────────────────────────────────────────────────────

  Widget _buildPhoto({required double size}) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.cardMedium,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: CachedNetworkImage(
            imageUrl: player.photoUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Icon(Icons.person,
                color: AppColors.textSecondary, size: size * 0.55),
            errorWidget: (_, __, ___) => Icon(Icons.person,
                color: AppColors.textSecondary, size: size * 0.55),
          ),
        ),
        if (player.chanceOfPlayingNextRound != null &&
            player.chanceOfPlayingNextRound! < 100)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: player.chanceOfPlayingNextRound! < 50
                    ? AppColors.error
                    : AppColors.warning,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardDark, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '${player.chanceOfPlayingNextRound}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _posTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withAlpha(100), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 1),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

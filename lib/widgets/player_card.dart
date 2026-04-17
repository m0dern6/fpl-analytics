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
      child: Container(
        decoration: AppTheme.gradientCard(),
        child: compact ? _buildCompact(posColor, posShort) : _buildFull(posColor, posShort),
      ),
    );
  }

  Widget _buildCompact(Color posColor, String posShort) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildPhoto(size: 40),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: posColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: posColor, width: 0.5),
                      ),
                      child: Text(posShort, style: TextStyle(color: posColor, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      team?.shortName ?? '',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
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
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                formatPrice(player.nowCost),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFull(Color posColor, String posShort) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildPhoto(size: 56),
          const SizedBox(width: 12),
          Expanded(
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
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (player.news.isNotEmpty)
                      const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: posColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: posColor, width: 0.8),
                      ),
                      child: Text(posShort, style: TextStyle(color: posColor, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      team?.name ?? '',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniStat('Form', formatForm(player.form), AppColors.accent),
                    const SizedBox(width: 12),
                    _miniStat('ICT', formatDouble(player.ictIndex, decimals: 1), AppColors.warning),
                    const SizedBox(width: 12),
                    _miniStat('Sel%', formatPercent(player.selectedByPercent), AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withAlpha(77)),
                ),
                child: Text(
                  '${player.totalPoints}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatPrice(player.nowCost),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                'pts',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto({required double size}) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.cardMedium,
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: CachedNetworkImage(
            imageUrl: player.photoUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Icon(Icons.person, color: AppColors.textSecondary, size: size * 0.6),
            errorWidget: (_, __, ___) => Icon(Icons.person, color: AppColors.textSecondary, size: size * 0.6),
          ),
        ),
        if (player.chanceOfPlayingNextRound != null && player.chanceOfPlayingNextRound! < 100)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: player.chanceOfPlayingNextRound! < 50 ? AppColors.error : AppColors.warning,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardDark, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '${player.chanceOfPlayingNextRound}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
